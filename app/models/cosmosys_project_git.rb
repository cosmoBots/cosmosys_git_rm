class CosmosysProjectGit < ActiveRecord::Base
    belongs_to :project
  
    before_create :init_attr


    private
    def init_attr
    end
end
