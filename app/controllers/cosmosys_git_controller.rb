class CosmosysGitController < ApplicationController
  before_action :find_this_project
  before_action :authorize, :except  => [:find_project,:menu,:import,:export]

  @@tmpdir = './tmp/cosmosys_req_plugin/'

  def menu
    if request.get? then
      # print("menu GET!!!!!")
    else
      # print("menu POST!!!!!")
    end
  end

  def show
    if request.get? then
      # print("show GET!!!!!")
    else
      # print("show POST!!!!!")
    end
  end

  def import
    @import = (params[:import] || session[:import] || nil)
    if @import == nil then
      @import = {}
      @import['from_documents'] = false
    end
    if request.get? then
      # print("import GET!!!!!")
    else
      # print("import POST!!!!!")
      ret = nil
      returnmessage = ""
      puts("Ejecuto la preparacion de gitlab")
      check_prepare_gitlab
      repo_folder,remoteurl = update_create_repo_folder(@project)
      if repo_folder != nil then
        rm_mirror_folder = update_create_repo_rm_mirror(remoteurl,@project)
        if rm_mirror_folder != nil then
          retvalue,retstr = import_project_repo(repo_folder,remoteurl,@import,@project)
          if (retvalue) then
            returnmessage += "Everything went OK"
            ret = true
            @project.csys.update_cschapters
          else
            if retstr != nil and retstr.size <= 0 then
              retstr = "Import failed, Unknown reason, ask cosmobots? and submit traces"
            end
            returnmessage += retstr
          end
        else
          ret = false
          returnmessage += "Problems creating the mirror Redmine repo"
        end
      else
        returnmessage += "Could not create/update the repo folder"
      end
      if (ret != nil and ret == true) then
        flash.now[:notice] = returnmessage
      else
        flash.now[:error] = returnmessage
      end
      session[:import] = @import
    end

  end

  def export
    @export = (params[:export] || session[:export] || nil)
    if @export == nil then
      @export = {}
      @export['include_subprojects'] = false
      @export['include_fields'] = false
      @export['include_cfields'] = false
      @export['import_template'] = false
    end
    puts @export
    if request.get? then
      # puts("export GET!!!!!")
    else
      # puts("export POST!!!!!")
      puts params[:export]
      puts session[:export]
      ret = nil
      returnmessage = ""
      puts("Ejecuto la preparacion de gitlab")
      check_prepare_gitlab
      repo_folder,remoteurl = update_create_repo_folder(@project)
      if repo_folder != nil then
        retvalue,retstr = export_project_repo(repo_folder,@export,@project)
        if (retvalue) then
          ret = commit_push_export_repo(repo_folder,@export['include_subprojects'],@export['import_template'])
          if (ret) then
            rm_mirror_folder = update_create_repo_rm_mirror(remoteurl,@project)
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
      else
        returnmessage += "Could not create/update the repo folder"
      end
      if (ret != nil and ret == true) then
        flash.now[:notice] = returnmessage
      else
        flash.now[:error] = returnmessage
      end
      session[:export] = @export
    end
  end

  def report
    @report = (params[:report] || session[:report] || nil)
    if @report == nil then
      @report = {}
      @report['include_subprojects'] = false
      @report['include_fields'] = false
      @report['include_cfields'] = false
      @report['import_template'] = false
    end
    puts @report
    if request.get? then
      # puts("report GET!!!!!")
    else
      # puts("report POST!!!!!")
      puts params[:report]
      puts session[:report]
      ret = nil
      returnmessage = ""
      puts("Ejecuto la preparacion de gitlab")
      check_prepare_gitlab
      repo_folder,remoteurl = update_create_repo_folder(@project)
      if repo_folder != nil then
        retvalue,retstr = report_project_repo(repo_folder,@report,@project)
        if (retvalue) then
          ret = commit_push_report_repo(repo_folder,@report['include_subprojects'],@report['import_template'])
          if (ret) then
            rm_mirror_folder = update_create_repo_rm_mirror(remoteurl,@project)
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
      else
        returnmessage += "Could not create/update the repo folder"
      end
      if (ret != nil and ret == true) then
        flash.now[:notice] = returnmessage
      else
        flash.now[:error] = returnmessage
      end
      session[:report] = @report
    end
  end

  def report_project_repo(repo_folder,report_preferences,thisproject)
    @output = []
    ret = false
    s3,retstr,s = thisproject.csys_git.get_reporting_path
    if (s3 != nil) then
      reportingpath = s3
      s3 = File.join(repo_folder, s3)
      s4 = s.value["reporting_template_path"]
      if (s4 != nil) then
        templatepath = s4
        s4 = File.join(repo_folder, s4)
        puts("report_project_repo s4 =",s4,"s3 =",s3)
        previous_steps_done = true
        if report_preferences['import_template'] then
          previous_steps_done = false
          d,a,s5,retstr = CosmosysDocument.find_uploadable_template_report(thisproject)
          if s5 != nil then
            s9 = File.join(s4,a.filename)
            # We copy the template over the last report file
            comando = "cp #{s5} #{s9}"
            output = `#{comando}`
            puts(output)
            if (File.file?(s9)) then
              puts(s5," copied successfully to ",s9)
              previous_steps_done = true
              d.csys.imported_on = Time.now
              d.csys.save
            else
              retstr = "We could not load the new report template"
            end
          end
        end
        if (previous_steps_done) then
          if (File.directory?(s4)) then
            if (File.directory?(s3)) then
              prot,host_with_port = obtain_project_url
              s6 = s.value["reporting_img_path"]
              if (s6 != nil) then
                imgpath = s6
                s6 = File.join(repo_folder, s6)
                if (File.directory?(s6)) then
                  root_url = prot+"://"+host_with_port
                  # We obtain the JSON tree
                  if not (File.directory?(@@tmpdir)) then
                    require 'fileutils'
                    FileUtils.mkdir_p @@tmpdir
                  end
                  tmpfile = Tempfile.new('rqdownload',@@tmpdir)
                  begin
                    treedata = @project.csys.show_as_json(nil,root_url,false)
                    tmpfile.write(treedata.to_json)
                    tmpfile.close
                    comando = "python3 plugins/cosmosys_git/assets/pythons/RqReports.py #{@project.id} #{repo_folder} #{reportingpath} #{templatepath} #{imgpath} #{root_url} #{tmpfile.path}"
                    require 'open3'
                    print(comando)
                    stdin, stdout, stderr = Open3.popen3("#{comando}")
                    stdin.close
                    stdout.each do |ele|
                      if ele != nil then
                        print ("->"+ele+"\n")
                        @output << ele
                      end
                    end
                    puts("acabo el comando")
                    ret = true
                  ensure
                    #tmpfile.unlink   # deletes the temp file
                  end
                else
                  retstr = "The reporting image path does not exist: "+s6
                end
              else
                retstr = "The setting for the reporting img path does not exist: reporting_img_path"
              end
            else
              retstr = "The reporting directory does not exist"
            end
          else
            retstr = "The template directory does not exist: "+s4
          end
        end
      else
        retstr = "The setting for the template file does not exist: reporting_template_path"
      end
    else
      retstr = "The setting for the reporting path does not exist: reporting_path"
    end
    puts("ret:",ret)
    puts("retstr:",retstr)
    return ret,retstr
  end

  private

  require 'fileutils'
  require 'yaml'
  require 'gitlab'
  require 'rspreadsheet'

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

  def commit_push_import_doc_repo(repo_folder)
    puts("++++commit_push_import_doc_repo++++")
    commit_str = "[csys bot] Import file added"
    comando = "cd #{repo_folder}; git add .;git commit -m \""+commit_str+"\";git push --all"
    puts("\n\n #{comando}")
    `#{comando}`
    return true
  end

  def commit_push_export_repo(repo_folder,including_subprojects = false, import_template = false)
    commit_str = "[csys bot] "
    if import_template
      commit_str += "Export_template +"
    end
    commit_str +=" Export executed"
    if including_subprojects
      commit_str += "+ including subprojects"
    end

    comando = "cd #{repo_folder}; git add .;git commit -m \""+commit_str+"\";git push --all"
    puts("\n\n #{comando}")
    `#{comando}`
    return true
  end

  def commit_push_report_repo(repo_folder,including_subprojects = false, import_template = false)
    commit_str = "[csys bot] "
    if import_template
      commit_str += "Report_template +"
    end
    commit_str +=" Report executed"
    if including_subprojects
      commit_str += "+ including subprojects"
    end

    comando = "cd #{repo_folder}; git add .;git commit -m \""+commit_str+"\";git push --all"
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
          ret,ignoreurl = CosmosysProjectGit.get_expected_repo_path(reponame)
          if  ret != nil then
            if not(File.directory?(ret)) then
              # Create it
              FileUtils.mkdir_p ret
              comando = "cp -r plugins/cosmosys_git/assets/template/* #{ret}"
              puts("\n\n #{comando}")
              `#{comando}`
              ## TODO: THIS IMPLIES GITLAB INCLUDED
              gitlabCfgPath = "/home/redmine/gitlabapicfg.yaml"
              gitlabconfig = YAML.load(File.read(gitlabCfgPath))
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
              puts("Deleting the template folder once the git repo has been created")
              FileUtils.rm_rf(ret)

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
          puts("The path_folder to create is "+path_folder)
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

  def update_create_repo_folder(thisproject)
    puts("+++++++update_create_repo_folder++++++++")
    # Chec if repo folder exists
    repo_folder,remote_url,s = CosmosysProjectGit.get_expected_repo_path(thisproject.identifier)
    puts("The repofolder is "+repo_folder)
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
        # We update the repository before executing the export
        comando = "cd #{repo_folder}; git pull origin master"
        puts("\n\n #{comando}")
        `#{comando}`
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

  def update_create_repo_rm_mirror(remote_url,thisproject)
    puts("+++++++update_create_repo_rm_mirror++++++++")

    ret = get_expected_rmrepo_path(thisproject.identifier)
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
      rs = thisproject.repositories
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
        r.project = thisproject
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

  def report_repo
  end

  # Definitions of the cells in the "Dict" sheet of the export file
  @@rmserverurlcell = [2,2] #B2
  @@rmkeycell = [3,2] #B3
  @@rmprojectidcell = [4,2] #B4
  @@projectcodecell = [5,2] #B5
  @@teamcolumn = 5 #E
  @@versionscolumn = 6 #F
  @@trackerscolumn = 7 #G
  @@statusescolumn = 8 #H
  @@prioritiescolumn = 9 #I
  @@categoriescolumn = 10 #J
  @@dictlistfirstrow = 2
  @@dictlastrow = [1,27] #AA1
  @@issueslastrow = [1,29] #AC1

  # Definitions of the cells in the "Items" sheet of the export file
  @@issuesfirstrow = 2
  @@issuesheadersrow = 1

  require 'time'

  def import_project_repo(repo_folder,remoteurl,import_preferences,thisproject)
    import_file_consumed = false
    retvalue = false
    s3,retstr,s = thisproject.csys_git.get_import_path
    if (s3 != nil) then
      relative_import_path = s3
      s3 = File.join(repo_folder, s3)
      previous_steps_done = true
      if import_preferences['from_documents']  then
        previous_steps_done = false
        d,a,s4,retstr = CosmosysDocument.find_uploadable_import_doc(thisproject)
        if s4 != nil then
          # We copy the template over the last import file
          comando = "cp #{s4} #{s3}"
          puts("\n\n #{comando}")
          `#{comando}`
          if (File.file?(s3)) then
            puts(s4," copied successfully to ",s3)
            ret = commit_push_import_doc_repo(repo_folder)
            if (ret) then
              rm_mirror_folder = update_create_repo_rm_mirror(remoteurl,thisproject)
              if rm_mirror_folder != nil then
                previous_steps_done = true
                d.csys.imported_on = Time.now
                d.csys.save
              else
                ret = false
                retstr = "Problems creating the mirror Redmine repo"
              end
            else
              retstr = "Problems commiting/pushing the Git repo"
            end
          else
            retstr = "We could not load the document to import"
          end
        end
      end
      if (previous_steps_done) then
        if (File.file?(s3)) then
          book = Rspreadsheet.open(s3)
          if (book != nil) then
            uploadable_revision = true
            thiscommit = nil
            thisrepo = thisproject.repositories.find_by_identifier("csys")
            if (thisrepo != nil) then
              thisrepo.fetch_changesets
              thisbranchname = thisrepo.default_branch
              if (thisbranchname != nil) then
                thischangesets = thisrepo.latest_changesets(relative_import_path,thisbranchname)
                if thischangesets != nil and thischangesets.size > 0 then
                  thiscommit = thischangesets.first
                  lastimporteddate = thisproject.csys_git.last_import
                  if lastimporteddate != nil then
                    if (lastimporteddate >= thiscommit.committed_on) then
                      uploadable_revision = false
                    end
                  end
                else
                  uploadable_revision = false
                  retstr = "There are no import files at the specified place"
                end
              else
                uploadable_revision = false
                retstr = "There is no default branch in the csys repository"
              end
            end
            if (uploadable_revision) then
                          dictsheet = book.worksheets('Dict')
              if (dictsheet != nil) then
                issuessheet = book.worksheets('Items')
                if (issuessheet != nil) then
                  extrasheet = book.worksheets('ExtraFields')
                  # puts("+++++++EXTRA FIELDS++++++++++")
                  if extrasheet != nil then
                    # DICT SHEET ###################
                    if (dictsheet.cell(@@rmprojectidcell[0],@@rmprojectidcell[1]).value != thisproject.identifier) then
                      retstr = "Project identifer mismatch, " + dictsheet.cell(@@rmprojectidcell[0],@@rmprojectidcell[1]).value +
                        " != "+thisproject.identifier
                    else
                      if (dictsheet.cell(@@projectcodecell[0],@@projectcodecell[1]).value != thisproject.code) then
                        retstr = "Project code mismatch, " + dictsheet.cell(@@projectcodecell[0],@@projectcodecell[1]).value +
                          " != "+thisproject.code
                      else
                        retstr = ""
                        lastrow = dictsheet.cell(@@dictlastrow[0],@@dictlastrow[1]).value
                        if lastrow != nil and lastrow != "" then
                          puts("lastrow 2",lastrow)
                          currentrow = @@dictlistfirstrow
                          errorfound = false
                          while (currentrow <= lastrow) do
                            thisitem = dictsheet.cell(currentrow,@@trackerscolumn)
                            if thisitem != nil and thisitem.value != nil then
                              element = thisproject.trackers.find_by_name(thisitem.value)
                              if element == nil then
                                retstr += "The tracker "+thisitem.value+" is not present in the current project, adding it?"
                                element = Tracker.find_by_name(thisitem.value)
                                if element == nil then
                                  retstr += "The tracker "+thisitem.value+" does not exist"
                                  errorfound = true
                                else
                                  thisproject.trackers << element
                                  thisproject.save
                                end
                             end

                            end
                            currentrow += 1
                            #puts("tracker row",currentrow)
                          end

                          if not errorfound then
                            currentrow = @@dictlistfirstrow
                            while (currentrow <= lastrow) do
                              thisitem = dictsheet.cell(currentrow,@@statusescolumn)
                              if thisitem != nil and thisitem.value != nil then
                                element = IssueStatus.find_by_name(thisitem.value)
                                if element == nil then
                                  retstr += "The status "+thisitem.value+" does not exist"
                                  errorfound = true
                                end
                              end
                              currentrow += 1
                            end
                          end

                          if not errorfound then
                            currentrow = @@dictlistfirstrow
                            while (currentrow <= lastrow) do
                              thisitem = dictsheet.cell(currentrow,@@prioritiescolumn)
                              if thisitem != nil and thisitem.value != nil then
                                element = IssuePriority.find_by_name(thisitem.value)
                                if element == nil then
                                  retstr += "The priority "+thisitem.value+" does not exist"
                                  errorfound = true
                                end
                              end
                              currentrow += 1
                            end
                          end

                          dictmembers = {}
                          thisproject.members.each {|m|
                            dictmembers[m.user.login] = m
                          }
                          if not errorfound then
                            currentrow = @@dictlistfirstrow
                            while (currentrow <= lastrow) do
                              thisitem = dictsheet.cell(currentrow,@@teamcolumn)
                              if thisitem != nil and thisitem.value != nil then
                                element = dictmembers[thisitem.value]
                                if element == nil then
                                  retstr += "The project member "+thisitem.value+" does not exist"
                                  errorfound = true
                                end
                              end
                              currentrow += 1
                            end
                          end

                          if not errorfound then
                            currentrow = @@dictlistfirstrow
                            while (currentrow <= lastrow) do
                              thisitem = dictsheet.cell(currentrow,@@versionscolumn)
                              if thisitem != nil and thisitem.value != nil then
                                element = thisproject.versions.find_by_name(thisitem.value)
                                if element == nil then
                                  retstr += "The version "+thisitem.value+" does not exist"
                                  errorfound = true
                                end
                              end
                              currentrow += 1
                            end
                          end

                          if not errorfound then
                            currentrow = @@dictlistfirstrow
                            while (currentrow <= lastrow) do
                              thisitem = dictsheet.cell(currentrow,@@categoriescolumn)
                              if thisitem != nil and thisitem.value != nil then
                                element = thisproject.issue_categories.find_by_name(thisitem.value)
                                if element == nil then
                                  retstr += "The category "+thisitem.value+" does not exist"
                                  errorfound = true
                                end
                              end
                              currentrow += 1
                            end
                          end

                          if not errorfound then
                            # At this moment we consider the file is being consumed
                            # and (exceptions apart) any importing issue is a defect of the
                            # file, so we never have to import the same file again.
                            # At the moment we have not found any exception to this, because the
                            # consistency of the Dict tab and the Redmine project is enought
                            # to guarantee that a well constructed import file will
                            # cause a valid import process.
                            import_file_consumed = true
                            puts("consumed!!!!")

                            # We need to create two dictionaries for the fields using the two sheets: Items and Extrafield
                            sheetindexes = {}
                            sheetindexes['extra'] = extrasheet
                            sheetindexes['issues'] = issuessheet
                            sheetindexes['dict'] = dictsheet

                            # Fields of the items sheet
                            index = 1
                            issuefieldlocation = {}
                            issuessheet.row(@@issuesheadersrow).cells.each{|i|
                              if (i.value != nil) then
                                if not issuefieldlocation.key?(i.value) then
                                  location = {:sheet => 'issues', :column =>index}
                                  issuefieldlocation[i.value] = location
                                end
                              end
                              index += 1
                            }

                            # Fields of the extra fields sheet
                            index = 1
                            extrasheet.row(@@issuesheadersrow).cells.each{|i|
                              if i.value != nil then
                                if not issuefieldlocation.key?(i.value) then
                                  location = {:sheet => 'extra', :column =>index}
                                  issuefieldlocation[i.value] = location
                                end
                              end
                              index += 1
                            }

                            # puts("++++++ LOCATION +++++++++")
                            # puts(issuefieldlocation)

                            lastrow = dictsheet.cell(@@issueslastrow[0],@@issueslastrow[1]).value
                            if lastrow != nil and lastrow != "" then
                              puts("lastrow 1",lastrow)
                              currentrow = @@issuesfirstrow
                              dictitems = {}
                              if currentrow <= lastrow then
                                while currentrow <= lastrow do
                                  thisitem = nil
                                  thisrow = issuessheet.row(currentrow)
                                  if thisrow != nil then
                                    thiskey = "ID"
                                    if issuefieldlocation.key?(thiskey) then
                                      thisfield = sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                        issuefieldlocation[thiskey][:column])
                                      if thisfield != nil then
                                        thisident = thisfield.value
                                        if thisident != nil then
                                          thisitem = thisproject.csys.find_issue_by_identifier(thisident,true)
                                          if (thisitem == nil) then
                                            puts("NO LO ENCONTRAMOS!!!!")
                                            thisitem = thisproject.issues.new
                                          end
                                          dictitems[thisident] = {}
                                          dictitems[thisident]['item'] = thisitem
                                        else
                                          puts("the row " + currentrow.to_s + " does not have an ID")
                                        end
                                      end
                                    end

                                    if thisitem != nil then
                                      retvalue = true

                                      thiskey = "tracker"
                                      ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if ret != nil then
                                        thistracker = Tracker.find_by_name(ret)
                                        if (thistracker != nil) then
                                          thisitem.tracker = thistracker
                                        else
                                          puts("the tracker ",thisvalue," does not exist")
                                        end
                                      end

                                      thiskey = "subject"
                                      ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if ret != nil then
                                        if ret.instance_of?(String) then
                                          thisitem.subject = convert_imported_text(ret)
                                        else
                                          thisitem.subject = ret.to_s
                                        end
                                      end

                                      thiskey = "status"
                                      ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if ret != nil then
                                        thisstatus = IssueStatus.find_by_name(ret)
                                        if (thisstatus != nil) then
                                          thisitem.status = thisstatus
                                        else
                                          puts("the status ",ret," does not exist")
                                        end
                                      end

                                      thiskey = "assignee"
                                      ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if ret != nil then
                                        thismember = dictmembers[ret]
                                        if (thismember != nil) then
                                          thisitem.assigned_to = thismember.user
                                        else
                                          puts("the project team member ",ret," does not exist")
                                        end
                                      end

                                      thiskey = "version"
                                      ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if ret != nil then
                                        thisversion = thisproject.versions.find_by_name(ret)
                                        if (thisversion != nil) then
                                          thisitem.fixed_version = thisversion
                                        else
                                          puts("the project version ",ret," does not exist")
                                        end
                                      end

                                      thiskey = "description"
                                      retcell = extract_cell_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if retcell != nil then
                                        descr = obtain_longtext(retcell)
                                        if descr != nil then
                                          # puts("DESCRIPCION",descr)
                                          thisitem.description = convert_imported_text(descr)
                                        end
                                      end

                                      thiskey = "estimated_hours"
                                      ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if ret != nil then
                                        thisitem.estimated_hours = ret
                                      end

                                      thiskey = "start_date"
                                      ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if ret != nil then
                                        thisitem.start_date = ret
                                      end

                                      thiskey = "due_date"
                                      ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if ret != nil then
                                        thisitem.due_date = ret
                                      end

                                      IssueCustomField.all.each { |cf|
                                        thiskey = cf.name
                                        # puts("++++ PROCESANDO++++ "+thiskey)
                                        # TODO: rqRational should not be hardcoded here!!!
                                        # Please rever to the longtext type
                                        if thiskey != "rqRationale" then
                                          ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                          if ret != nil then
                                            # puts(ret)
                                            cfty = thisitem.custom_field_values.select{|a| a.custom_field_id == cf.id }.first
                                            if cfty != nil then
                                              if ret.class == String then
                                                cfty.value = convert_imported_text(ret)
                                              else
                                                cfty.value = ret
                                              end
                                            end
                                          end
                                        else
                                          retcell = extract_cell_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                          if retcell != nil then
                                            rational_str = obtain_longtext(retcell)
                                            if (rational_str != nil) then
                                              # puts("RATIONAL:",rational_str)
                                              cfty = thisitem.custom_field_values.select{|a| a.custom_field_id == cf.id }.first
                                              if cfty != nil then
                                                cfty.value = convert_imported_text(rational_str)
                                              end
                                            end
                                          end
                                        end
                                      }

                                      puts("Let's save the item")
                                      if (thisitem != nil) then
                                        if thisitem.author == nil then
                                          thisitem.author = User.current
                                        end
                                        puts(thisitem.inspect)
                                        saved = thisitem.save
                                        puts thisitem.errors.full_messages
                                        puts("item saved:" + saved.to_s)
                                        retvalue = retvalue and saved
                                      end

                                      # Now we will obtain the relationships, so in a second loop we can add the relationships
                                      thiskey = "parent"
                                      # It is important to know if the parent column exists, in order to know if we have to remove
                                      # parent relationships
                                      if issuefieldlocation[thiskey] then
                                        ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                        if ret != nil then
                                          dictitems[thisident]['parent'] = ret
                                        end
                                      end
                                      thiskey = 'precedent_items'
                                      ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if ret != nil then
                                        dictitems[thisident][thiskey] = ret
                                      end

                                      thiskey = 'blocking_items'
                                      ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if ret != nil then
                                        dictitems[thisident][thiskey] = ret
                                      end

                                      thiskey = 'related_items'
                                      ret = extract_cellvalue_from_key(thiskey,issuefieldlocation,sheetindexes,currentrow)
                                      if ret != nil then
                                        dictitems[thisident][thiskey] = ret
                                      end
                                    end
                                    thisextrarow = extrasheet.row(currentrow)
                                    if thisextrarow != nil then
                                      # TODO: Import data from the ExtraFields sheet
                                    end
                                  end
                                  currentrow += 1
                                  # puts("next row",currentrow)
                                end
                                dictitems.each{|key,node|
                                  changeditem = false
                                  thisitem = node['item']
                                  if thisitem.id != nil then
                                    thisitem.reload
                                  end
                                  # puts("EXPLORING RELATIONSHIPS OF " + key)
                                  # puts(node)
                                  # This causes a failure when importing a void item
                                  # puts(+"---> "+ thisitem.csys.get_identifier)

                                  relations_to_add = []
                                  # Parent item

                                  if issuefieldlocation["parent"] then
                                      parentid = node['parent']
                                    if (parentid != nil and parentid.size > 0) then
                                      # Maybe the parent is not in the same spreadsheet
                                      if dictitems.key?(parentid) then
                                        thisparentitem = dictitems[parentid]['item']
                                      else
                                        thisparentitem = nil
                                        # puts("the parent issue ",parentid," can not be found in the same import document, partial file load?")
                                      end
                                      if (thisparentitem == nil) then
                                        thisparentitem = thisproject.csys.find_issue_by_identifier(parentid,true)
                                        if (thisparentitem == nil) then
                                          # In case we are importing a partial file load, the parent item can be located at the parent project, let's search for it
                                          if thisproject.parent != nil then
                                            thisparentitem = thisproject.parent.csys.find_issue_by_identifier(parentid,true)
                                            dictitems[parentid]['item'] = thisparentitem
                                          else
                                            puts "WARNING: This ODS claims to be part of a subdiagram, but it is not"
                                          end
                                        end
                                      end
                                      if (thisparentitem != nil) then
                                        if thisitem.parent != thisparentitem then
                                          relations_to_add += [{:type => 'parent', :item_from => thisparentitem}]
                                        end
                                      else
                                        puts("the parent issue ",parentid," does not exist")
                                      end

                                    else
                                      # The column exists, and it is void.
                                      # If it exists, we have to remove the parent relationship
                                      thisitem.parent = nil
                                    end
                                  end

                                  # Exploramos ahora las relaciones de dependencia
                                  # Busco las relaciones existences con este requisito
                                  # Como voy a tratar las que tienen el requisito como destino, las filtro
                                  my_filtered_req_relations = thisitem.relations_to
                                  # Al cargar requisitos puede ser que haya antiguas relaciones que ya no existan.  Al finalizar la carga
                                  # deberemos eliminar los remanentes, asi que meteremos la lista de relaciones en una lista de remanentes
                                  residual_relations = []
                                  my_filtered_req_relations.each { |e|
                                    residual_relations << e
                                  }


                                  thiskey = "blocking_items"
                                  if issuefieldlocation[thiskey] then
                                    relations_to_add += get_relations_to_add(thiskey,"blocks",node,dictitems,thisproject,residual_relations)
                                  end
                                  thiskey = "precedent_items"
                                  if issuefieldlocation[thiskey] then
                                    relations_to_add += get_relations_to_add(thiskey,"precedes",node,dictitems,thisproject,residual_relations)
                                  end
                                  thiskey = "related_items"
                                  if issuefieldlocation[thiskey] then
                                    relations_to_add += get_relations_to_add(thiskey,"relates",node,dictitems,thisproject,residual_relations)
                                  end

                                  # Hay que eliminar todas las relaciones preexistentes que no hayan sido "reescritas"
                                  #print("residual_relations AFTER",residual_relations)
                                  residual_relations.each { |r|
                                      #print("Destruyo la relacion", r)
                                      removeit = false
                                      if issuefieldlocation["blocking_items"] and
                                        r.relation_type == 'blocks' then
                                        removeit = true
                                      end
                                      if not removeit and issuefieldlocation["precedent_items"] and
                                        r.relation_type == 'precedes' then
                                        removeit = true
                                      end
                                      if not removeit and issuefieldlocation["related_items"] and
                                        r.relation_type == 'relates' then
                                        removeit = true
                                      end

                                      if removeit then
                                        r.issue_from.relations_from.delete(r)
                                        r.destroy
                                      end
                                  }

                                  # Ahora que hemos eliminado las relaciones residuales, vamos a crear las nuevas
                                  # Se hace en este orden para que existan las menores colisiones
                                  relations_to_add.each {|r|
                                    if r[:type] == 'parent' then
                                      if r[:item_from].id == thisitem.id then
                                        puts("ITEM POINTING TO ITSELF AS PARENT ---> nil ")
                                      else
                                        thisitem.parent = r[:item_from]
                                      end
                                    else
                                      #print("Creo una nueva relacion")
                                      relation = r[:item_from].relations_from.new
                                      relation.issue_to = thisitem
                                      relation.relation_type = r[:type]
                                      relation.errors.clear
                                      if (relation.save) then
                                        #print(relation.to_s+" ... ok\n")
                                      else
                                        #print(relation.to_s+" ... nok\n")
                                        relation.errors.full_messages.each  do |message|
                                          print("--> " + message + "\n")
                                        end
                                      end
                                    end
                                  }

                                  thisitem.errors.clear
                                  if (thisitem.save) then
                                    print(thisitem.csys.get_identifier+" ... relations ok\n")
                                  else
                                    # print(thisitem.csys.get_identifier+" ... relations nok\n")
                                    thisitem.errors.full_messages.each  do |message|
                                      print("--> " + message + "\n")
                                    end
                                  end
                                  if changeditem then
                                    retvalue = retvalue and thisitem.save
                                  end
                                }
                              else
                                retstr = "No items imported, review the import file.  Did you Shift+Ctrl+F9 and saved it before submitting it? (1.1)"
                              end
                            else
                              retstr = "The import file is not indicating the Items sheet last row in cell Dict!AC1"
                            end
                          end
                        else
                          retstr = "The import file is not indicating the Dict sheet last row in cell Dict!AA1"
                        end
                      end
                    end
                  else
                    retstr = "Could not access the 'ExtraFields' sheet of the export file: "+s3
                  end
                else
                  retstr = "Could not access the 'Items' sheet of the export file: "+s3
                end
              else
                retstr = "Could not access the 'Dict' sheet of the export file: "+s3
              end
            else
              if retstr == nil then
                retstr = "The revision of the import file is not newer than the last revision imported.  Maybe you are trying to commit the same file again?  If this is the case and you want to force this not recommended actuation, you must commit a newer version to the repository."
              end
            end
          else
            retstr = "Could not open the book of the import file: "+s3
          end
          # If we have determined that the import file has been "consumed", then we have to store
          # this import operation date to prevent importing the same file.
          if (import_file_consumed) then
            thisproject.csys_git.last_import = thiscommit.committed_on
            thisproject.csys_git.save
          end
        else
          retstr = "The import file does not exist: "+s3
        end
      end
    else
      retstr = "The setting for the exporting path does not exist: export_path"
    end
    # puts("retorno",retvalue,retstr)
    return retvalue,retstr
  end

  def obtain_project_url
    s = Setting.find_by_name("host_name")
    p = Setting.find_by_name("protocol")
    prot = nil
    if s == nil or p == nil then
      splitted_url = request.fullpath.split('/cosmosys_reqs')
      print("\nsplitted_url: ",splitted_url)
      root_url = splitted_url[0]
      print("\nroot_url: ",root_url)
      print("\nbase_url: ",request.base_url)
      print("\nurl: ",request.url)
      print("\noriginal: ",request.original_url)
      print("\nhost: ",request.host)
      print("\nhost wp: ",request.host_with_port)
      print("\nfiltered_path: ",request.filtered_path)
      print("\nfullpath: ",request.fullpath)
      print("\npath_translated: ",request.path_translated)
      print("\noriginal_fullpath ",request.original_fullpath)
      print("\nserver_name ",request.server_name)
      print("\noriginal_fullpath ",request.original_fullpath)
      print("\npath ",request.path)
      print("\nserver_addr ",request.server_addr)
      print("\nhost ",request.host)
      print("\nremote_host ",request.remote_host)

      if s == nil then
        s = Setting.new
        s.name = "host_name"
        s.value = request.host_with_port
        s.save
      end
      if p == nil then
        p = Setting.new
        p.name = "protocol"
        prot = request.protocol
        if prot == "http://" then
          p.value =  "http"
          prot = p.value
          p.save
        else
          if prot == "https://" then
            p.value = "https"
            prot = p.value
            p.save
          else
            puts "Unknown protocol "+prot+" can not save the Redmine setting"
          end
        end
      end
    else
      prot = p.value
    end
    return p.value,s.value
  end


  def export_project_repo(repo_folder,export_preferences,thisproject)
    ret = false
    s3,retstr,s = thisproject.csys_git.get_export_path
    if (s3 != nil) then
      if (File.extname(s3) != nil) then
        s3 = File.join(repo_folder, s3)
        s4 = s.value["export_template_path"]
        if (s4 != nil) then
          s4 = File.join(repo_folder, s4)
          previous_steps_done = true
          if export_preferences['import_template'] then
            previous_steps_done = false
            d,a,s5,retstr = CosmosysDocument.find_uploadable_template_doc(thisproject)
            if s5 != nil then
              # We copy the template over the last export file
              comando = "cp #{s5} #{s4}"
              puts("\n\n #{comando}")
              output = `#{comando}`
              puts(output)
              if (File.file?(s4)) then
                puts(s4," copied successfully to ",s5)
                previous_steps_done = true
                d.csys.imported_on = Time.now
                d.csys.save
              else
                retstr = "We could not load the new export template"
              end
            end
          end
          if (previous_steps_done) then
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
                      extrasheet = book.worksheets('ExtraFields')
                      # puts("+++++++EXTRA FIELDS++++++++++")
                      if extrasheet != nil then

                        # DICT SHEET ###################
                        prot,host_with_port = obtain_project_url

                        dictsheet.cell(@@rmserverurlcell[0],@@rmserverurlcell[1]).value = prot+"://"+host_with_port
                        dictsheet.cell(@@rmkeycell[0],@@rmkeycell[1]).value = "my API Key?"
                        dictsheet.cell(@@rmprojectidcell[0],@@rmprojectidcell[1]).value = thisproject.identifier
                        dictsheet.cell(@@projectcodecell[0],@@projectcodecell[1]).value = thisproject.code
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
                        thisproject.members.each {|m|
                          dictsheet.cell(currentrow,@@teamcolumn).value = m.user.login
                          currentrow += 1
                        }
                        currentrow = @@dictlistfirstrow
                        thisproject.versions.each {|v|
                          dictsheet.cell(currentrow,@@versionscolumn).value = v.name
                          currentrow += 1
                        }
                        currentrow = @@dictlistfirstrow
                        thisproject.issue_categories.each {|c|
                          dictsheet.cell(currentrow,@@categoriescolumn).value = c.name
                          currentrow += 1
                        }

                        # We need to create two dictionaries for the fields using the two sheets: Items and Extrafield
                        sheetindexes = {}
                        sheetindexes['extra'] = extrasheet
                        sheetindexes['issues'] = issuessheet
                        sheetindexes['dict'] = dictsheet

                        # Fields of the items sheet
                        index = 1
                        issuefieldlocation = {}
                        issuessheet.row(@@issuesheadersrow).cells.each{|i|
                          if (i.value != nil) then
                            if not issuefieldlocation.key?(i.value) then
                              location = {:sheet => 'issues', :column =>index}
                              issuefieldlocation[i.value] = location
                            end
                          end
                          index += 1
                        }

                        # Fields of the extra fields sheet
                        index = 1
                        lastextrausedcolumn = nil
                        extrasheet.row(@@issuesheadersrow).cells.each{|i|
                          if i.value != nil then
                            if not issuefieldlocation.key?(i.value) then
                              location = {:sheet => 'extra', :column =>index}
                              issuefieldlocation[i.value] = location
                            end
                            lastextrausedcolumn = index
                          end
                          index += 1
                        }

                        include_precedent = issuefieldlocation.key?("precedent_items")
                        include_blocking = issuefieldlocation.key?("blocking_items")
                        include_related = issuefieldlocation.key?("related_items")

                        if export_preferences['include_fields'] then
                          thiskey = "RM#"
                          if issuefieldlocation.key?(thiskey) then
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                          end
                          thiskey = "ID"
                          if issuefieldlocation.key?(thiskey) then
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                          end
                          thiskey = "tracker"
                          if issuefieldlocation.key?(thiskey) then
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                          end
                          thiskey = "subject"
                          if issuefieldlocation.key?(thiskey) then
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                          end
                          thiskey = "status"
                          if issuefieldlocation.key?(thiskey) then
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                          end
                          thiskey = "assignee"
                          if issuefieldlocation.key?(thiskey) then
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                          end
                          thiskey = "description"
                          if issuefieldlocation.key?(thiskey) then
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                          end
                          thiskey = "parent"
                          if issuefieldlocation.key?(thiskey) then
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                          end

                          thiskey = "estimated_hours"
                          if issuefieldlocation.key?(thiskey) then
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                          end

                          thiskey = "start_date"
                          if issuefieldlocation.key?(thiskey) then
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                          end

                          thiskey = "due_date"
                          if issuefieldlocation.key?(thiskey) then
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                          end

                          if not include_precedent then
                            thiskey = "precedent_items"
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                            include_precedent = true
                          end

                          if not include_blocking then
                            thiskey = "blocking_items"
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                            include_blocking = true
                          end

                          if not include_related then
                            thiskey = "related_items"
                            location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                            issuefieldlocation[thiskey] = location
                            lastextrausedcolumn += 1
                            extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = thiskey
                            include_related = true
                          end
                        end

                        # Extra custom fields not in the template, to be appended as columns in the extrafields
                        # sheet
                        if export_preferences['include_cfields'] != nil and export_preferences['include_cfields'] then
                          IssueCustomField.all.each{|cf|
                            if not issuefieldlocation.key?(cf.name) then
                              location = {:sheet => 'extra', :column =>lastextrausedcolumn+1}
                              issuefieldlocation[cf.name] = location
                              lastextrausedcolumn += 1
                              extrasheet.row(@@issuesheadersrow).cell(lastextrausedcolumn).value = cf.name
                            end
                          }
                        end
                        #puts("++++++ LOCATION +++++++++")
                        #puts(issuefieldlocation)


                        # Normal Issue fields
                        currentrow = @@issuesfirstrow
                        thisprojectissues = thisproject.issues.sort_by {|obj| obj.csys.sortable_chapter_str}
                        thisprojectissues.each{|i|
                          # puts("Processing issues ",currentrow,i)
                          thiskey = "RM#"
                          if issuefieldlocation.key?(thiskey) then
                            sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                              issuefieldlocation[thiskey][:column]).value = i.id
                          end
                          thiskey = "ID"
                          if issuefieldlocation.key?(thiskey) then
                            sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                              issuefieldlocation[thiskey][:column]).value = i.csys.get_identifier
                          end
                          thiskey = "tracker"
                          if issuefieldlocation.key?(thiskey) then
                            sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                              issuefieldlocation[thiskey][:column]).value = i.tracker.name
                          end
                          thiskey = "subject"
                          if issuefieldlocation.key?(thiskey) then
                            sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                              issuefieldlocation[thiskey][:column]).value = i.subject
                          end
                          thiskey = "status"
                          if issuefieldlocation.key?(thiskey) then
                            sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                              issuefieldlocation[thiskey][:column]).value = i.status.name
                          end
                          if (i.assigned_to != nil) then
                            thiskey = "assignee"
                            if issuefieldlocation.key?(thiskey) then
                              sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                issuefieldlocation[thiskey][:column]).value = i.assigned_to.login
                            end
                          end
                          thiskey = "description"
                          if issuefieldlocation.key?(thiskey) then
                            sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                              issuefieldlocation[thiskey][:column]).value = i.description
                          end
                          if (i.parent != nil) then
                            thiskey = "parent"
                            if issuefieldlocation.key?(thiskey) then
                              sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                issuefieldlocation[thiskey][:column]).value = i.parent.csys.get_identifier
                            end
                          end
                          thiskey = "estimated_hours"
                          if issuefieldlocation.key?(thiskey) then
                            sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                              issuefieldlocation[thiskey][:column]).value = i.estimated_hours
                          end
                          thiskey = "start_date"
                          if issuefieldlocation.key?(thiskey) then
                            sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                              issuefieldlocation[thiskey][:column]).value = i.start_date
                          end
                          thiskey = "due_date"
                          if issuefieldlocation.key?(thiskey) then
                            sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                              issuefieldlocation[thiskey][:column]).value = i.due_date
                          end
                          thiskey = "chapter"
                          if issuefieldlocation.key?(thiskey) then
                            sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                              issuefieldlocation[thiskey][:column]).value = i.csys.chapter_str
                          end

                          #Now we enumerate the relations where the issue is the destination
                          rlsstr = nil
                          blkstr = nil
                          relstr = nil
                          rls = i.relations_to

                          rls.each{|rl|
                            if include_precedent and (rl.relation_type == "precedes") then
                              if rlsstr != nil then
                                rlsstr += ","
                              else
                                rlsstr = ""
                              end
                              rlsstr += rl.issue_from.csys.get_identifier
                            end
                            if include_blocking and (rl.relation_type == "blocks") then
                              if blkstr != nil then
                                blkstr += ","
                              else
                                blkstr = ""
                              end
                              blkstr += rl.issue_from.csys.get_identifier
                            end
                            if include_related and (rl.relation_type == "relates") then
                              if relstr != nil then
                                relstr += ","
                              else
                                relstr = ""
                              end
                              relstr += rl.issue_from.csys.get_identifier
                            end
                          }
                          if include_precedent and rlsstr != nil then
                              sheetindexes[issuefieldlocation["precedent_items"][:sheet]].cell(currentrow,
                                issuefieldlocation["precedent_items"][:column]).value = rlsstr
                          end
                          if include_blocking and blkstr != nil then
                              sheetindexes[issuefieldlocation["blocking_items"][:sheet]].cell(currentrow,
                                issuefieldlocation["blocking_items"][:column]).value = blkstr
                          end
                          if include_related and relstr != nil then
                              sheetindexes[issuefieldlocation["related_items"][:sheet]].cell(currentrow,
                                issuefieldlocation["related_items"][:column]).value = relstr
                          end
                          if (i.last_notes != nil) then
                            thiskey = "last_notes"
                            if issuefieldlocation.key?(thiskey) then
                              sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                issuefieldlocation[thiskey][:column]).value = i.last_notes
                            end
                          end
                          if (i.priority != nil) then
                            thiskey = "priority"
                            if issuefieldlocation.key?(thiskey) then
                              sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                issuefieldlocation[thiskey][:column]).value = i.priority.name
                            end
                          end
                          if (i.fixed_version != nil) then
                            thiskey = "version"
                            if issuefieldlocation.key?(thiskey) then
                              sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                issuefieldlocation[thiskey][:column]).value = i.fixed_version.name
                            end
                          end
                          if (i.category != nil) then
                            thiskey = "category"
                            if issuefieldlocation.key?(thiskey) then
                              sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                issuefieldlocation[thiskey][:column]).value = i.category.name
                            end
                          end

                          i.custom_values.each{|cv|
                            thiskey = cv.custom_field.name
                            if issuefieldlocation.key?(thiskey) then
                              prevvalue = sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                issuefieldlocation[thiskey][:column]).value
                              if (cv.custom_field.field_format == "float") then
                                sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                  issuefieldlocation[thiskey][:column]).value = cv.value.to_f
                              else
                                if (cv.custom_field.field_format == "user") then
                                  if (cv.value != nil) then
                                    userid = cv.value.to_i
                                    if (userid > 0) then
                                      u = User.find(cv.value.to_i)
                                      if (prevvalue == nil) then
                                        sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                          issuefieldlocation[thiskey][:column]).value = u.login
                                      else
                                        sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                          issuefieldlocation[thiskey][:column]).value = prevvalue + "," + u.login
                                      end
                                    end
                                  end
                                else
                                  sheetindexes[issuefieldlocation[thiskey][:sheet]].cell(currentrow,
                                    issuefieldlocation[thiskey][:column]).value = cv.value
                                end
                              end
                            end
                          }
                          currentrow += 1
                        }
                        ret = book.save
                        if ret == false then
                          retstr = "Could not save export file: "+s3
                        else
                          if export_preferences['include_subprojects'] then
                            thisproject.children.each {|cp|
                              export_project_repo(repo_folder,export_preferences,cp)
                            }
                          else
                            ret = true
                          end
                        end
                      else
                        retstr = "Could not access the 'ExtraFields' sheet of the export file: "+s3
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
          end
        else
          retstr = "The setting for the template file does not exist: export_template_path"
        end
      else
        retstr = "The export path setting has no extension "+s.value["export_path"]
      end
    else
      retstr = "The setting for the exporting path does not exist: export_path"
    end
    return ret,retstr
  end

  def convert_imported_text(input_text)
    output_text = input_text

    # First we have to convert specific OpenOffice/LibreOffice tags
    toreplace = "<text:s/>"
    if output_text.include?(toreplace) then
      output_text = output_text.gsub(toreplace," ")
    end
    toreplace = "<text:line-break/>"
    if output_text.include?(toreplace) then
      # puts ("!!!!!!!!! HACEMOS ALGO !!!!!!!!!!!!!")
      output_text = output_text.gsub(toreplace,"\n")
    end
    # We will be converting the text until the <text:s text:c=" token does not appear
    toreplace1 = '<text:s text:c="'
    toreplace2 = '"/>'
    while output_text.include?(toreplace1)
      textindex1 = output_text.index(toreplace1)
      output_text = output_text.sub(toreplace1,"")
      textindex2 = output_text.index(toreplace2)
      if textindex2 != nil then
        number_s=output_text[textindex1..textindex2-1]
        if number_s != nil then
          #puts("number_s: "+number_s)
          number = number_s.to_i
          if number != nil then
            #puts ("number: "+number.to_s)
            output_text = output_text.sub(number_s+toreplace2," " * number)
          end
        end
      end
    end
    # Now we have to convert HTML to text
    return Nokogiri::HTML(output_text).text
  end

  def obtain_longtext(cell)
    ret = ""
    first = true
    cell.xmlnode.each_element {|e|
      if (first) then
        first = false
      else
        ret += "\n"
      end
      ret += e.inner_xml.to_s
    }
    return ret
  end

  def check_prepare_gitlab
    gitlabCfgPath = "/home/redmine/gitlabapicfg.yaml"
    puts("Compruebo...")
    if not File.file?(gitlabCfgPath) then
      puts("No existe ",gitlabCfgPath ,",tengo que ejecutar el comando python")
      comando = "python3 ./plugins/cosmosys_git/assets/scripts/gitlab-preparation.py"
      puts("\n\n #{comando}")
      output = `#{comando}`
      puts("=====================")
      puts(output)
    end
  end

  def extract_cell_from_key(k,location_dict,sheet_index,row_i)
    ret = nil
    if location_dict.key?(k) then
      thisfield = sheet_index[location_dict[k][:sheet]].cell(row_i,
      location_dict[k][:column])
      if thisfield != nil then
        ret = thisfield
      else
        puts("the row " + row_i.to_s + " does not have a " + k + " field")
      end
    end
    return ret
  end

  def extract_cellvalue_from_key(k,location_dict,sheet_index,row_i)
    ret = nil
    thisfield = extract_cell_from_key(k,location_dict,sheet_index,row_i)
    if thisfield != nil then
      ret = thisfield.value
      if ret == nil then
        puts("the row " + row_i.to_s + " does not have a " + k + " value")
      end
    end
    return ret
  end

  def get_relations_to_add(k,reltype,n,items_dict,p,residual_relations)
    ret = []
    # Obtaining the relations string of the given column name (key)
    rel_str = n[k]
    if rel_str != nil then
      # Separating the related items identifiers
      rel_item_idents = n[k].split(/[\s,]/)
      rel_item_idents.each { |rel_item_ident|
        # Iterating each related item identifier
        rel_item_ident = rel_item_ident.strip()
        #print("\n  related to: '"+rel_item_ident+"'")
        # Busco ese requisito
        # Primero entre los recién cargados
        rel_item_node = items_dict[rel_item_ident]
        if (rel_item_node != nil) then
          rel_req = rel_item_node['item']
        end
        if (rel_req == nil) then
          # Si no lo hemos encontrado, entonces lo buscamos en el proyecto
          rel_req = p.csys.find_issue_by_identifier(rel_item_ident,true)
        end
        if (rel_req != nil) then
          #print(" encontrado ",rel_req.id)
          # Veo si ya existe algun tipo de relacion con el
          preexistent_relations = n['item'].relations_to.where(issue_from: rel_req)
          #print(preexistent_relations)
          already_exists = false
          if (preexistent_relations.size>0) then
            preexistent_relations.each { |rel|
              if (rel.relation_type == reltype) then
                #print("Ya existe la relacion ",rel)
                residual_relations.delete(rel)
                already_exists = true
              end
            }
          end
          if not(already_exists) then
            ret += [{:type => reltype, :item_from => rel_req}]
          end
        else
          print("Error, no existe el requisito '"+reltype+"' "+rel_item_ident)
        end
      }
    end
    return ret
  end

end
