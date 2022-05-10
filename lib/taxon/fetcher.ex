defmodule Taxon.Fetcher do
  def add_cloud_ips() do
    providers = %{
      aws: "https://ip-ranges.amazonaws.com/ip-ranges.json",
      azure: "https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519"
    }

    get_prefixes_update_term(providers)
  end

  def get_prefixes_update_term(providers) do
    # 1. Get the IP prefixes for each provider
    # 2. Return a list of prefixes for each provider, if the HTTP request fails return []
    new_prefixes =
      Enum.map(providers, fn {cloud_provider, url} ->
        Task.async(fn -> {cloud_provider, url_to_prefixes(url, cloud_provider)} end)
      end)
      |> Enum.map(&Task.await/1)

    iptrie = prefixes_to_trie(new_prefixes)
    :persistent_term.put({__MODULE__, :dc_trie}, iptrie)

    IO.inspect(Iptrie.count(iptrie), label: "Iptrie count")
    iptrie_size = iptrie |> :erlang.term_to_binary() |> :erlang.byte_size()
    IO.inspect(iptrie_size / 1_000_000, label: "Iptrie_size in MB")
  end

  def prefixes_to_trie(pl) do
    prefixes =
      pl
      |> Enum.map(fn {c, p} ->
        IO.inspect(length(p), label: " prefixes for #{c}")
        p
      end)
      |> List.flatten()
      |> Enum.map(fn prefix -> {prefix, true} end)

    IO.inspect(length(prefixes), label: "Total prefixes length (includes duplicates)")
    Iptrie.new(prefixes)
  end

  def url_to_prefixes(url, :aws) do
    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(url),
         {:ok, j_body} <- Jason.decode(body) do
      ipv4 = extract_prefixes_aws(j_body, "prefixes", "ip_prefix")
      ipv6 = extract_prefixes_aws(j_body, "ipv6_prefixes", "ipv6_prefix")
      Enum.concat([ipv4, ipv6])
    else
      _ ->
        []
    end
  end

  def url_to_prefixes(url, :azure) do
    with {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(url),
         {:ok, json_url} <- get_json_url(body),
         {:ok, %{status_code: 200, body: json_body}} <-
           HTTPoison.get(json_url, [], follow_redirect: true),
         {:ok, jd_body} <- Jason.decode(json_body) do
      extract_prefixes_azure(jd_body)
    else
      _ ->
        []
    end
  end

  def get_json_url(body) do
    {:ok, html} = Floki.parse_document(body)

    json_url =
      html
      |> Floki.find("a, href")
      |> Enum.map(fn {_a, l, _} ->
        Enum.filter(l, fn {_k, v} -> String.contains?(v, ".json") end)
      end)
      |> Enum.filter(fn x -> x != [] end)
      |> hd()
      |> hd()
      |> elem(1)

    {:ok, json_url}
  end

  def extract_prefixes_aws(body, k1, k2) do
    body
    |> Map.get(k1)
    |> Enum.map(fn %{^k2 => prefix} -> prefix end)
  end

  def extract_prefixes_azure(body) do
    body
    |> Map.get("values")
    |> Enum.map(fn x -> get_in(x, ["properties", "addressPrefixes"]) end)
    |> List.flatten()
  end
end
