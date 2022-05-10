defmodule Taxon.BlockDCIP do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:data_center_ip] do
      conn
      |> halt()
      |> send_resp(404, "Not found")
    else
      conn
    end
  end
end
