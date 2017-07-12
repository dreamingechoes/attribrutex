defmodule Repo.Migrations.CreateCustomField do
  use Ecto.Migration

  def change do
    create table(:custom_fields) do
      add :key, :string, null: false
      add :field_type, :integer, null: false, default: 0
      add :fieldable_type, :string, null: false

      add :inserted_at,  :utc_datetime, null: false
      add :updated_at,  :utc_datetime, null: false
    end
  end
end
