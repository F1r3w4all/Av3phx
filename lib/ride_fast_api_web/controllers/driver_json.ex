defmodule RideFastApiWeb.DriverJSON do
  alias RideFastApi.Accounts.Driver

  @doc """
  Renders a list of drivers.
  """
  def index(%{drivers: drivers}) do
    %{data: for(driver <- drivers, do: data(driver))}
  end

  @doc """
  Renders a single driver.
  """
  def show(%{driver: driver}) do
    %{data: data(driver)}
  end

  def data(%{driver: driver}) do
    %{
      id: driver.id,
      name: driver.name,
      email: driver.email,
      phone: driver.phone,
      status: driver.status,
      # CORREÇÃO: Usar inserted_at
      created_at: driver.inserted_at,
      updated_at: driver.updated_at
    }
  end
end
