defmodule RideFastApiWeb.DriverJSON do
  alias RideFastApi.Accounts.Driver
  alias Ecto.Association.NotLoaded

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
      inserted_at: driver.inserted_at,
      # associações renderizadas de forma segura
      profile: render_profile(driver.profile),
      vehicles: render_vehicles(driver.vehicles),
      languages_spoken: render_languages(driver.languages)
    }
  end

  # ---------- PROFILE (sem birth_date) ----------
  defp render_profile(%NotLoaded{}), do: nil
  defp render_profile(nil), do: nil

  defp render_profile(profile) do
    %{
      # birth_date removido
      license_number: profile.license_number
      # ... outros campos de profile, se quiser manter
    }
  end

  # ---------- VEHICLES ----------
  defp render_vehicles(%NotLoaded{}), do: []
  defp render_vehicles(nil), do: []
  defp render_vehicles(vehicles), do: Enum.map(vehicles, &render_vehicle/1)

  defp render_vehicle(vehicle) do
    %{
      model: vehicle.model,
      license_plate: vehicle.license_plate,
      color: vehicle.color
      # ... outros campos de vehicle
    }
  end

  # ---------- LANGUAGES ----------
  defp render_languages(%NotLoaded{}), do: []
  defp render_languages(nil), do: []
  defp render_languages(languages), do: Enum.map(languages, &render_language/1)

  defp render_language(language) do
    %{
      code: language.code,
      name: language.name
    }
  end
end
