defmodule Taxon.DataCenterPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # Add this line, AWS IP
    aws_ip = {3, 5, 140, 2}
    # Add this line
    conn = Map.put(conn, :remote_ip, aws_ip)
    iptrie = :persistent_term.get({Taxon.Fetcher, :dc_trie})
    lookup = Iptrie.lookup(iptrie, conn.remote_ip)

    if is_nil(lookup) do
      IO.puts("Not data_center_ip")
      assign(conn, :data_center_ip, false)
    else
      IO.puts("A data_center_ip")
      assign(conn, :data_center_ip, true)
    end
  end
end
