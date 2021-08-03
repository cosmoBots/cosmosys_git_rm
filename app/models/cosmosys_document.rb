class CosmosysDocument < ActiveRecord::Base
    belongs_to :document
  
    before_create :init_attr

    def self.find_uploadable_template_doc(p)
        return self.find_create_uploadable_import_doc(p,"template","cSysTemplate")
    end
    def self.find_uploadable_import_doc(p)
        return self.find_create_uploadable_import_doc(p,"import","cSysImport")
    end

    private
    def init_attr

    end
    def self.find_csys_uploadable_document(d)
        puts("+++find_csys_uploadable_document+++")
        errorstr = nil
        retpath = nil
        retdoc = nil
        retfile = nil
        doc_cat = DocumentCategory.find_by_name("cSys")
        if d.category != doc_cat then
            d.category = doc_cat
            d.save
        end
        a = d.attachments.reverse.first
        if a != nil then
            if d.csys.imported_on == nil or a.created_on > d.csys.imported_on then
                retpath = a.diskfile
                retdoc = d
                retfile = a
            else
                errorstr = "Could not import '"+d.title+"': The newest document attachment file is older ("+a.created_on.to_s+") than the last time it was imported ("+d.csys.imported_on.to_s+")"
            end
        else
            errorstr = "Could not import '"+d.title+"': The document has no files attached to it"
        end
        puts("ret:",retpath,"retstr:",errorstr)
        return retdoc,retfile,retpath,errorstr
    end

    def self.find_create_uploadable_import_doc(p,kind,name)
        ret = nil
        cg = p.csys_git
        if (cg != nil) then
            if kind == "template" then
                d = p.csys_git.doc_template
            else
                d = p.csys_git.doc_import
            end
            puts "doc_temp:",d
            if d == nil then
                # The document does not exist or is not correctly linked
                d = p.documents.where(title: name).first
                if d == nil then
                    d = p.documents.new
                    d.title = name
                end
                d.category = DocumentCategory.find_by_name("cSys")
                d.save
                if kind == "template" then
                    p.csys_git.doc_template = d
                else
                    p.csys_git.doc_import = d
                end
            end
            if d != nil then
                return self.find_csys_uploadable_document(d)
            end
        end
        return nil,nil,nil,"The "+kind+" does not exist in the project"        
    end    
end
