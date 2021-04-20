defmodule BankingApiWeb.OperationControllerTest do
  use BankingApiWeb.ConnCase, async: true

  alias BankingApi.Users.Schemas.User
  alias BankingApi.Accounts.Schemas.Account
  alias BankingApi.Repo

  describe "POST /api/operations/transaction" do
    test "fails with 404 when one of users does not exist", ctx do
      input = %{
        source_user_email: "not_exist@email.com",
        target_user_email: "not_exist_too@email.com",
        amount: 1
      }

      assert %{
               "description" => "Sender's account does not exist",
               "type" => "not_found"
             } =
               ctx.conn
               |> post("/api/operations/transaction", input)
               |> json_response(:not_found)
    end

    test "fails with 400 when amount is negative", ctx do
      source_user =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 0, user_id: source_user.id})

      target_user =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 100, user_id: target_user.id})

      input = %{
        source_user_email: source_user.email,
        target_user_email: target_user.email,
        amount: -100
      }

      assert %{
               "description" => "Invalid input",
               "type" => "bad_input",
               "details" => %{"amount" => "must be greater than or equal to 0"}
             } =
               ctx.conn
               |> post("/api/operations/transaction", input)
               |> json_response(:bad_request)

      assert %{balance: 0} = Repo.get_by(Account, user_id: source_user.id)
      assert %{balance: 100} = Repo.get_by(Account, user_id: target_user.id)
    end

    test "fails with 400 when user's account does not have sufficient funds", ctx do
      source_user =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 0, user_id: source_user.id})

      target_user =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 100, user_id: target_user.id})

      input = %{
        source_user_email: source_user.email,
        target_user_email: target_user.email,
        amount: 500
      }

      assert %{
               "description" => "Sender's account does not have enough money available",
               "type" => "insufficient_funds"
             } =
               ctx.conn
               |> post("/api/operations/transaction", input)
               |> json_response(:bad_request)

      assert %{balance: 0} = Repo.get_by(Account, user_id: source_user.id)
      assert %{balance: 100} = Repo.get_by(Account, user_id: target_user.id)
    end

    test "successfully create a new transaction", ctx do
      source_user =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 1000, user_id: source_user.id})

      target_user =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 100, user_id: target_user.id})

      input = %{
        source_user_email: source_user.email,
        target_user_email: target_user.email,
        amount: 500
      }

      assert %{"status" => status} =
               ctx.conn
               |> post("/api/operations/transaction", input)
               |> json_response(:ok)

      assert status == "success"

      assert %{balance: 500} = Repo.get_by(Account, user_id: source_user.id)
      assert %{balance: 600} = Repo.get_by(Account, user_id: target_user.id)
    end
  end
end
