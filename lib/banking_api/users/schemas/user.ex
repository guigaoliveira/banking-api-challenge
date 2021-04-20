defmodule BankingApi.Users.Schemas.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias BankingApi.Accounts.Schemas.Account

  @required [:name, :email]
  @optional []

  @derive {Jason.Encoder, only: [:id, :name, :email, :inserted_at, :updated_at]}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type Ecto.UUID

  schema "users" do
    field :name, :string
    field :email, :string
    has_one :account, Account

    timestamps()
  end

  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint(:email)
  end
end
