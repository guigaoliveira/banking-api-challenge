defmodule BankingApi.Users.Inputs.Create do
  use Ecto.Schema

  import Ecto.Changeset

  @required_fields [:name, :email]
  @optional_fields []

  @primary_key false
  embedded_schema do
    field :name, :string
    field :email, :string
  end

  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, min: 3)
  end
end
