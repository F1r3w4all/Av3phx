defmodule RideFastApi.Rides do
  import Ecto.Query, warn: false
  alias RideFastApi.Repo
  alias RideFastApi.Rides.Ride
  alias RideFastApi.Accounts.Driver
  import Ecto.Query

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

  def accept_ride(ride_id, driver_id, vehicle_id) do
    Repo.transaction(fn ->
      # 1) Carrega ride com lock (SELECT ... FOR UPDATE)
      ride_query =
        from r in Ride,
          where: r.id == ^ride_id,
          lock: "FOR UPDATE"

      ride = Repo.one(ride_query)

      if ride == nil do
        {:error, :not_found}
      else
        # 2) Valida status SOLICITADA
        if ride.status != "SOLICITADA" do
          {:error, :invalid_status}
        else
          # 3) Carrega driver e valida status + disponibilidade
          driver = Repo.get(Driver, driver_id)

          cond do
            driver == nil ->
              {:error, :driver_not_found}

            driver.status != "available" and driver.status != "ACTIVE" ->
              {:error, :driver_inactive}

            driver_has_active_ride?(driver_id) ->
              {:error, :driver_busy}

            true ->
              # 4) Atualiza ride para ACEITA, atribui driver e veículo
              changes =
                %{status: "ACEITA", driver_id: driver_id, vehicle_id: vehicle_id}

              case Repo.update(Ecto.Changeset.change(ride, changes)) do
                {:ok, updated_ride} ->
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

  def get_ride_with_details(id) do
    Ride
    |> Repo.get(id)
    |> Repo.preload([:user, :driver, :vehicle])
  end
end
