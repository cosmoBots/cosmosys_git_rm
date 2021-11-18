class CosmosysDocument < ActiveRecord::Base
    belongs_to :document
  
    before_create :init_attr

    def self.find_uploadable_template_doc(p)
        return self.find_create_uploadable_doc(p,"template","cSysTemplate")
        puts("+++find_uploadable_template_doc+++")
    end
    def self.find_uploadable_import_doc(p)
        puts("+++find_uploadable_import_doc+++")
        return self.find_create_uploadable_doc(p,"import","cSysImport")
    end
    def self.find_uploadable_template_report(p)
        return self.find_create_uploadable_doc(p,"reportTemplate","cSysReportTemplate")
        puts("+++find_uploadable_template_report+++")
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
            if true or d.csys.imported_on == nil or a.created_on > d.csys.imported_on then
                retpath = a.diskfile
                puts("retpath =",retpath)
                retdoc = d
                puts("retdoc =",retpath)
                retfile = a
                puts("retfile =",retpath)
            else
                errorstr = "Could not import '"+d.title+"': The newest document attachment file is older ("+a.created_on.to_s+") than the last time it was imported ("+d.csys.imported_on.to_s+")"
            end
        else
            errorstr = "Could not import '"+d.title+"': The document has no files attached to it"
        end
        puts("ret:",retpath,"retstr:",errorstr)
        return retdoc,retfile,retpath,errorstr
    end

    def self.find_create_uploadable_doc(p,kind,name)
        puts("+++find_csys_uploadable_doc+++"+kind)
        ret = nil
        cg = p.csys_git
        if (cg != nil) then
            if kind == "import" then
                d = p.csys_git.doc_import
            else
                if kind == "template" then
                    d = p.csys_git.doc_template
                else
                    if kind == "reportTemplate" then
                        d = p.csys_git.rpt_template
                        if d == nil then
                            # Try to recover from unconsistent installation
                            p.csys_git.rpt_template = p.documents.find_by_title("cSysReportTemplate")
                            p.csys_git.save
                            d = p.csys_git.rpt_template
                        end
                    end
                end
            end
            puts "doc_temp:",d.title
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
                    if kind == "import" then
                        p.csys_git.doc_import = d
                    else
                        if king == "reportTemplate" then
                            p.csys_git.rpt_template = d
                        end
                    end
                end
            end
            if d != nil then
                return self.find_csys_uploadable_document(d)
            end
        end
        return nil,nil,nil,"The "+kind+" does not exist in the project"        
    end    
end
