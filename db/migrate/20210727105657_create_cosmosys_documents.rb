class CreateCosmosysDocuments < ActiveRecord::Migration[5.2]
  def up 
    doctemp = DocumentCategory.new
    doctemp.name = "cSys"
    doctemp.save

    create_table :cosmosys_documents do |t|
      t.integer :document_id, foreign_key: true
      t.timestamp :imported_on
    end
    add_index :cosmosys_documents, :document_id

		Role.all.each{|tr|
			changed = false
=begin      
			if tr.permissions.include?(:view_issues) then
				tr.permissions += [
			
				]
				changed = true
			end
=end
			if tr.permissions.include?(:edit_issues) then
				tr.permissions += [
          :csys_git_menu,
          :csys_git_report
				]
				changed = true
			end
			if changed then
				tr.save
			end
		}
    
  end

  def down
    remove_index :cosmosys_documents, :document_id
    drop_table :cosmosys_documents
    
    # If there is a document category different from the csysImport or csysTemplate ones, the documents will be moved there
    # If there is no document category, then the documents will be destroyed!!!!
    freecategory = nil
    doctemp = DocumentCategory.find_by_name("cSys")
    DocumentCategory.all.each{|cat|
      if freecategory == nil then
        if cat != doctemp then
          freecategory = cat
        end
      end
    }

    Document.where(category: doctemp).each{|d|
      if freecategory != nil then
        d.category = freecategory
        d.save
      else
        d.destroy
      end
    }
    doctemp.destroy
  end
end