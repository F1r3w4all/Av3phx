defmodule RideFastApi.Repo do
  use Ecto.Repo,
    otp_app: :ride_fast_api,
    adapter: Ecto.Adapters.MyXQL
end
