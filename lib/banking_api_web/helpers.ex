defmodule BankingApiWeb.Helpers do
  use BankingApiWeb, :controller

  def send_json(conn, status, body) do
    conn
    |> put_status(status)
    |> json(body)
  end

  def changeset_errors_to_details(errors) do
    errors
    |> Enum.map(fn {key, {message, _opts}} -> {key, message} end)
    |> Map.new()
  end
end
