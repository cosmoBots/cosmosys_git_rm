class CreateCosmosysProjectGits < ActiveRecord::Migration[5.2]
  def up
    create_table :cosmosys_project_gits do |t|
      t.integer :project_id, foreign_key: true
      t.timestamp :last_import
      t.integer :doc_import_id, foreign_key: { to_table: :documents}
      t.integer :doc_template_id, foreign_key: { to_table: :documents}
    end
    add_index :cosmosys_project_gits,:project_id
    add_index :cosmosys_project_gits,:doc_import_id
    add_index :cosmosys_project_gits,:doc_template_id    
  end
  def down
    remove_index :cosmosys_project_gits,:project_id
    remove_index :cosmosys_project_gits,:doc_import_id
    remove_index :cosmosys_project_gits,:doc_template_id    
    drop_table :cosmosys_project_gits
  end
end
