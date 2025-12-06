defmodule RideFastApi.AccountsTest do
  use RideFastApi.DataCase

  alias RideFastApi.Accounts

  describe "users" do
    alias RideFastApi.Accounts.User

    import RideFastApi.AccountsFixtures

    @invalid_attrs %{name: nil, email: nil, phone: nil, password_hash: nil, created_at: nil, updated_at: nil}

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      valid_attrs = %{name: "some name", email: "some email", phone: "some phone", password_hash: "some password_hash", created_at: ~N[2025-12-05 18:46:00], updated_at: ~N[2025-12-05 18:46:00]}

      assert {:ok, %User{} = user} = Accounts.create_user(valid_attrs)
      assert user.name == "some name"
      assert user.email == "some email"
      assert user.phone == "some phone"
      assert user.password_hash == "some password_hash"
      assert user.created_at == ~N[2025-12-05 18:46:00]
      assert user.updated_at == ~N[2025-12-05 18:46:00]
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      update_attrs = %{name: "some updated name", email: "some updated email", phone: "some updated phone", password_hash: "some updated password_hash", created_at: ~N[2025-12-06 18:46:00], updated_at: ~N[2025-12-06 18:46:00]}

      assert {:ok, %User{} = user} = Accounts.update_user(user, update_attrs)
      assert user.name == "some updated name"
      assert user.email == "some updated email"
      assert user.phone == "some updated phone"
      assert user.password_hash == "some updated password_hash"
      assert user.created_at == ~N[2025-12-06 18:46:00]
      assert user.updated_at == ~N[2025-12-06 18:46:00]
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end

  describe "drivers" do
    alias RideFastApi.Accounts.Driver

    import RideFastApi.AccountsFixtures

    @invalid_attrs %{name: nil, status: nil, email: nil, phone: nil, password_hash: nil, created_at: nil, updated_at: nil}

    test "list_drivers/0 returns all drivers" do
      driver = driver_fixture()
      assert Accounts.list_drivers() == [driver]
    end

    test "get_driver!/1 returns the driver with given id" do
      driver = driver_fixture()
      assert Accounts.get_driver!(driver.id) == driver
    end

    test "create_driver/1 with valid data creates a driver" do
      valid_attrs = %{name: "some name", status: "some status", email: "some email", phone: "some phone", password_hash: "some password_hash", created_at: ~N[2025-12-05 18:47:00], updated_at: ~N[2025-12-05 18:47:00]}

      assert {:ok, %Driver{} = driver} = Accounts.create_driver(valid_attrs)
      assert driver.name == "some name"
      assert driver.status == "some status"
      assert driver.email == "some email"
      assert driver.phone == "some phone"
      assert driver.password_hash == "some password_hash"
      assert driver.created_at == ~N[2025-12-05 18:47:00]
      assert driver.updated_at == ~N[2025-12-05 18:47:00]
    end

    test "create_driver/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_driver(@invalid_attrs)
    end

    test "update_driver/2 with valid data updates the driver" do
      driver = driver_fixture()
      update_attrs = %{name: "some updated name", status: "some updated status", email: "some updated email", phone: "some updated phone", password_hash: "some updated password_hash", created_at: ~N[2025-12-06 18:47:00], updated_at: ~N[2025-12-06 18:47:00]}

      assert {:ok, %Driver{} = driver} = Accounts.update_driver(driver, update_attrs)
      assert driver.name == "some updated name"
      assert driver.status == "some updated status"
      assert driver.email == "some updated email"
      assert driver.phone == "some updated phone"
      assert driver.password_hash == "some updated password_hash"
      assert driver.created_at == ~N[2025-12-06 18:47:00]
      assert driver.updated_at == ~N[2025-12-06 18:47:00]
    end

    test "update_driver/2 with invalid data returns error changeset" do
      driver = driver_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_driver(driver, @invalid_attrs)
      assert driver == Accounts.get_driver!(driver.id)
    end

    test "delete_driver/1 deletes the driver" do
      driver = driver_fixture()
      assert {:ok, %Driver{}} = Accounts.delete_driver(driver)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_driver!(driver.id) end
    end

    test "change_driver/1 returns a driver changeset" do
      driver = driver_fixture()
      assert %Ecto.Changeset{} = Accounts.change_driver(driver)
    end
  end
end
