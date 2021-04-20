defmodule BankingApi.Accounts do
  require Logger

  alias BankingApi.Accounts.Schemas.Account
  alias BankingApi.Repo

  @spec get(String.t()) :: {:error, :not_found} | {:ok, map()}
  def get(user_id) do
    Logger.debug("Fetch account by user_id: #{inspect(user_id)}")

    case Repo.get_by(Account, user_id: user_id) do
      nil -> {:error, :not_found}
      account -> {:ok, account}
    end
  end

  def create(params) do
    Logger.info("Inserting new account")

    params
    |> Account.changeset()
    |> Repo.insert()
  end
end
