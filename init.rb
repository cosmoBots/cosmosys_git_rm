Redmine::Plugin.register :cosmosys_git do
  name 'Cosmosys Git plugin'
  author 'Txinto Vaz'
  description 'This is a plugin for Redmine'
  version '0.0.2'
  url 'http://cosmobots.eu'
  author_url 'http://cosmobots.eu'  

  requires_redmine_plugin :cosmosys , :version_or_higher => '0.0.2'

  permission :csys_git_menu, :cosmosys_git => :menu
  permission :csys_git_report, :cosmosys_git => :report

  menu :project_menu, :cosmosys_git, {:controller => 'cosmosys_git', :action => 'menu' }, :caption => 'cosmoSysGit', :after => :activity, :param => :id

  settings :default => {
    "repo_server_sync"=> true, 
    "repo_local_path"=>"/home/redmine/gitbase/csys/%project_id%", 
    "repo_server_path"=>"ssh://git@gitlab/cosmobots/%project_id%.git",
    "repo_template_id" => "template",
    "repo_redmine_sync" => true,
    "repo_redmine_path" => "/home/redmine/gitbase/csys_rm/%project_id%.git",
    "import_path" => "01_importing/csysImport.ods",
    "export_path" => "02_exporting/csysExport.ods",
    "export_template_path" => "02_exporting/csExportTemplate.ods",
    "reporting_template_path" => "03_reporting/01_templates",
    "reporting_path" => "03_reporting/02_doc",
    "reporting_img_path" => "03_reporting/03_img"
    }, :partial => 'settings/cosmosys_git_settings'

end
