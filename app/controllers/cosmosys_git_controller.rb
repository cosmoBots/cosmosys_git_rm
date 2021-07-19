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
      ret = nil
      returnmessage = ""
      repo_folder,remoteurl = update_create_repo_folder()
      if repo_folder != nil then
        retvalue,retstr = export_project_repo(repo_folder)
        if (retvalue) then
          ret = commit_push_project_repo(repo_folder)
          if (ret) then
            rm_mirror_folder = update_create_repo_rm_mirror(remoteurl)
            if rm_mirror_folder != nil then
              returnmessage += "Everything went OK"
            else
              ret = false
              returnmessage += "Problems creating the mirror Redmine repo"
            end
          else
            returnmessage += "Problems commiting/pushing the Git repo"
          end
        else
          returnmessage += retstr
        end
      end
      if (ret != nil) then 
        flash[:notice] = returnmessage
      else
        flash[:error] = returnmessage
      end
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
  require 'yaml'
  require 'gitlab'

  def commit_push_project_repo(repo_folder)
    comando = "cd #{repo_folder}; git add .;git commit -m \"[csys bot] Export executed\";git push --all"
    puts("\n\n #{comando}")
    `#{comando}`
    return true
  end

  def check_create_gitlab_prj(gitlabconfig, prj_identifier, ssh_url)
    puts("+++++++check_create_gitlab_prj++++++++")    
    Gitlab.configure do |config|
      config.endpoint = gitlabconfig['endpoint']+'/api/v4'
      config.private_token  = gitlabconfig['authtoken']
    end
    puts("++++++++++++++++++++++++++ GITLAB connection +++++++++++++++++++++++\n")
    projects = Gitlab.projects
    thisproject = nil
    projects.each{|p|
      puts(p.to_hash)
      puts("name")
      puts(p.name)
      if (p.ssh_url_to_repo == ssh_url) then
        thisproject = p 
      end
    }
    if (thisproject == nil) then
      puts("We need to create a project")
      thisproject = Gitlab.create_project prj_identifier
      puts "#{prj_identifier} created on #{thisproject.ssh_url_to_repo}"
    else
      puts("The project already exists "+thisproject.ssh_url_to_repo)
    end
    return thisproject
  end

  def create_template_repo(remoteurl)
    puts("+++++++create_template_repo++++++++")
    s = Setting.find_by_name("plugin_cosmosys_git")
    if (s != nil) then
      if (s.value != nil) then
        puts("The setting exists")
        reponame = s.value["repo_template_id"]
        if (reponame != nil) then
          ret,ignoreurl = get_expected_repo_path(reponame)
          if  ret != nil then
            if not(File.directory?(ret)) then
              # Create it
              FileUtils.mkdir_p ret
              comando = "cp -r plugins/cosmosys_git/assets/template/* #{ret}"
              puts("\n\n #{comando}")
              `#{comando}`
              ## TODO: THIS IMPLIES GITLAB INCLUDED
              gitlabconfig = YAML.load(File.read("/home/redmine/gitlabapicfg.yaml"))
              puts("yaml leído")
              puts(gitlabconfig)
              gitlabproject = check_create_gitlab_prj(gitlabconfig,reponame,remoteurl)
              comando = "cd #{ret}; git init; git remote add origin #{remoteurl}"
              puts("\n\n #{comando}")
              `#{comando}`               
              comando = "cd #{ret}; git add .;git commit -m \"Initial commit\";git push --all"
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
    puts("+++++++get_expected_repo_path++++++++")    
    s = Setting.find_by_name("plugin_cosmosys_git")
    if (s != nil) then
      if (s.value != nil) then
        puts("The setting exists")
        ret = s.value["repo_local_path"].gsub("%project_id%",prj_identifier)
        ret2 = s.value["repo_server_path"].gsub("%project_id%",prj_identifier)
        return ret,ret2
      end
    else
      puts("The setting does not exist")
    end
    return nil,nil
  end

  def download_create_template_repo(repo_folder)
    puts("+++++++download_create_template_repo++++++++")            
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
            comando = "git clone #{remoteurl} #{repo_folder}"
            puts("\n\n #{comando}")
            output = `#{comando}`
          end
          comando = "cd #{repo_folder}; rm -rf .git; git init; git add .; git commit -m \"Initial commit from template\";"
          puts("\n\n #{comando}")
          output = `#{comando}`
        end
      end
    else
      puts("The setting does not exist")
    end
    return ret
  end

  def update_create_repo_folder
    puts("+++++++update_create_repo_folder++++++++")                
    # Chec if repo folder exists
    repo_folder,remote_url = get_expected_repo_path(@project.identifier)
    if  repo_folder != nil then
      if not(File.directory?(repo_folder)) then
        # The folder does not exist, we need to pull it from the template repo
        template_name = download_create_template_repo(repo_folder)
        if template_name then
          if (File.directory?(repo_folder)) then
            puts("Created!!!"+repo_folder)
            comando = "cd #{repo_folder}; git remote add origin #{remote_url}; git push --all"
            puts("\n\n #{comando}")
            output = `#{comando}`            
          end
        else
          puts("Error trying to download template for "+repo_folder)
        end
      else

      end
      puts("Folder: "+repo_folder)
    else
      puts("Error, the setting does not exist")
    end
    return repo_folder,remote_url
  end

  def get_expected_rmrepo_path(prj_identifier)
    puts("+++++++get_expected_rmrepo_path++++++++")    
    s = Setting.find_by_name("plugin_cosmosys_git")
    if (s != nil) then
      if (s.value != nil) then
        puts("The setting exists")
        return s.value["repo_redmine_path"].gsub("%project_id%",prj_identifier)
      else
        puts("The setting value does not exist")
      end
    else
      puts("The setting does not exist")
    end
    return nil
  end

  def update_create_repo_rm_mirror(remote_url)
    puts("+++++++update_create_repo_rm_mirror++++++++")

    ret = get_expected_rmrepo_path(@project.identifier)
    if ret != nil then
      path_folder = File.expand_path("..", ret)
      if not(File.directory?(path_folder)) then
        # Create it
        FileUtils.mkdir_p path_folder
      end
      if not(File.directory?(ret)) then
        # Create it
        comando = "cd #{path_folder}; git clone --mirror #{remote_url}"
        puts("\n\n #{comando}")
        `#{comando}`
      else
        # Fetch it
        comando = "cd #{ret}; git fetch --all"
        puts("\n\n #{comando}")
        `#{comando}`        
      end
      rs = @project.repositories
      foundrepo = false
      rs.each {|r|
        if foundrepo == false then
          if (r.identifier = "csys") then
            foundrepo = true
            if (r.url != ret) then
              r.url = ret
              r.save
            end
          end
        end
      }
      if foundrepo == false then
        r = Repository::Git.new
        r.project = @project
        r.identifier = "csys"
        r.report_last_commit = true
        r.url = ret
        r.is_default = true
        r.path_encoding = "UTF-8"
        r.save
      end
    end

    return ret
  end



  def import_project_repo
  end

  def report_repo
  end

  require 'rspreadsheet'

  # Definitions of the cells in the "Dict" sheet of the export file
  @@rmserverurlcell = [1,2] #B1
  @@rmkeycell = [2,2] #B2
  @@rmprojectidcell = [3,2] #B3
  @@dictlistfirstrow = 2
  @@teamcolumn = 5 #E
  @@versionscolumn = 6 #F
  @@trackerscolumn = 7 #G
  @@statusescolumn = 8 #H
  @@prioritiescolumn = 9 #I
  
  # Definitions of the cells in the "Items" sheet of the export file
  @@issuesfirstrow = 2

  # Definitions of the cells in the "ExtraFields" sheet of the export file
  @@issuesextrafirstrow = 2
  @@extraheadersrow = 1

  def export_project_repo(repo_folder)
    s = Setting.find_by_name("plugin_cosmosys_git")
    if (s != nil) then
      if (s.value != nil) then
        s3 = s.value["export_path"]
        if (s3 != nil) then
          s3 = File.join(repo_folder, s3)
          s4 = s.value["export_template_path"]
          if (s4 != nil) then
            s4 = File.join(repo_folder, s4)
            # We update the repository before executin the export
            comando = "cd #{repo_folder}; git pull origin master"
            puts("\n\n #{comando}")
            `#{comando}`

            if (File.file?(s4)) then
              # We copy the template over the last export file
              comando = "cp #{s4} #{s3}"
              puts("\n\n #{comando}")              
              `#{comando}`
              if (File.file?(s3)) then
                book = Rspreadsheet.open(s3)
                if (book != nil) then
                  dictsheet = book.worksheets('Dict')
                  if (dictsheet != nil) then
                    issuessheet = book.worksheets('Items')
                    if (issuessheet != nil) then
                      # Data in the DictSheet
                      dictsheet.cell(@@rmserverurlcell[0],@@rmserverurlcell[1]).value = "http://localhost:3001"
                      dictsheet.cell(@@rmkeycell[0],@@rmkeycell[1]).value = "my API Key?"
                      dictsheet.cell(@@rmprojectidcell[0],@@rmprojectidcell[1]).value = @project.identifier
                      currentrow = @@dictlistfirstrow
                      Tracker.all.each{|t|
                        dictsheet.cell(currentrow,@@trackerscolumn).value = t.name
                        currentrow += 1
                      }
                      currentrow = @@dictlistfirstrow
                      IssueStatus.all.each{|s|
                        dictsheet.cell(currentrow,@@statusescolumn).value = s.name
                        currentrow += 1
                      }
                      currentrow = @@dictlistfirstrow
                      IssuePriority.all.each{|s|
                        dictsheet.cell(currentrow,@@prioritiescolumn).value = s.name
                        currentrow += 1
                      }                      
                      currentrow = @@dictlistfirstrow
                      @project.members.each {|m|
                        dictsheet.cell(currentrow,@@teamcolumn).value = m.user.login
                        currentrow += 1
                      }
                      currentrow = @@dictlistfirstrow
                      @project.versions.each {|v|
                        dictsheet.cell(currentrow,@@versionscolumn).value = v.name
                        currentrow += 1
                      }

                      trackercolumn = nil
                      subjectcolumn = nil
                      itemstatuscolumn = nil
                      rmidcolumn = nil
                      localidcolumn = nil
                      itemparentcolumn = nil
                      descriptioncolumn = nil
                      assigneecolumn = nil
                      hourscolumn = nil
                      precedencescolumn = nil
                      blockingcolumn = nil

                      index = 1
                      issuessheet.row(1).cells.each{|i|
                        if trackercolumn == nil and i.value == "tracker" then
                          trackercolumn = index
                        else
                          if subjectcolumn == nil and i.value == "subject" then
                            subjectcolumn = index
                          else
                            if itemstatuscolumn == nil and i.value == "status" then
                              itemstatuscolumn = index
                            else
                              if rmidcolumn == nil and i.value == "RM#" then
                                rmidcolumn = index
                              else
                                if localidcolumn == nil and i.value == "ID" then
                                  localidcolumn = index
                                else
                                  if itemparentcolumn == nil and i.value == "parent" then
                                    itemparentcolumn = index
                                  else
                                    if descriptioncolumn == nil and i.value == "description" then
                                      descriptioncolumn = index
                                    else
                                      if assigneecolumn == nil and i.value == "assignee" then
                                        assigneecolumn = index
                                      else
                                        if hourscolumn == nil and i.value == "estimated_hours" then
                                          hourscolumn = index
                                        else
                                          if precedencescolumn == nil and i.value == "precedent_issues" then
                                            precedencescolumn = index
                                          else
                                            if blockingcolumn == nil and i.value == "blocking_issues" then
                                              blockingcolumn = index
                                            else
                                              
                                            end     
                                          end                                                  
                                        end                                                
                                      end                                                                     end                                         
                                  end          
                                end                                        
                              end                              
                            end
                          end
                        end
                        index += 1
                      }

                      # Data in the IssuesSheet
                      currentrow = @@issuesfirstrow
                      @project.issues.each{|i|
                        issuessheet.cell(currentrow,rmidcolumn).value = i.id
                        issuessheet.cell(currentrow,localidcolumn).value = i.identifier
                        issuessheet.cell(currentrow,trackercolumn).value = i.tracker.name
                        issuessheet.cell(currentrow,subjectcolumn).value = i.subject
                        issuessheet.cell(currentrow,itemstatuscolumn).value = i.status.name
                        if (i.assigned_to) then
                          issuessheet.cell(currentrow,assigneecolumn).value = i.assigned_to.login
                        end
                        if (i.description) then
                          issuessheet.cell(currentrow,descriptioncolumn).value = i.description
                        end
                        if (i.parent) then
                          #issuessheet.cell(currentrow,itemparentcolumn).value = "#"+i.parent.id.to_s
                          issuessheet.cell(currentrow,itemparentcolumn).value = i.parent.identifier
                        end
                        if (i.estimated_hours) then
                          puts(i.subject+": "+i.estimated_hours.to_s+"h")
                          issuessheet.cell(currentrow,hourscolumn).value = i.estimated_hours
                        end

                        #Now we enumerate the relations where the issue is the destination
                        rlsstr = nil
                        blkstr = nil
                        rls = i.relations_to
                        rls.each{|rl|
                          if (rl.relation_type == "precedes") then
                            if rlsstr != nil then
                              rlsstr += ","
                            else
                              rlsstr = ""
                            end
                            #rlsstr += "#"+rl.issue_from_id.to_s
                            rlsstr += rl.issue_from.identifier
                          end
                          if (rl.relation_type == "blocks") then
                            if blkstr != nil then
                              blkstr += ","
                            else
                              blkstr = ""
                            end
                            #blkstr += "#"+rl.issue_from_id.to_s
                            blkstr += rl.issue_from.identifier
                          end
                        }
                        if rlsstr != nil then
                          issuessheet.cell(currentrow,precedencescolumn).value = rlsstr
                        end
                        if blkstr != nil then
                          issuessheet.cell(currentrow,blockingcolumn).value = blkstr
                        end                        
                        currentrow += 1
                      }

                      extrasheet = book.worksheets('ExtraFields')
                      puts("+++++++EXTRA FIELDS++++++++++")
                      if extrasheet != nil then
                        columnindex = 1
                        lastusedcolumn = 1
                        dictcf = {}
                        extrasheet.row(@@extraheadersrow).cells.each {|cf|
                          if (cf.value != nil) then
                            if (cf.value != "subject" and cf.value != "ID") then
                              dictcf[cf.value] = columnindex
                              lastusedcolumn = columnindex
                            end
                          end
                          columnindex += 1
                        }
                        columnindex = lastusedcolumn + 1
                        IssueCustomField.all.each{|cf|
                          if (cf.name != "csWload" and cf.name != "csID") then
                            if not dictcf.key?(cf.name) then
                              dictcf[cf.name] = columnindex
                              extrasheet.row(@@extraheadersrow).cell(columnindex).value = cf.name
                              columnindex += 1
                            end
                          end
                        }
                        puts dictcf
                        currentrow = @@issuesextrafirstrow
                        if dictcf.key?('last_notes') then
                          add_last_notes = true
                          lastnotescolumn = dictcf['last_notes']

                        else
                          add_last_notes = false
                        end
                        @project.issues.each{|i|
                          if (add_last_notes and (i.last_notes != nil)) then
                            extrasheet.cell(currentrow,lastnotescolumn).value = i.last_notes
                          end
                          i.custom_values.each{|cv|
                            columnindex = dictcf[cv.custom_field.name]
                            if columnindex != nil then
                              prevvalue = extrasheet.cell(currentrow,columnindex).value
                              if (cv.custom_field.field_format == "float") then
                                extrasheet.cell(currentrow,columnindex).value = cv.value.to_f
                              else
                                if (cv.custom_field.field_format == "user") then
                                  if (cv.value != nil) then
                                    userid = cv.value.to_i
                                    if (userid > 0) then
                                      u = User.find(cv.value.to_i)
                                      if (prevvalue == nil) then
                                        extrasheet.cell(currentrow,columnindex).value = u.login
                                      else
                                        extrasheet.cell(currentrow,columnindex).value = prevvalue + "," + u.login
                                      end
                                    end
                                  end
                                else
                                  extrasheet.cell(currentrow,columnindex).value = cv.value
                                end
                              end
                            end
                          }
                          currentrow += 1
                        }
                      end

                      ret = book.save
                      if ret == false then
                        retstr = "Could not save export file: "+s3
                      else
                        return true
                      end
                    else
                      retstr = "Could not access the 'Items' sheet of the export file: "+s3
                    end
                  else
                    retstr = "Could not access the 'Dict' sheet of the export file: "+s3
                  end
                else
                  retstr = "Could not open the book of the export file: "+s3
                end
              else
                retstr = "The export file could not be created: "+s3
              end
            else
              retstr = "The template file does not exist: "+s4
            end
          else
            retstr = "The setting for the template file does not exist: export_template_path"
          end
        else
          retstr = "The setting for the exporting path does not exist: export_path"
        end
      else
        retstr = "The setting value for the cosmosysGit plugin does not exist: plugin_cosmosys_git.value"
      end
    else
      retstr = "The setting entry for the cosmosysGit plugin does not exist: plugin_cosmosys_git"
    end
    return false,retstr
  end
end
  
