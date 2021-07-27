class CosmosysDocument < ActiveRecord::Base
    belongs_to :document
  
    before_create :init_attr
  
    def self.find_uploadable_template_doc(p)
        return self.find_csys_uploadable_document(p,"template","csysTemplate","cSys")
    end
=begin
=> "#<Attachment id: 2, container_id: 2, container_type: \"Document\", 
filename: \"csysExport (7).ods\", disk_filename: \"210727114541_8d44e66729517168501d02936fa13f8e.ods\", 
filesize: 1631996, content_type: \"application/vnd.oasis.opendocument.spreadsheet\", 
digest: \"873e94430c0066bc1fe31b3d7975abce7248d9c28e034cef5a...\", downloads: 0, author_id: 1, 
created_on: \"2021-07-27 11:45:41\", description: \"\", disk_directory: \"2021/07\">"
=end    
    def self.find_uploadable_import_doc(p)
        return self.find_csys_uploadable_document(p,"requirements","csysImport","cSys")
    end

    private
    def init_attr

    end
    def self.find_csys_uploadable_document(p,kind,title,categoryname)
        puts("+++find_csys_uploadable_document+++")
        continue_search = true
        errorstr = nil
        retpath = nil
        retdoc = nil
        retfile = nil
        doc_category = nil
        p.documents.each{|d|
            if continue_search then
                if d.title == title then
                    continue_search = false
                    if doc_category == nil then
                        doc_category = DocumentCategory.find_by_name(categoryname)
                    end
                    if d.category == doc_category then
                        a = d.attachments.reverse.first
                        if a != nil then
                            if d.csys.imported_on == nil or a.created_on > d.csys.imported_on then
                                retpath = a.diskfile
                                retdoc = d
                                retfile = a
                            else
                                errorstr = "Could not import the "+kind+": The newest '"+title+"' document attachment file is older ("+a.created_on.to_s+") than the last time it was imported ("+d.csys.imported_on.to_s+")"
                            end
                        else
                            errorstr = "Could not import the "+kind+": The '"+title+"' document has no files attached to it"
                        end
                    else
                        errorstr = "Could not import the "+kind+": The '"+title+"' document is not having the '"+categoryname+"' category."
                    end
                end
            end
        }
        if retpath == nil and errorstr == nil then
            errorstr = "Could not import the "+kind+": in the project there must exist a document called '"+title+"' within of the '"+categoryname+"' category"
        end
        puts("ret:",retpath,"retstr:",errorstr)
        return retdoc,retfile,retpath,errorstr
    end
end
