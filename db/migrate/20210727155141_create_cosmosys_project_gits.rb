class CreateCosmosysProjectGits < ActiveRecord::Migration[5.2]
  def up
    create_table :cosmosys_project_gits do |t|
      t.integer :project_id
      t.timestamp :last_import
    end
    add_index :cosmosys_project_gits, :project_id
  end
  def down
    remove_index :cosmosys_project_gits, :project_id
    drop_table :cosmosys_project_gits
  end
end
