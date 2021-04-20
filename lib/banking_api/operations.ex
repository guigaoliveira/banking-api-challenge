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
      get_accounts(input.source_user_email, input.target_user_email)
    )
    |> Multi.run(:verify_balances_step, verify_balances(input.amount))
    |> Multi.run(:subtract_from_source_account_step, &subtract_from_source_account/2)
    |> Multi.run(:add_to_target_account_step, &add_to_target_account/2)
    |> Repo.transaction()
    |> case do
      {:ok, %{get_accounts_step: {source_account, target_account}}} ->
        {:ok, {source_account, target_account}}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  defp verify_balances(amount) do
    fn _repo, %{get_accounts_step: {source_account, target_account}} ->
      if source_account.balance < amount,
        do: {:error, :insufficient_funds},
        else: {:ok, {source_account, target_account, amount}}
    end
  end

  defp get_accounts(source_user_email, target_user_email) do
    fn repo, _ ->
      with {:source_account, %{account: source_account}} <-
             {:source_account, get_account_by_email(repo, source_user_email)},
           {:target_account, %{account: target_account}} <-
             {:target_account, get_account_by_email(repo, target_user_email)} do
        {:ok, {source_account, target_account}}
      else
        {:source_account, nil} -> {:error, :source_account_not_found}
        {:target_account, nil} -> {:error, :target_account_not_found}
      end
    end
  end

  defp get_account_by_email(repo, email) do
    User |> lock("FOR UPDATE") |> repo.get_by(email: email) |> repo.preload([:account])
  end

  defp subtract_from_source_account(repo, %{verify_balances_step: {source_account, _, amount}}) do
    update_account_balance(repo, source_account, source_account.balance - amount)
  end

  defp add_to_target_account(repo, %{verify_balances_step: {_, target_account, amount}}) do
    update_account_balance(repo, target_account, target_account.balance + amount)
  end

  defp update_account_balance(repo, account, balance) do
    account |> Account.changeset(%{balance: balance}) |> repo.update()
  end
end
