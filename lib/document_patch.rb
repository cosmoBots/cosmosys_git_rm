require_dependency 'document'

# Patches Redmine's Document dynamically.

module DocumentPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      
      has_one :cosmosys_document

    end

  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    def csys
      if self.cosmosys_document == nil then
          CosmosysDocument.create!(document: self)
      end    
      self.cosmosys_document
    end
  end
end

# Add module to Document
Document.send(:include, DocumentPatch)

