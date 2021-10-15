class AddRqtTemplate < ActiveRecord::Migration[5.2]
  def up
    add_column :cosmosys_project_gits, :rpt_template_id, :integer, foreign_key: { to_table: :documents}
    add_index :cosmosys_project_gits,:rpt_template_id    
  end
  def down
    remove_index :cosmosys_project_gits, :rpt_template_id    
    remove_column :cosmosys_project_gits, :rpt_template_id
  end
  def down
  end
end
