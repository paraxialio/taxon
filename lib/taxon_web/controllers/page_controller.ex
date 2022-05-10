defmodule TaxonWeb.PageController do
  use TaxonWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def no_dc(conn, _params) do
    render(conn, "no_dc.html")
  end
end
