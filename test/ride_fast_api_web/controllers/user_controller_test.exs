defmodule RideFastApiWeb.UserControllerTest do
  use RideFastApiWeb.ConnCase

  import RideFastApi.AccountsFixtures
  alias RideFastApi.Accounts.User

  @create_attrs %{
    name: "some name",
    email: "some email",
    phone: "some phone",
    password_hash: "some password_hash",
    created_at: ~N[2025-12-05 18:46:00],
    updated_at: ~N[2025-12-05 18:46:00]
  }
  @update_attrs %{
    name: "some updated name",
    email: "some updated email",
    phone: "some updated phone",
    password_hash: "some updated password_hash",
    created_at: ~N[2025-12-06 18:46:00],
    updated_at: ~N[2025-12-06 18:46:00]
  }
  @invalid_attrs %{name: nil, email: nil, phone: nil, password_hash: nil, created_at: nil, updated_at: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get(conn, ~p"/api/users")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/users", user: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/users/#{id}")

      assert %{
               "id" => ^id,
               "created_at" => "2025-12-05T18:46:00",
               "email" => "some email",
               "name" => "some name",
               "password_hash" => "some password_hash",
               "phone" => "some phone",
               "updated_at" => "2025-12-05T18:46:00"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/users", user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      conn = put(conn, ~p"/api/users/#{user}", user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/users/#{id}")

      assert %{
               "id" => ^id,
               "created_at" => "2025-12-06T18:46:00",
               "email" => "some updated email",
               "name" => "some updated name",
               "password_hash" => "some updated password_hash",
               "phone" => "some updated phone",
               "updated_at" => "2025-12-06T18:46:00"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, ~p"/api/users/#{user}", user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, ~p"/api/users/#{user}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/users/#{user}")
      end
    end
  end

  defp create_user(_) do
    user = user_fixture()

    %{user: user}
  end
end
