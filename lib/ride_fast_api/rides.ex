defmodule RideFastApi.Rides do
  import Ecto.Query, warn: false
  alias RideFastApi.Repo
  alias RideFastApi.Rides.Ride
  alias RideFastApi.Accounts.Driver
  alias RideFastApi.Rides.RideEvent

  def create_ride(attrs) do
    %Ride{}
    |> Ride.create_changeset(attrs)
    |> Repo.insert()
  end

  def list_rides(params \\ %{}) do
    page = String.to_integer(Map.get(params, "page", "1"))
    size = String.to_integer(Map.get(params, "size", "20"))

    base_query =
      Ride
      |> filter_status(params["status"])
      |> filter_user(params["user_id"])
      |> filter_driver(params["driver_id"])
      |> order_by([r], desc: r.inserted_at)

    total_entries = Repo.aggregate(base_query, :count)
    offset = (page - 1) * size

    rides =
      base_query
      |> limit(^size)
      |> offset(^offset)
      |> Repo.all()

    meta = %{
      page: page,
      size: size,
      total_entries: total_entries,
      total_pages:
        if size == 0 do
          0
        else
          div(total_entries + size - 1, size)
        end
    }

    {:ok, %{items: rides, meta: meta}}
  end

  # ACCEPT ---------------------------------------------------------

  def accept_ride(ride_id, driver_id, vehicle_id) do
    Repo.transaction(fn ->
      ride_query =
        from r in Ride,
          where: r.id == ^ride_id,
          lock: "FOR UPDATE"

      ride = Repo.one(ride_query)

      if ride == nil do
        {:error, :not_found}
      else
        if ride.status != "SOLICITADA" do
          {:error, :invalid_status}
        else
          driver = Repo.get(Driver, driver_id)

          cond do
            driver == nil ->
              {:error, :driver_not_found}

            driver.status != "available" and driver.status != "ACTIVE" ->
              {:error, :driver_inactive}

            driver_has_active_ride?(driver_id) ->
              {:error, :driver_busy}

            true ->
              changes = %{status: "ACEITA", driver_id: driver_id, vehicle_id: vehicle_id}

              case Repo.update(Ecto.Changeset.change(ride, changes)) do
                {:ok, updated_ride} ->
                  # registra evento de histórico
                  create_event(updated_ride.id, ride.status, "ACEITA", "driver", driver_id, nil)
                  {:ok, updated_ride}

                {:error, changeset} ->
                  {:error, changeset}
              end
          end
        end
      end
    end)
    |> case do
      {:ok, result} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  defp driver_has_active_ride?(driver_id) do
    query =
      from r in Ride,
        where: r.driver_id == ^driver_id and r.status == "EM_ANDAMENTO",
        select: r.id,
        limit: 1

    Repo.one(query) != nil
  end

  # FILTERS --------------------------------------------------------

  defp filter_status(query, nil), do: query
  defp filter_status(query, ""), do: query

  defp filter_status(query, status) do
    from r in query, where: r.status == ^status
  end

  defp filter_user(query, nil), do: query
  defp filter_user(query, ""), do: query

  defp filter_user(query, user_id) do
    case Integer.parse(user_id) do
      {id, _} -> from r in query, where: r.user_id == ^id
      :error -> query
    end
  end

  defp filter_driver(query, nil), do: query
  defp filter_driver(query, ""), do: query

  defp filter_driver(query, driver_id) do
    case Integer.parse(driver_id) do
      {id, _} -> from r in query, where: r.driver_id == ^id
      :error -> query
    end
  end

  # DETAILS --------------------------------------------------------

  def get_ride_with_details(id) do
    Ride
    |> Repo.get(id)
    |> Repo.preload([:user, :driver, :vehicle])
  end

  # START ----------------------------------------------------------

  def start_ride(ride_id, driver_id) do
    case Repo.get(Ride, ride_id) do
      nil ->
        {:error, :not_found}

      %Ride{} = ride ->
        cond do
          ride.driver_id != driver_id ->
            {:error, :forbidden}

          ride.status != "ACEITA" ->
            {:error, :invalid_status}

          true ->
            now = DateTime.utc_now() |> DateTime.truncate(:second)
            changes = %{status: "EM_ANDAMENTO", started_at: now}

            case Repo.update(Ecto.Changeset.change(ride, changes)) do
              {:ok, updated} ->
                create_event(updated.id, ride.status, "EM_ANDAMENTO", "driver", driver_id, nil)
                {:ok, updated}

              {:error, changeset} ->
                {:error, changeset}
            end
        end
    end
  end

  # COMPLETE -------------------------------------------------------

  def complete_ride(ride_id, driver_id, attrs) do
    case Repo.get(Ride, ride_id) do
      nil ->
        {:error, :not_found}

      %Ride{} = ride ->
        cond do
          ride.driver_id != driver_id ->
            {:error, :forbidden}

          ride.status != "EM_ANDAMENTO" ->
            {:error, :invalid_status}

          true ->
            now = DateTime.utc_now() |> DateTime.truncate(:second)

            changes = %{
              status: "FINALIZADA",
              ended_at: now,
              final_price: Map.get(attrs, "final_price"),
              payment_method: Map.get(attrs, "payment_method", ride.payment_method)
            }

            case Repo.update(Ecto.Changeset.change(ride, changes)) do
              {:ok, updated} ->
                create_event(updated.id, ride.status, "FINALIZADA", "driver", driver_id, nil)
                {:ok, updated}

              {:error, changeset} ->
                {:error, changeset}
            end
        end
    end
  end

  # CANCEL ---------------------------------------------------------

  def cancel_ride(ride_id, actor) do
    case Repo.get(Ride, ride_id) do
      nil ->
        {:error, :not_found}

      %Ride{} = ride ->
        allowed? =
          case actor.role do
            "admin" -> true
            "user" -> ride.user_id == actor.id
            "driver" -> ride.driver_id == actor.id
            _ -> false
          end

        cond do
          not allowed? ->
            {:error, :forbidden}

          ride.status == "CANCELADA" ->
            {:error, :already_cancelled}

          true ->
            now = DateTime.utc_now() |> DateTime.truncate(:second)

            changes = %{
              status: "CANCELADA",
              cancel_reason: actor.reason,
              canceled_by: actor.role,
              ended_at: ride.ended_at || now
            }

            case Repo.update(Ecto.Changeset.change(ride, changes)) do
              {:ok, updated} ->
                create_event(
                  updated.id,
                  ride.status,
                  "CANCELADA",
                  actor.role,
                  actor.id,
                  actor.reason
                )

                {:ok, updated}

              {:error, changeset} ->
                {:error, changeset}
            end
        end
    end
  end

  # HISTORY --------------------------------------------------------

  def list_ride_history(ride_id) do
    query =
      from e in RideEvent,
        where: e.ride_id == ^ride_id,
        order_by: [asc: e.inserted_at]

    {:ok, Repo.all(query)}
  end

  # helper para criar evento ---------------------------------------

  defp create_event(ride_id, from_state, to_state, actor_role, actor_id, reason) do
    %RideEvent{}
    |> RideEvent.changeset(%{
      ride_id: ride_id,
      from_state: from_state,
      to_state: to_state,
      actor_role: actor_role,
      actor_id: actor_id,
      reason: reason
    })
    |> Repo.insert()
  end
end
