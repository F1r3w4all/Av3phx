defmodule RideFastApiWeb.DriverController do
  use RideFastApiWeb, :controller

  alias RideFastApi.Accounts
  alias RideFastApi.Accounts.Driver

  action_fallback RideFastApiWeb.FallbackController

  def index(conn, _params) do
    drivers = Accounts.list_drivers()
    render(conn, :index, drivers: drivers)
  end

  def create(conn, %{"driver" => driver_params}) do
    with {:ok, %Driver{} = driver} <- Accounts.create_driver(driver_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/drivers/#{driver}")
      |> render(:show, driver: driver)
    end
  end

  def show(conn, %{"id" => id}) do
    driver = Accounts.get_driver!(id)
    render(conn, :show, driver: driver)
  end

  def update(conn, %{"id" => id, "driver" => driver_params}) do
    driver = Accounts.get_driver!(id)

    with {:ok, %Driver{} = driver} <- Accounts.update_driver(driver, driver_params) do
      render(conn, :show, driver: driver)
    end
  end

  def delete(conn, %{"id" => id}) do
    driver = Accounts.get_driver!(id)

    with {:ok, %Driver{}} <- Accounts.delete_driver(driver) do
      send_resp(conn, :no_content, "")
    end
  end
end
