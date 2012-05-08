define :git_retrieve_app, :conf => nil, :user => nil, :group => nil do

  app_dir = params[:name]
  conf = params[:conf]
  raise ArgumentError, 'app_dir must be specified' if app_dir.nil? or
    app_dir.empty?
  raise ArgumentError, 'conf must be specified' if conf.nil?
  raise ArgumentError, 'user must be specified' if params[:user].nil?
  raise ArgumentError, 'group must be specified' if params[:group].nil?

  execute "clone the repository" do
    command "git clone #{conf[:git_repo]} #{app_dir}/"
    creates "#{app_dir}/.git"
  end
  execute "fetch all code" do
    cwd app_dir
    command "git fetch"
  end
  execute "checkout the desired branch" do
    cwd app_dir
    command "git checkout -b activebranch origin/#{conf[:git_branch]}"
    returns [0, 128]
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
  # This does nothing when a repo has no submodules
  execute "pull in submodules" do
    cwd app_dir
    command "git submodule update --init"
  end

  execute "give-app-user-ownership" do
    command "chown -R #{params[:user]}:#{params[:group]} #{app_dir}"
  end

end

