defmodule BankingApiWeb.AccountControllerTest do
  use BankingApiWeb.ConnCase, async: true

  alias BankingApi.Users.Schemas.User
  alias BankingApi.Accounts.Schemas.Account
  alias BankingApi.Repo

  describe "GET /api/accounts/:user_id" do
    test "fail if id is not an UUID", ctx do
      assert ctx.conn
             |> get("/api/accounts/qualquercoisa")
             |> json_response(:bad_request) == %{
               "description" => "Not a proper UUID v4",
               "type" => "bad_input"
             }
    end

    test "fail if there are no accounts with the given id", ctx do
      assert ctx.conn
             |> get("/api/accounts/#{Ecto.UUID.generate()}")
             |> json_response(:not_found) == %{
               "description" => "Account not found",
               "type" => "not_found"
             }
    end

    test "successfully show account details", ctx do
      user = Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})
      account = Repo.insert!(%Account{balance: 1000, user_id: user.id})

      assert %{
               "id" => id,
               "user_id" => user_id,
               "balance" => balance
             } =
               ctx.conn
               |> get("/api/accounts/#{user.id}")
               |> json_response(:ok)

      assert id == account.id
      assert user_id == account.user_id
      assert balance == account.balance
    end
  end
end
