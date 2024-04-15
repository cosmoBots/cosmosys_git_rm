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
  permission :csys_git_export, :cosmosys_git => :export

  menu :project_menu, :cosmosys_git, {:controller => 'cosmosys_git', :action => 'menu' }, :caption => 'cosmoSysGit', :after => :activity, :param => :id

  def repo_server_path()
    if ENV["COSMOSYS_GIT_USER"]
      user = ENV["COSMOSYS_GIT_USER"]
      "ssh://git@gitlab/#{user}/%project_id%.git"
    else
      "ssh://git@gitlab/cosmobots/%project_id%.git"
    end
  end

  settings :default => {
    "repo_local_path" => "/home/redmine/gitbase/csys/%project_id%",
    "repo_server_path" => repo_server_path(),
    "repo_template_id" => "template",
    "repo_redmine_path" => "/home/redmine/gitbase/csys_rm/%project_id%.git",
    "import_path" => "01_importing/csys%project_code%.ods",
    "export_path" => "02_exporting/csys%project_code%.ods",
    "export_template_path" => "02_exporting/csExportTemplate.ods",
    "reporting_template_path" => "03_reporting/01_templates",
    "reporting_path" => "03_reporting/02_doc",
    "reporting_img_path" => "03_reporting/03_img"
    }, :partial => 'settings/cosmosys_git_settings'

  require 'cosmosys_git'
  # Patches to the Redmine core.
  require 'document_patch'
  require 'project_patch_git'
end
