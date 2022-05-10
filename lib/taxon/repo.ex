defmodule Taxon.Repo do
  use Ecto.Repo,
    otp_app: :taxon,
    adapter: Ecto.Adapters.Postgres
end
