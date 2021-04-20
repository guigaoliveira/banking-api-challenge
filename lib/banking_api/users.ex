defmodule BankingApi.Users do
  require Logger

  alias BankingApi.Users.Inputs
  alias BankingApi.Users.Schemas.User
  alias BankingApi.Repo

  @spec get(any) :: {:error, :not_found} | {:ok, any}
  def get(user_id) do
    Logger.debug("Fetch user by id: #{inspect(user_id)}")

    case User |> Repo.get(user_id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def create(%Inputs.Create{} = input) do
    Logger.info("Inserting new user")

    %{name: input.name, email: input.email} |> User.changeset() |> Repo.insert()
  end
end
