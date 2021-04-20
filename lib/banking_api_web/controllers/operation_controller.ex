# usar transection para saldo
defmodule BankingApiWeb.OperationController do
  use BankingApiWeb, :controller

  alias BankingApi.Operations
  alias BankingApi.Operations.Inputs

  alias BankingApiWeb.InputValidation
  alias BankingApiWeb.Helpers

  @spec withdrawal(Plug.Conn.t(), map) :: Plug.Conn.t()
  def withdrawal(conn, params) do
    with {:ok, input} <- InputValidation.cast_and_apply(params, Inputs.Withdrawal),
         {:uuid, {:ok, _}} <- {:uuid, Ecto.UUID.cast(input.account_id)},
         {:ok, account} <- Operations.withdrawal(input) do
      Helpers.send_json(conn, :ok, account)
    else
      {:uuid, :error} ->
        Helpers.send_json(conn, :bad_request, %{
          type: "bad_input",
          description: "Not a proper UUID v4"
        })

      {:error, :insufficient_funds} ->
        Helpers.send_json(conn, :bad_request, %{
          type: "insufficient_funds",
          description: "Account does not have enough money available"
        })

      {:error, :not_found} ->
        Helpers.send_json(conn, :not_found, %{type: "not_found", description: "Account not found"})

      {:error, %Ecto.Changeset{errors: errors}} ->
        Helpers.send_json(conn, :bad_request, %{
          type: "bad_input",
          description: "Invalid input",
          details: Helpers.changeset_errors_to_details(errors)
        })
    end
  end

  @spec create_transaction(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create_transaction(conn, params) do
    with {:ok, input} <- InputValidation.cast_and_apply(params, Inputs.CreateTransaction),
         {:ok, _} <- Operations.create_transaction(input) do
      Helpers.send_json(conn, :ok, %{status: "success"})
    else
      {:error, :insufficient_funds} ->
        Helpers.send_json(conn, :bad_request, %{
          type: "insufficient_funds",
          description: "Sender's account does not have enough money available"
        })

      {:error, :source_account_not_found} ->
        Helpers.send_json(conn, :not_found, %{
          type: "not_found",
          description: "Sender's account does not exist"
        })

      {:error, :target_account_not_found} ->
        Helpers.send_json(conn, :not_found, %{
          type: "not_found",
          description: "Receiver's account does not exist"
        })

      {:error, %Ecto.Changeset{errors: errors}} ->
        Helpers.send_json(conn, :bad_request, %{
          type: "bad_input",
          description: "Invalid input",
          details: Helpers.changeset_errors_to_details(errors)
        })
    end
  end
end
