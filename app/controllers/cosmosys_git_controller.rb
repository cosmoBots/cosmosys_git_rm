class CosmosysGitController < ApplicationController
  before_action :find_this_project#, :authorize, :except => [:find_project, :treeview]

  def menu
    if request.get? then
      print("menu GET!!!!!")
    else
      print("menu POST!!!!!")
    end            
  end

  def show
    if request.get? then
      print("show GET!!!!!")
    else
      print("show POST!!!!!")
    end        
  end

  def import
    if request.get? then
      print("import GET!!!!!")
    else
      print("import POST!!!!!")
    end

  end
  
  def export
    if request.get? then
      print("export GET!!!!!")      
    else
      print("export POST!!!!!")
    end
    ret = nil
    repo_folder,remoteurl = update_create_repo_folder()
    if repo_folder != nil then
      ret = export_project_repo(repo_folder,remoteurl)
      rm_mirror_folder = update_create_repo_rm_mirror(repo_folder)
    end
    if (ret != nil) then 
      flash[:notice] = "Everything went fine"
    else
      flash[:error] = "Something happened"
    end
  end

  def report
    if request.get? then
      print("reports GET!!!!!")
    else
      print("reports POST!!!!!")
    end    
  end

  def find_this_project
    # @project variable must be set before calling the authorize filter
    if (params[:issue_id]) then
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    else
      if(params[:id]) then
        @project = Project.find(params[:id])
      else
        @project = Project.first
      end
    end
    #print("Project: "+@project.to_s+"\n")
  end  

  private

  require 'fileutils'

  def create_template_repo(remoteurl)
    s = Setting.find_by_name("plugin_cosmosys_git")
    if (s != nil) then
      if (s.value != nil) then
        puts("The setting exists")
        reponame = s.value["repo_template_id"]
        if (reponame != nil) then
          ret = get_expected_repo_path(reponame)
          if  ret != nil then
            if not(File.directory?(ret)) then
              # Create it
              FileUtils.mkdir_p ret
              comando = "cp -r plugins/cosmosys_git/assets/template/* #{ret}"
              puts("\n\n #{comando}")
              `#{comando}`        
              comando = "cd #{ret}; git remote add origin #{remoteurl}"
              puts("\n\n #{comando}")
              `#{comando}`               
              comando = "cd #{ret}; git add .;git commit -m \"Initial commit\";git push all"
              puts("\n\n #{comando}")
              output = `#{comando}`               
              puts("=====================")
              puts(output)
              puts("Cloned?: "+ret)
              puts("Folder: "+ret)
            end
          else
            puts("Error, the setting does not exist")
          end
        end
      end
    else
      puts("The setting does not exist")
    end
    return ret    
  end

  def get_expected_repo_path(prj_identifier)
    s = Setting.find_by_name("plugin_cosmosys_git")
    if (s != nil) then
      if (s.value != nil) then
        puts("The setting exists")
        return s.value["repo_local_path"].gsub("%project_id%",prj_identifier)
      end
    else
      puts("The setting does not exist")
    end
    return nil
  end

  def get_expected_repo_rm_mirror_path(pridentifier)
    s = Setting.find_by_name("plugin_cosmosys_git")
    if (s != nil) then
      if (s.value != nil) then
        puts("The setting exists")
        return s.value["repo_redmine_path"].gsub("%project_id%",pridentifier)
      end
    else
      puts("The setting does not exist")
    end
    return nil
  end

  def download_create_template_repo(repo_folder)
    remoteurl = nil
    s = Setting.find_by_name("plugin_cosmosys_git")
    if (s != nil) then
      if (s.value != nil) then
        puts("The setting exists")
        ret = s.value["repo_template_id"]
        if (ret !=nil) then
          remoteurl = s.value["repo_server_path"].gsub("%project_id%",ret)
          puts("Template shall be cloned from "+remoteurl)
          path_folder = File.expand_path("..", repo_folder)
          if not(File.directory?(path_folder)) then
            # Create it
            FileUtils.mkdir_p path_folder
          end
          comando = "git clone #{remoteurl} #{repo_folder}"
          puts("\n\n #{comando}")
          output = `#{comando}`
          if (File.directory?(repo_folder)) then
            puts("Created!!!"+repo_folder)
          else
            create_template_repo(remoteurl)
          end
        end
      end
    else
      puts("The setting does not exist")
    end
    return remoteurl
  end

  def update_create_repo_folder
    # Chec if repo folder exists
    repo_folder = get_expected_repo_path(@project.identifier)
    if  repo_folder != nil then
      if not(File.directory?(repo_folder)) then
        # The folder does not exist, we need to pull it from the template repo
        remoteurl = download_create_template_repo(repo_folder)
        if remoteurl then
          puts("Cloned!: "+repo_folder+" "+remoteurl)
        else
          puts("Error trying to download template for "+repo_folder)
        end
      else
        if update_create_repo_folder(repo_folder) then
          puts("Updated!: "+repo_folder)
        else
          puts("Error trying to update "+ret)
        end        
      end
      puts("Folder: "+repo_folder)
    else
      puts("Error, the setting does not exist")
    end
    return repo_folder,remoteurl
  end

  def check_create_repo_rm_mirror(repo_folder)
    ret = get_expected_repo_rm_mirror_path(@project.identifier)
    if  ret != nil then
      if not(File.directory?(ret)) then
        # Create it
        puts("Creating!: "+ret)
        comando = "git clone --mirror #{repo_folder} #{ret}"
        print("\n\n #{comando}")
        `#{comando}`
      else
        comando = "cd #{ret}; git fetch"
        print("\n\n #{comando}")
        `#{comando}`
      end
      puts("Folder: "+ret)
    else
      puts("Error, the setting does not exist")
    end
    return ret    
  end

  def check_create_gitlab_prj
  end

  def import_project_repo
  end

  def report_repo
  end

  def export_project_repo(repo_folder,remoteurl)
    return true
  end

end
