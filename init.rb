Redmine::Plugin.register :cosmosys_git do
  name 'Cosmosys Git plugin'
  author 'Txinto Vaz'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://cosmobots.eu'
  author_url 'http://cosmobots.eu'  

  #requires_redmine_plugin :cosmosys , :version_or_higher => '0.0.2'

  permission :csys_git_menu, :cosmosys_git => :menu
  permission :csys_git_report, :cosmosys_git => :report

  menu :project_menu, :cosmosys_git, {:controller => 'cosmosys_git', :action => 'menu' }, :caption => 'cosmoSysGit', :after => :activity, :param => :id

  settings :default => {
    'repo_local_path' => "/home/redmine/gitbase/repos/csys/%project_id%",
    'repo_server_sync' => :false,
    'repo_server_path'  => "http://gitlab/issues/csys/%project_id%.git",
    'repo_template_id'  => 'template',
    'repo_redmine_path' => "/home/redmine/gitbase/csys_rm/%project_id%.git",
    'repo_redmine_sync' => :true,
    'relative_uploadfile_path' => "uploading/csysUpload.ods",
    'relative_downloadfile_path' => "downloading/csysDownload.ods",
    'relative_reporting_path' => "reporting",
    'relative_img_path' => "reporting/doc/img"
  }, :partial => 'settings/cosmosys_git_settings'

end
