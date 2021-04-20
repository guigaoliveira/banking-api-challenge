defmodule BankingApi.Accounts do
  require Logger

  alias BankingApi.Accounts.Schemas.Account
  alias BankingApi.Repo

  @spec get(String.t()) :: {:error, :not_found} | {:ok, map()}
  def get(user_id) do
    Logger.debug("Fetch account by user_id: #{inspect(user_id)}")

    case Account |> Repo.get_by(user_id: user_id) do
      nil -> {:error, :not_found}
      account -> {:ok, account}
    end
  end

  @spec create(%{:balance => any, :user_id => any, optional(any) => any}) :: any
  def create(%{balance: balance, user_id: user_id}) do
    Logger.info("Inserting new account")

    %{balance: balance, user_id: user_id}
    |> Account.changeset()
    |> Repo.insert()
  end
end
