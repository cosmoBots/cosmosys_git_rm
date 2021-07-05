  
# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'cosmosys_git/:id/menu', :to => 'cosmosys_git#menu'
get 'cosmosys_git/:id/report', :to => 'cosmosys_git#report'
get 'cosmosys_git/:id/export', :to => 'cosmosys_git#export'
get 'cosmosys_git/:id/import', :to => 'cosmosys_git#import'

post 'cosmosys_git/:id/report', :to => 'cosmosys_git#report'
post 'cosmosys_git/:id/import', :to => 'cosmosys_git#import'
post 'cosmosys_git/:id/export', :to => 'cosmosys_git#export'
