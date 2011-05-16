define :install_app, :conf => nil, :user => nil, :group => nil do 
  
  app_dir = params[:name]
  venv_dir = params[:venv_dir]
  
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
  
  when "py_venv_buildout", "javapy_venv_buildout_ant"
    bash "prepare cache" do
      cwd "/tmp"
      code <<-EOH
      set -e
      if [ -d /opt/cache/ ]; then
        rm -rf /opt/cache
      fi
      mkdir /opt/cache
      cd /opt/cache
      wget #{conf[:super_cache]}
      tar xvzf *
      chown -R #{username} /opt/cache
      EOH
    end
    bash "run buildout" do
      cwd app_dir
      user username
      group groupname
      code <<-EOH
      set -e
      if [ -f autolaunch.cfg ]; then
        python ./bootstrap.py -c autolaunch.cfg
        bin/buildout -O -c autolaunch.cfg
      else
        python ./bootstrap.py
        bin/buildout
      fi
      echo 'export PATH="#{app_dir}/bin:$PATH"' >> #{venv_dir}/bin/activate
      EOH
    end
  else raise ArgumentError, "unknown install_method #{conf[:install_method]}"
  end
  
  case conf[:install_method]
  when "javapy_venv_buildout_ant"
    execute "ant #{conf[:ant_target]}" do
      cwd app_dir
      user username
      group groupname
      action :run
    end
  end
end
