class CosmosysProjectGit < ActiveRecord::Base
    belongs_to :project
    belongs_to :doc_import, :class_name => "Document"
    belongs_to :doc_template, :class_name => "Document"
  
    before_create :init_attr

    def self.get_expected_repo_path(prj_identifier)
        puts("+++++++get_expected_repo_path++++++++")    
        s = Setting.find_by_name("plugin_cosmosys_git")
        if (s != nil) then
          if (s.value != nil) then
            puts("The setting exists")
            ret = s.value["repo_local_path"].gsub("%project_id%",prj_identifier)
            ret2 = s.value["repo_server_path"].gsub("%project_id%",prj_identifier)
            return ret,ret2
          end
        else
          puts("The setting does not exist")
        end
        return nil,nil,s
    end
    
    def get_import_path
        return get_setting_with_code("import_path")
    end    

    def get_export_path
        return get_setting_with_code("export_path")
    end

    def get_setting_with_code(str)
        s3 = nil
        retstr = nil
        s = Setting.find_by_name("plugin_cosmosys_git")
        if (s != nil) then
            if (s.value != nil) then
                puts s.value
                s3 = s.value[str].gsub("%project_code%",self.project.code)
            else
                retstr = "The setting value for the cosmosysGit plugin does not exist: plugin_cosmosys_git.value"
            end
        else
            retstr = "The setting entry for the cosmosysGit plugin does not exist: plugin_cosmosys_git"
        end
        return s3,retstr,s
    end

    private
    def init_attr
        doc_cat = DocumentCategory.find_by_name("cSys")
        self.doc_import = project.documents.find_by_title("cSysImport")
        if self.doc_import == nil then
            self.doc_import = self.project.documents.new
            self.doc_import.title = "cSysImport"
            self.doc_import.category = doc_cat
            self.doc_import.save
        else
            if self.doc_import.category != doc_cat then
                self.doc_import.category = doc_cat
                self.doc_import.save
            end
        end
        self.doc_template = project.documents.find_by_title("cSysTemplate")
        if self.doc_template == nil then
            self.doc_template = self.project.documents.new
            self.doc_template.title = "cSysTemplate"
            self.doc_template.category = doc_cat
            self.doc_template.save            
        else
            if self.doc_template.category != doc_cat then
                self.doc_template.category = doc_cat
                self.doc_template.save
            end
        end
    end
end
