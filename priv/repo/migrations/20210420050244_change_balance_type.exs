defmodule BankingApi.Repo.Migrations.ChangeBalanceType do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      modify(:balance, :bigint)
    end
  end
end
