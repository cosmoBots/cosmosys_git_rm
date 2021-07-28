require_dependency 'project'

# Patches Redmine's Project dynamically.
module ProjectPatchGit
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development

      has_one :cosmosys_project_git
      before_save :csys_git
    end

  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    def csys_git
      if self.cosmosys_project_git == nil then
        CosmosysProjectGit.create!(project: self)
      end
      self.cosmosys_project_git
    end
  end
end
# Add module to Project
Project.send(:include, ProjectPatchGit)

