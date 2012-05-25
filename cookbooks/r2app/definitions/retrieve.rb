define :retrieve_app, :conf => nil, :user => nil, :group => nil do

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
    app_archive = "/tmp/app-archive.tar.gz"
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
    execute "give-app-user-ownership" do
      command "chown -R #{params[:user]}:#{params[:group]} #{app_dir}"
    end

  when "git"
    git app_dir do
      repository conf[:git_repo]
      reference conf[:git_branch]
      action :sync
      user params[:user]
      group params[:group]
    end
  else
    raise ArgumentError, "unknown retrieve_method #{conf[:retrieve_method]}, should be 'archive' or 'git'"
  end
end
