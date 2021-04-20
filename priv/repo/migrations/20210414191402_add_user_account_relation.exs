defmodule BankingApi.Repo.Migrations.AddUserAccountRelation do
  use Ecto.Migration

  def change do
    alter table(:accounts, primary_key: false) do
      add :user_id, references(:users, type: :uuid)
    end
    alter table(:users, primary_key: false) do
      add :account_id, references(:accounts, type: :uuid)
    end
  end
end
