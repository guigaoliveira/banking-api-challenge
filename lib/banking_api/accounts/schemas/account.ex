defmodule BankingApi.Accounts.Schemas.Account do
  @moduledoc """
  The author of a post.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias BankingApi.Users.Schemas.User

  @required_fields [:balance, :user_id]
  @optional_fields []

  @derive {Jason.Encoder, only: [:id, :user_id, :balance]}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accounts" do
    field :balance, :integer
    belongs_to :user, User
    timestamps()
  end

  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:balance,
      greater_than_or_equal_to: 0,
      message: "must be greater than or equal to 0"
    )
  end
end
