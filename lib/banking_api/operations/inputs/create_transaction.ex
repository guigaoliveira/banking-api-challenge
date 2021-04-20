defmodule BankingApi.Operations.Inputs.CreateTransaction do
  use Ecto.Schema

  import Ecto.Changeset

  @required_fields [:email_sender, :email_receiver, :amount]
  @optional_fields []

  @primary_key false
  embedded_schema do
    field :email_sender, :string
    field :email_receiver, :string
    field :amount, :integer
  end

  def changeset(model \\ %__MODULE__{}, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:amount,
      greater_than_or_equal_to: 0,
      message: "must be greater than or equal to 0"
    )
  end
end
