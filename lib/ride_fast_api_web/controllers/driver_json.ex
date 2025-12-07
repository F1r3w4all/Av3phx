# lib/ride_fast_api_web/controllers/driver_json.ex
defmodule RideFastApiWeb.DriverJSON do
  alias RideFastApi.Accounts.Driver

  def index(%{drivers: drivers, meta: meta}) do
    %{
      data: Enum.map(drivers, &data/1),
      meta: meta
    }
  end

  def show(%{driver: driver}) do
    %{data: data(driver)}
  end

  def data(%Driver{} = driver) do
    %{
      id: driver.id,
      name: driver.name,
      email: driver.email,
      phone: driver.phone,
      status: driver.status,
      inserted_at: driver.inserted_at
    }
  end
end
