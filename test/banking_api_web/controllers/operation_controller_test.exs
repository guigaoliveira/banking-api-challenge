defmodule BankingApiWeb.OperationControllerTest do
  use BankingApiWeb.ConnCase, async: true

  alias BankingApi.Users.Schemas.User
  alias BankingApi.Accounts.Schemas.Account
  alias BankingApi.Repo

  describe "POST /api/operations/transaction" do
    test "fails with 404 when one of users does not exist", ctx do
      input = %{
        email_sender: "not_exist@email.com",
        email_receiver: "not_exist_too@email.com",
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
      user_sender =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 0, user_id: user_sender.id})

      user_receiver =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 100, user_id: user_receiver.id})

      input = %{
        email_sender: user_sender.email,
        email_receiver: user_receiver.email,
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

      assert %{balance: 0} = Repo.get_by(Account, user_id: user_sender.id)
      assert %{balance: 100} = Repo.get_by(Account, user_id: user_receiver.id)
    end

    test "fails with 400 when user's account does not have sufficient funds", ctx do
      user_sender =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 0, user_id: user_sender.id})

      user_receiver =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 100, user_id: user_receiver.id})

      input = %{email_sender: user_sender.email, email_receiver: user_receiver.email, amount: 500}

      assert %{
               "description" => "Sender's account does not have enough money available",
               "type" => "insufficient_funds"
             } =
               ctx.conn
               |> post("/api/operations/transaction", input)
               |> json_response(:bad_request)

      assert %{balance: 0} = Repo.get_by(Account, user_id: user_sender.id)
      assert %{balance: 100} = Repo.get_by(Account, user_id: user_receiver.id)
    end

    test "successfully create a new transaction", ctx do
      user_sender =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 1000, user_id: user_sender.id})

      user_receiver =
        Repo.insert!(%User{email: "#{Ecto.UUID.generate()}@email.com", name: "Some name"})

      Repo.insert!(%Account{balance: 100, user_id: user_receiver.id})

      input = %{email_sender: user_sender.email, email_receiver: user_receiver.email, amount: 500}

      assert %{"status" => status} =
               ctx.conn
               |> post("/api/operations/transaction", input)
               |> json_response(:ok)

      assert status == "success"

      assert %{balance: 500} = Repo.get_by(Account, user_id: user_sender.id)
      assert %{balance: 600} = Repo.get_by(Account, user_id: user_receiver.id)
    end
  end
end
