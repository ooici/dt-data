define :install_app, :conf => nil, :user => nil, :group => nil do 
  
  app_dir = params[:name]
  
  # need to dereference params passed to nested definitions because of chef 
  # bug described above
  username = params[:user]
  groupname = params[:group]
  
  conf = params[:conf]
  raise ArgumentError, 'app_dir must be specified' if app_dir.nil? or 
    app_dir.empty?
  raise ArgumentError, 'conf must be specified' if conf.nil?
  raise ArgumentError, 'user must be specified' if username.nil?
  raise ArgumentError, 'group must be specified' if groupname.nil?

  case conf[:install_method]
  when "py_venv_setup"
    execute "run install" do
      cwd app_dir
      user username
      group groupname
      command "python setup.py install"
    end
  
  when "py_venv_buildout"
    bash "run install" do
      cwd app_dir
      user username
      group groupname
      code <<-EOH
      set -e
      python ./bootstrap.py
      if [ -f autolaunch.cfg ]; then
        bin/buildout -c autolaunch.cfg
      else
        bin/buildout
      fi
      EOH
    end
  when "javapy_venv_buildout_ant"
    bash "run install" do
      cwd app_dir
      user username
      group groupname
      code <<-EOH
      set -e
      python ./bootstrap.py
      if [ -f autolaunch.cfg ]; then
        bin/buildout -c autolaunch.cfg
      else
        bin/buildout
      fi
      ant #{conf[:ant_target]}
      EOH
    end
  else raise ArgumentError, "unknown install_method #{conf[:install_method]}"
  end
end
