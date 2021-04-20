defmodule BankingApiWeb.UserController do
  use BankingApiWeb, :controller

  alias BankingApi.Users
  alias BankingApi.Users.Inputs
  alias BankingApi.Accounts

  alias BankingApiWeb.InputValidation
  alias BankingApiWeb.Helpers

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => user_id}) do
    with {:uuid, {:ok, _}} <- {:uuid, Ecto.UUID.cast(user_id)},
         {:ok, user} <- Users.get(user_id) do
      Helpers.send_json(conn, :ok, user)
    else
      {:uuid, :error} ->
        Helpers.send_json(conn, :bad_request, %{
          type: "bad_input",
          description: "Not a proper UUID v4"
        })

      {:error, :not_found} ->
        Helpers.send_json(conn, :not_found, %{type: "not_found", description: "User not found"})
    end
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, params) do
    with {:ok, input} <- InputValidation.cast_and_apply(params, Inputs.Create),
         {:ok, user} <- Users.create(input),
         {:ok, _account} <- Accounts.create(%{balance: 1000, user_id: user.id}) do
      Helpers.send_json(conn, :ok, user)
    else
      {:error, %Ecto.Changeset{errors: errors}} ->
        msg = %{
          type: "bad_input",
          description: "Invalid input",
          details: Helpers.changeset_errors_to_details(errors)
        }

        Helpers.send_json(conn, :bad_request, msg)
    end
  end
end
