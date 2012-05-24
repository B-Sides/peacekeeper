Sequel.migration do
  up do
    create_table(:businesses) do
      primary_key :id
      String :name
    end
  end

  down do
    drop_table(:businesses)
  end
end
