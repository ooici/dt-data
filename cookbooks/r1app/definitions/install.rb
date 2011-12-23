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
  
  # in chef 0.9+ this should be cookbook_file
  remote_file "/tmp/versionreport.py" do
    source "versionreport.py"
    mode "0755"
  end

  env = conf[:build_env]
  env = env && env.to_hash

  case conf[:install_method]
  when "py_venv_setup"
    execute "run install" do
      cwd app_dir
      user username
      group groupname
      environment env
      command "env >/tmp/env ; python setup.py install"
    end
  when "py_venv_buildout", "javapy_venv_buildout_ant"
    bash "prepare cache" do
      cwd "/tmp"
      code <<-EOH
      set -e
      if [ ! -d /opt/cache/eggs ]; then
        rm -rf /opt/cache
        mkdir /opt/cache
        cd /opt/cache
        wget #{conf[:super_cache]}
        tar xzf *
        chmod -R 777 /opt/cache
      fi
      EOH
    end
    bash "run buildout" do
      cwd app_dir
      user username
      group groupname
      environment env
      code <<-EOH
      set -e
      source #{venv_dir}/bin/activate
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
    bash "run ant" do
      cwd app_dir
      user username
      group groupname
      code <<-EOH
      sed -i 's/ivy.cache.dir=.*/ivy.cache.dir=\\/opt\\/cache\\/ivy/' .settings/ivysettings.properties
      /opt/ant-1.8.2/bin/ant #{conf[:ant_target]}
      EOH
    end
    bash "run java-version-print" do
      cwd app_dir
      user username
      group groupname
      code <<-EOH
      ./bin/python /tmp/versionreport.py lib >> logs/versions.log
      EOH
    end
  when "py_venv_buildout"
    bash "run python-version-print" do
      cwd app_dir
      user username
      group groupname
      code <<-EOH
      ./bin/python /tmp/versionreport.py >> logs/versions.log
      EOH
    end
  end
end
