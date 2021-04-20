defmodule BankingApi.Operations do
  require Logger

  alias BankingApi.Operations.Inputs
  alias BankingApi.Accounts.Schemas.Account
  alias BankingApi.Users.Schemas.User
  alias BankingApi.Repo
  alias Ecto.Multi
  import Ecto.Query

  def withdrawal(%Inputs.Withdrawal{} = input) do
    Logger.info("Starting withdrawal operation")

    Multi.new()
    |> Multi.run(:get_account_step, get_account_by_id(input.account_id))
    |> Multi.run(:update_balance, subtract_balance_account(input.amount))
    |> Repo.transaction()
    |> case do
      {:ok, %{update_balance: update_balance}} -> {:ok, update_balance}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp get_account_by_id(id) do
    fn repo, _changes ->
      case Account |> lock("FOR UPDATE") |> repo.get(id) do
        nil -> {:error, :not_found_account}
        account -> {:ok, account}
      end
    end
  end

  defp subtract_balance_account(amount) do
    fn repo, %{get_account_step: account} ->
      case account |> Account.changeset(%{balance: account.balance - amount}) |> repo.insert() do
        {:ok, account} -> {:ok, account}
        {:error, _} -> {:error, :insufficient_funds}
      end
    end
  end

  def create_transaction(%Inputs.CreateTransaction{} = input) do
    Logger.info("Starting transaction operation")

    Multi.new()
    |> Multi.run(
      :get_accounts_step,
      get_accounts(input.email_sender, input.email_receiver)
    )
    |> Multi.run(:verify_balances_step, verify_balances(input.amount))
    |> Multi.run(:subtract_from_account_sender_step, &subtract_from_account_sender/2)
    |> Multi.run(:add_to_account_receiver_step, &add_to_account_receiver/2)
    |> Repo.transaction()
    |> case do
      {:ok, %{get_accounts_step: {account_sender, account_receiver}}} ->
        {:ok, {account_sender, account_receiver}}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp verify_balances(amount) do
    fn _repo, %{get_accounts_step: {account_sender, account_receiver}} ->
      if account_sender.balance < amount,
        do: {:error, :insufficient_funds},
        else: {:ok, {account_sender, account_receiver, amount}}
    end
  end

  defp get_accounts(email_sender, email_receiver) do
    fn repo, _ ->
      with {:account_sender, %{account: account_sender}} <-
             {:account_sender, get_account_by_email(repo, email_sender)},
           {:account_receiver, %{account: account_receiver}} <-
             {:account_receiver, get_account_by_email(repo, email_receiver)} do
        {:ok, {account_sender, account_receiver}}
      else
        {:account_sender, nil} -> {:error, :account_sender_not_found}
        {:account_receiver, nil} -> {:error, :account_receiver_not_found}
      end
    end
  end

  defp get_account_by_email(repo, email) do
    User |> lock("FOR UPDATE") |> repo.get_by(email: email) |> repo.preload([:account])
  end

  defp subtract_from_account_sender(repo, %{verify_balances_step: {account_sender, _, amount}}) do
    update_account_balance(repo, account_sender, account_sender.balance - amount)
  end

  defp add_to_account_receiver(repo, %{verify_balances_step: {_, account_receiver, amount}}) do
    update_account_balance(repo, account_receiver, account_receiver.balance + amount)
  end

  defp update_account_balance(repo, account, balance) do
    account |> Account.changeset(%{balance: balance}) |> repo.update()
  end
end
