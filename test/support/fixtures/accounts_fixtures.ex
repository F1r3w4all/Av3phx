defmodule RideFastApi.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RideFastApi.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        created_at: ~N[2025-12-05 18:46:00],
        email: "some email",
        name: "some name",
        password_hash: "some password_hash",
        phone: "some phone",
        updated_at: ~N[2025-12-05 18:46:00]
      })
      |> RideFastApi.Accounts.create_user()

    user
  end

  @doc """
  Generate a driver.
  """
  def driver_fixture(attrs \\ %{}) do
    {:ok, driver} =
      attrs
      |> Enum.into(%{
        created_at: ~N[2025-12-05 18:47:00],
        email: "some email",
        name: "some name",
        password_hash: "some password_hash",
        phone: "some phone",
        status: "some status",
        updated_at: ~N[2025-12-05 18:47:00]
      })
      |> RideFastApi.Accounts.create_driver()

    driver
  end
end
