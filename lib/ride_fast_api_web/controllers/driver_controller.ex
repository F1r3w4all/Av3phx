defmodule RideFastApiWeb.DriverController do
  use RideFastApiWeb, :controller

  alias RideFastApi.Accounts
  alias RideFastApi.Accounts.Driver
  alias RideFastApiWeb.DriverJSON
  alias RideFastApi.Guardian

  action_fallback RideFastApiWeb.FallbackController

  # GET /api/v1/drivers
  def index(conn, params) do
    case Accounts.list_drivers(params) do
      {:ok, %{items: drivers, meta: meta}} ->
        conn
        |> put_status(:ok)
        |> render(DriverJSON, :index, drivers: drivers, meta: meta)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to list drivers: #{reason}"})
    end
  end

  # POST /api/v1/drivers (admin, via JWT)
  def create(conn, params) do
    current = Guardian.Plug.current_resource(conn)

    if current.role != "admin" do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden"})
    else
      case Accounts.create_driver(params) do
        {:ok, %Driver{} = driver} ->
          conn
          |> put_status(:created)
          |> put_resp_header("location", ~p"/api/v1/drivers/#{driver.id}")
          |> render(DriverJSON, :show, driver: driver)

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:bad_request)
          |> render(RideFastApiWeb.ChangesetJSON, :error, changeset: changeset)

        {:error, :email_conflict} ->
          conn
          |> put_status(:conflict)
          |> json(%{error: "E-mail já cadastrado."})

        _ ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: "Erro inesperado ao criar driver."})
      end
    end
  end

  # GET /api/v1/drivers/:id
  def show(conn, %{"id" => id}) do
    driver = Accounts.get_driver_with_details(id)

    case driver do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Driver not found"})

      _ ->
        render(conn, DriverJSON, :show, driver: driver)
    end
  end

  # GET /api/v1/drivers/:driver_id/profile
  def profile(conn, %{"driver_id" => id}) do
    current = Guardian.Plug.current_resource(conn)
    driver  = Accounts.get_driver_with_details(id)

    case driver do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Driver not found"})

      _ ->
        cond do
          current.role == "admin" or current.id == driver.id ->
            profile =
              case driver.profile do
                nil ->
                  nil

                p ->
                  %{
                    address: p.address,
                    city: p.city,
                    state: p.state,
                    zip_code: p.zip_code,
                    birth_date: p.birth_date,
                    cnh_number: p.cnh_number,
                    cnh_category: p.cnh_category
                  }
              end

            conn
            |> put_status(:ok)
            |> json(%{data: profile})

          true ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: "Forbidden"})
        end
    end
  end

  # POST /api/v1/drivers/:driver_id/profile
  def create_profile(conn, %{"driver_id" => id} = params) do
    current = Guardian.Plug.current_resource(conn)
    driver  = Accounts.get_driver_with_details(id)

    case driver do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Driver not found"})

      _ ->
        cond do
          current.role == "admin" or current.id == driver.id ->
            do_create_profile(conn, driver, params)

          true ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: "Forbidden"})
        end
    end
  end

  defp do_create_profile(conn, driver, params) do
    case driver.profile do
      %RideFastApi.Accounts.DriverProfile{} ->
        conn
        |> put_status(:conflict)
        |> json(%{error: "Profile already exists for this driver"})

      nil ->
        attrs = %{
          driver_id: driver.id,
          cnh_number: Map.get(params, "license_number"),
          cnh_category: Map.get(params, "license_category"),
          address: Map.get(params, "address"),
          city: Map.get(params, "city"),
          state: Map.get(params, "state"),
          zip_code: Map.get(params, "zip_code"),
          birth_date: Map.get(params, "birth_date")
        }

        case Accounts.create_driver_profile(attrs) do
          {:ok, profile} ->
            conn
            |> put_status(:created)
            |> json(%{
              data: %{
                id: profile.id,
                driver_id: profile.driver_id,
                address: profile.address,
                city: profile.city,
                state: profile.state,
                zip_code: profile.zip_code,
                birth_date: profile.birth_date,
                cnh_number: profile.cnh_number,
                cnh_category: profile.cnh_category
              }
            })

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:bad_request)
            |> render(RideFastApiWeb.ChangesetJSON, :error, changeset: changeset)
        end
    end
  end

  # PUT /api/v1/drivers/:driver_id/profile
  def update_profile(conn, %{"driver_id" => id} = params) do
    current = Guardian.Plug.current_resource(conn)
    driver  = Accounts.get_driver_with_details(id)

    case driver do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Driver not found"})

      _ ->
        cond do
          current.role == "admin" or current.id == driver.id ->
            do_update_profile(conn, driver, params)

          true ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: "Forbidden"})
        end
    end
  end

  defp do_update_profile(conn, driver, params) do
    case driver.profile do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Profile not found for this driver"})

      profile ->
        attrs = %{
          cnh_number: Map.get(params, "license_number", profile.cnh_number),
          cnh_category: Map.get(params, "license_category", profile.cnh_category),
          address: Map.get(params, "address", profile.address),
          city: Map.get(params, "city", profile.city),
          state: Map.get(params, "state", profile.state),
          zip_code: Map.get(params, "zip_code", profile.zip_code),
          birth_date: Map.get(params, "birth_date", profile.birth_date)
        }

        case Accounts.update_driver_profile(profile, attrs) do
          {:ok, profile} ->
            conn
            |> put_status(:ok)
            |> json(%{
              data: %{
                id: profile.id,
                driver_id: profile.driver_id,
                address: profile.address,
                city: profile.city,
                state: profile.state,
                zip_code: profile.zip_code,
                birth_date: profile.birth_date,
                cnh_number: profile.cnh_number,
                cnh_category: profile.cnh_category
              }
            })

          {:error, %Ecto.Changeset{} = changeset} ->
            conn
            |> put_status(:bad_request)
            |> render(RideFastApiWeb.ChangesetJSON, :error, changeset: changeset)
        end
    end
  end

  # POST /api/v1/drivers/:driver_id/vehicles
  def create_vehicle(conn, %{"driver_id" => id} = params) do
    current = Guardian.Plug.current_resource(conn)
    driver  = Accounts.get_driver_with_details(id)

    case driver do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Driver not found"})

      _ ->
        cond do
          current.role == "admin" or current.id == driver.id ->
            do_create_vehicle(conn, driver, params)

          true ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: "Forbidden"})
        end
    end
  end

  defp do_create_vehicle(conn, driver, params) do
    attrs = %{
      driver_id: driver.id,
      plate: Map.get(params, "plate"),
      model: Map.get(params, "model"),
      color: Map.get(params, "color"),
      # campos extras do schema: ajuste se quiser usar brand/year/renavam/chassis
      brand: Map.get(params, "brand"),
      year: Map.get(params, "year"),
      renavam: Map.get(params, "renavam"),
      chassis: Map.get(params, "chassis")
    }

    case Accounts.create_vehicle(attrs) do
      {:ok, vehicle} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: %{
            id: vehicle.id,
            driver_id: vehicle.driver_id,
            plate: vehicle.plate,
            model: vehicle.model,
            color: vehicle.color,
            brand: vehicle.brand,
            year: vehicle.year,
            renavam: vehicle.renavam,
            chassis: vehicle.chassis
          }
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        case Keyword.get(changeset.errors, :plate) do
          {_, opts} ->
            # opts é a keyword list de metadados do erro; se tiver constraint: :unique, tratamos como 409
            case Keyword.get(opts, :constraint) do
              :unique ->
                conn
                |> put_status(:conflict)
                |> json(%{error: "Vehicle with this plate already exists"})

              _ ->
                conn
                |> put_status(:bad_request)
                |> render(RideFastApiWeb.ChangesetJSON, :error, changeset: changeset)
            end

          _ ->
            conn
            |> put_status(:bad_request)
            |> render(RideFastApiWeb.ChangesetJSON, :error, changeset: changeset)
        end
    end
  end

   # PUT /api/v1/drivers/:id
  def update(conn, %{"id" => id, "driver" => driver_params}) do
    current = Guardian.Plug.current_resource(conn)
    driver = Accounts.get_driver!(id)

    cond do
      current.role == "admin" ->
        do_update_driver(conn, driver, driver_params)

      current.id == driver.id ->
        do_update_driver(conn, driver, driver_params)

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Forbidden"})
    end
  end

  defp do_update_driver(conn, driver, driver_params) do
    case Accounts.update_driver(driver, driver_params) do
      {:ok, %Driver{} = driver} ->
        conn
        |> put_status(:ok)
        |> render(RideFastApiWeb.DriverJSON, :show, driver: driver)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:bad_request)
        |> render(RideFastApiWeb.ChangesetJSON, :error, changeset: changeset)
    end
  end

  # DELETE /api/v1/drivers/:id (admin only, 204)
  def delete(conn, %{"id" => id}) do
    current = Guardian.Plug.current_resource(conn)

    if current.role != "admin" do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden"})
    else
      driver = Accounts.get_driver!(id)

      case Accounts.delete_driver(driver) do
        {:ok, %Driver{}} ->
          send_resp(conn, :no_content, "")

        {:error, _reason} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: "Erro ao deletar driver."})
      end
    end
  end
end
