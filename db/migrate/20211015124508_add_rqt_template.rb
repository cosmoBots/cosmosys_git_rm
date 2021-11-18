class AddRqtTemplate < ActiveRecord::Migration[5.2]
  def up
    add_column :cosmosys_project_gits, :rpt_template_id, :integer, foreign_key: { to_table: :documents}
    add_index :cosmosys_project_gits,:rpt_template_id

    # Build the rpt_template for existing projects
    doc_cat = DocumentCategory.find_by_name("cSys")
    Project.all.each {|p|
      cpg = p.cosmosys_project_git
      cpg.rpt_template = p.documents.find_by_title("cSysReportTemplate")
      if cpg.rpt_template == nil then
        cpg.rpt_template = cpg.project.documents.new
        cpg.rpt_template.title = "cSysReportTemplate"
        cpg.rpt_template.category = doc_cat
        cpg.rpt_template.save
      else
        if cpg.rpt_template.category != doc_cat then
          cpg.rpt_template.category = doc_cat
          cpg.rpt_template.save
        end
      end
    }
      
  end
  def down
    remove_index :cosmosys_project_gits, :rpt_template_id    
    remove_column :cosmosys_project_gits, :rpt_template_id
  end
  def down
  end
end
