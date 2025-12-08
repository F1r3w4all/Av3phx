defmodule RideFastApiWeb.RideController do
  use RideFastApiWeb, :controller

  alias RideFastApi.Rides
  alias RideFastApi.Rides.Ride
  alias RideFastApi.Guardian
  action_fallback RideFastApiWeb.FallbackController

  # POST /api/v1/rides
  def create(conn, params) do
    current = Guardian.Plug.current_resource(conn)

    # garante que é user (não driver/admin)
    if current.role != "user" do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden"})
    else
      # espera body:
      # {
      #   "origin": {"lat": -3.7, "lng": -38.5},
      #   "destination": {"lat": -3.71, "lng": -38.52},
      #   "payment_method": "CARD"
      # }
      origin = Map.get(params, "origin", %{})
      dest = Map.get(params, "destination", %{})

      attrs = %{
        "user_id" => current.id,
        "origin_lat" => origin["lat"],
        "origin_lng" => origin["lng"],
        "destination_lat" => dest["lat"],
        "destination_lng" => dest["lng"],
        "payment_method" => params["payment_method"]
      }

      case Rides.create_ride(attrs) do
        {:ok, %Ride{} = ride} ->
          conn
          |> put_status(:created)
          |> json(%{
            data: %{
              id: ride.id,
              user_id: ride.user_id,
              driver_id: ride.driver_id,
              status: ride.status,
              origin: %{
                lat: ride.origin_lat,
                lng: ride.origin_lng
              },
              destination: %{
                lat: ride.destination_lat,
                lng: ride.destination_lng
              },
              payment_method: ride.payment_method,
              inserted_at: ride.inserted_at
            }
          })

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:bad_request)
          |> render(RideFastApiWeb.ChangesetJSON, :error, changeset: changeset)
      end
    end
  end

  # ==listar rides===
  # GET /api/v1/rides
  def index(conn, params) do
    current = Guardian.Plug.current_resource(conn)

    # aplica scoping por role
    scoped_params =
      case current.role do
        "admin" ->
          params

        "user" ->
          Map.put(params, "user_id", to_string(current.id))

        "driver" ->
          Map.put(params, "driver_id", to_string(current.id))

        _ ->
          params
      end

    case Rides.list_rides(scoped_params) do
      {:ok, %{items: rides, meta: meta}} ->
        data =
          Enum.map(rides, fn ride ->
            %{
              id: ride.id,
              user_id: ride.user_id,
              driver_id: ride.driver_id,
              status: ride.status,
              origin: %{
                lat: ride.origin_lat,
                lng: ride.origin_lng
              },
              destination: %{
                lat: ride.destination_lat,
                lng: ride.destination_lng
              },
              payment_method: ride.payment_method,
              inserted_at: ride.inserted_at
            }
          end)

        conn
        |> put_status(:ok)
        |> json(%{data: data, meta: meta})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to list rides", reason: inspect(reason)})
    end
  end

  # ==obter ride por id===
  # GET /api/v1/rides/:id
  def show(conn, %{"id" => id}) do
    current = Guardian.Plug.current_resource(conn)
    ride = Rides.get_ride_with_details(id)

    case ride do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Ride not found"})

      _ ->
        allowed? =
          case current.role do
            "admin" ->
              true

            "user" ->
              current.id == ride.user_id

            "driver" ->
              current.id == ride.driver_id

            _ ->
              false
          end

        if not allowed? do
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Forbidden"})
        else
          data = %{
            id: ride.id,
            status: ride.status,
            payment_method: ride.payment_method,
            user:
              ride.user &&
                %{
                  id: ride.user.id,
                  name: ride.user.name,
                  email: ride.user.email
                },
            driver:
              ride.driver &&
                %{
                  id: ride.driver.id,
                  name: ride.driver.name,
                  email: ride.driver.email
                },
            vehicle:
              ride.vehicle &&
                %{
                  id: ride.vehicle.id,
                  plate: ride.vehicle.plate,
                  model: ride.vehicle.model,
                  color: ride.vehicle.color,
                  seats: ride.vehicle.seats
                },
            origin: %{
              lat: ride.origin_lat,
              lng: ride.origin_lng
            },
            destination: %{
              lat: ride.destination_lat,
              lng: ride.destination_lng
            },
            inserted_at: ride.inserted_at,
            updated_at: ride.updated_at
          }

          conn
          |> put_status(:ok)
          |> json(%{data: data})
        end
    end
  end

  def accept(conn, %{"id" => id} = params) do
    current = Guardian.Plug.current_resource(conn)

    # Apenas driver pode aceitar
    if current.role != "driver" do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Forbidden"})
    else
      vehicle_id = Map.get(params, "vehicle_id")

      case Rides.accept_ride(id, current.id, vehicle_id) do
        {:ok, ride} ->
          conn
          |> put_status(:ok)
          |> json(%{
            data: %{
              id: ride.id,
              status: ride.status,
              user_id: ride.user_id,
              driver_id: ride.driver_id,
              vehicle_id: ride.vehicle_id,
              origin: %{
                lat: ride.origin_lat,
                lng: ride.origin_lng
              },
              destination: %{
                lat: ride.destination_lat,
                lng: ride.destination_lng
              },
              payment_method: ride.payment_method,
              inserted_at: ride.inserted_at,
              updated_at: ride.updated_at
            }
          })

        {:error, :not_found} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Ride not found"})

        {:error, :invalid_status} ->
          conn
          |> put_status(:conflict)
          |> json(%{error: "Ride is not in SOLICITADA status"})

        {:error, :driver_inactive} ->
          conn
          |> put_status(:forbidden)
          |> json(%{error: "Driver is not active"})

        {:error, :driver_busy} ->
          conn
          |> put_status(:conflict)
          |> json(%{error: "Driver already has ride in progress"})

        {:error, :driver_not_found} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Driver not found"})

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:bad_request)
          |> render(RideFastApiWeb.ChangesetJSON, :error, changeset: changeset)

        {:error, reason} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: "Could not accept ride", reason: inspect(reason)})
      end
    end
  end
end
