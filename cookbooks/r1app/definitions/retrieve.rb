define :retrieve_app, :conf => nil, :user => nil, :group => nil do
  
  app_archive = "/tmp/app-archive.tar.gz"
  app_dir = params[:name]
  conf = params[:conf]
  raise ArgumentError, 'app_dir must be specified' if app_dir.nil? or 
    app_dir.empty?
  raise ArgumentError, 'conf must be specified' if conf.nil?
  raise ArgumentError, 'user must be specified' if params[:user].nil?
  raise ArgumentError, 'group must be specified' if params[:group].nil?

  raise ArgumentError, 'retrieve method must be specified' if 
    not conf.include?(:retrieve_method)

  case conf[:retrieve_method]
  when "archive"
    if not conf[:archive_url] =~ /(.*)\.tar\.gz$/
      raise ArgumentError, 'archive_url is not tar.gz file'
    end
    remote_file app_archive do
      source conf[:archive_url]
      owner params[:user]
      group params[:group]
    end
    directory "/tmp/expand_tmp" do
      owner "root"
      group "root"
      mode "0755"
      action :create
    end
    execute "untar app" do
      cwd "/tmp/expand_tmp"
      command "tar xzf #{app_archive}"
    end
    execute "move app" do
      command "mv /tmp/expand_tmp/* #{app_dir}"
    end
    execute "archive the tarball" do
      command "mv #{app_archive} /tmp/previous__app-archive.tar.gz"
    end

  when "git"
    execute "clone the repository" do
      command "git clone #{conf[:git_repo]} #{app_dir}/"
    end
    execute "fetch all code" do
      cwd app_dir
      command "git fetch"
    end
    execute "checkout the desired branch" do
      cwd app_dir
      command "git checkout -b activebranch origin/#{conf[:git_branch]}"
    end
    # This makes HEAD meaningful: 
    execute "move branch to latest" do
      cwd app_dir
      command "git pull"
    end
    execute "move branch to commit or reference" do
      cwd app_dir
      command "git reset --hard #{conf[:git_commit]}"
    end
  else raise ArgumentError, "unknown retrieve_method #{conf[:retrieve_method]}, should be 'archive' or 'git'"
  end
  
  execute "give-app-user-ownership" do
    command "chown -R #{params[:user]}:#{params[:group]} #{app_dir}"
  end

end
