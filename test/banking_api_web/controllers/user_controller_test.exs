defmodule BankingApiWeb.UserControllerTest do
  use BankingApiWeb.ConnCase, async: true

  alias BankingApi.Users.Schemas.User
  alias BankingApi.Repo

  describe "POST /api/users" do
    test "fail with 400 when name is too small", ctx do
      input = %{"name" => "A", "email" => "user@email.com"}

      assert ctx.conn
             |> post("/api/users", input)
             |> json_response(:bad_request) == %{
               "description" => "Invalid input",
               "type" => "bad_input",
               "details" => %{
                 "name" => "should be at least %{count} character(s)"
               }
             }
    end

    test "fail with 400 when required fields are missing", ctx do
      input = %{}

      assert ctx.conn
             |> post("/api/users", input)
             |> json_response(:bad_request) == %{
               "description" => "Invalid input",
               "type" => "bad_input",
               "details" => %{
                 "email" => "can't be blank",
                 "name" => "can't be blank"
               }
             }
    end

    test "fail with 400 when email is already taken", ctx do
      email = "#{Ecto.UUID.generate()}@email.com"

      Repo.insert!(%User{email: email})

      input = %{
        "name" => "Um Dois Três de Oliveira Quatro",
        "email" => email
      }

      assert ctx.conn
             |> post("/api/users", input)
             |> json_response(:bad_request) == %{
               "description" => "Invalid input",
               "type" => "bad_input",
               "details" => %{"email" => "has already been taken"}
             }
    end

    test "successfully create a new user", ctx do
      user_email = "#{Ecto.UUID.generate()}@email.com"

      input = %{
        email: user_email,
        name: "Some name"
      }

      assert %{
               "email" => email,
               "name" => name,
               "id" => id,
               "inserted_at" => inserted_at,
               "updated_at" => updated_at
             } =
               ctx.conn
               |> post("/api/users", input)
               |> json_response(:ok)

      assert name == input.name
      assert email == input.email
      assert is_binary(id)
      assert is_binary(inserted_at)
      assert is_binary(updated_at)
    end
  end

  describe "GET /api/users/:id" do
    test "fail if id is not an UUID", ctx do
      assert ctx.conn
             |> get("/api/users/qualquercoisa")
             |> json_response(:bad_request) == %{
               "description" => "Not a proper UUID v4",
               "type" => "bad_input"
             }
    end

    test "fail if there are no users with the given id", ctx do
      assert ctx.conn
             |> get("/api/users/#{Ecto.UUID.generate()}")
             |> json_response(:not_found) == %{
               "description" => "User not found",
               "type" => "not_found"
             }
    end

    test "successfully show user details", ctx do
      user = Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      assert %{
               "email" => email,
               "id" => id,
               "inserted_at" => inserted_at,
               "name" => name,
               "updated_at" => updated_at
             } =
               ctx.conn
               |> get("/api/users/#{user.id}")
               |> json_response(:ok)

      assert name == user.name
      assert email == user.email
      assert id == user.id
      assert inserted_at == NaiveDateTime.to_iso8601(user.inserted_at)
      assert updated_at == NaiveDateTime.to_iso8601(user.updated_at)
    end
  end
end
