# usar transection para saldo
defmodule BankingApiWeb.AccountController do
  use BankingApiWeb, :controller

  alias BankingApi.Accounts
  alias BankingApiWeb.Helpers

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"user_id" => user_id}) do
    with {:uuid, {:ok, _}} <- {:uuid, Ecto.UUID.cast(user_id)},
         {:ok, account} <- Accounts.get(user_id) do
      Helpers.send_json(conn, :ok, account)
    else
      {:uuid, :error} ->
        Helpers.send_json(conn, :bad_request, %{
          type: "bad_input",
          description: "Not a proper UUID v4"
        })

      {:error, :not_found} ->
        Helpers.send_json(conn, :not_found, %{type: "not_found", description: "Account not found"})
    end
  end
end
