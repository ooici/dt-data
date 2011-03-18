app_archive = "/tmp/app-archive.tar.gz"
app_dir = "/home/#{node[:username]}/app"
venv_dir = "/home/#{node[:username]}/app-venv"

execute "Cleanup app dir" do
  command "rm -rf #{app_dir}"
end
execute "Cleanup virtualenv dir" do
  command "rm -rf #{venv_dir}"
end

########################################################################
# RETRIEVAL
########################################################################

case node[:appretrieve][:retrieve_method]
when "archive"
  if node[:appretrieve][:archive_url] =~ /(.*)\.tar\.gz$/
    print "url is tar.gz"
  else
    raise ArgumentError, 'archive_url is not tar.gz file'
  end
  remote_file app_archive do
    source node[:appretrieve][:archive_url]
    owner node[:username]
    group node[:groupname]
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
    command "git clone #{node[:appretrieve][:git_repo]} #{app_dir}/"
  end
  execute "fetch all code" do
    cwd app_dir
    command "git fetch"
  end
  execute "checkout the desired branch" do
    cwd app_dir
    command "git checkout -b activebranch origin/#{node[:appretrieve][:git_branch]}"
  end
  # This makes HEAD meaningful: 
  execute "move branch to latest" do
    cwd app_dir
    command "git pull"
  end
  execute "move branch to commit or reference" do
    cwd app_dir
    command "git reset --hard #{node[:appretrieve][:git_commit]}"
  end
else raise ArgumentError, "unknown retrieve_method #{node[:appretrieve][:retrieve_method]}, should be 'archive' or 'git'"
end

########################################################################
# INSTALLATION
########################################################################

case node[:appinstall][:install_method]
when "py_venv_setup"
  execute "create virtualenv" do
    command "/opt/python2.5/bin/virtualenv --python=python2.5 --no-site-packages #{venv_dir}"
  end
  bash "run install" do
    cwd app_dir
    code <<-EOH
    source #{venv_dir}/bin/activate
    #{venv_dir}/bin/python setup.py install
    EOH
  end
when "py_venv_buildout"
  execute "create virtualenv" do
    command "/opt/python2.5/bin/virtualenv --python=python2.5 --no-site-packages #{venv_dir}"
  end
  bash "run install" do
    cwd app_dir
    code <<-EOH
    source #{venv_dir}/bin/activate
    #{venv_dir}/bin/python ./bootstrap.py
    #{venv_dir}/bin/buildout
    EOH
  end
else raise ArgumentError, "unknown install_method #{node[:appinstall][:install_method]}"
end

bash "give-app-user-ownership" do
  code <<-EOH
  chown -R #{node[:username]}:#{node[:groupname]} /home/#{node[:username]}
  EOH
end

########################################################################
# ACCESS
########################################################################

bash "give-remote-user-log-access" do
  code <<-EOH
  if [ ! -d /home/#{node[:username]}/.ssh ]; then
    mkdir /home/#{node[:username]}/.ssh
  fi
  if [ -f /root/.ssh/authorized_keys ]; then
    cp /root/.ssh/authorized_keys /home/#{node[:username]}/.ssh/
  fi
  chown -R #{node[:username]}:#{node[:groupname]} /home/#{node[:username]}/.ssh
  EOH
end

########################################################################
# PREPARE SERVICES
########################################################################
   
case node[:apprun][:run_method]
when "sh", "supervised"
  
  ######################################################################
  # PREPARE SH or SUPERVISED
  ######################################################################
    
  template "#{app_dir}/res/logging/loglevels.cfg" do
    source "loglevels.cfg.erb"
    owner "#{node[:username]}"
    group "#{node[:groupname]}"
    variables(:log_level => node[:pythoncc][:log_level])
  end

  template "#{app_dir}/ooici-conn.properties" do
    source "ooici-conn.properties.erb"
    owner "#{node[:username]}"
    group "#{node[:groupname]}"
    variables(:exchange => node[:pythoncc][:sysname],
              :server => node[:pythoncc][:broker])

  end
  
  ionlocal_config File.join(app_dir, "res/config/ionlocal.config") do
    user node[:username]
    group node[:groupname]
    universals node[:universal_app_confs]
    locals node[:local_app_confs]
  end
  
  node[:services].each do |service, service_spec|
    
    service_config = service_spec[:service_config]
    abs_service_config = File.join(app_dir, service_config)
    ruby_block "check-config" do
      block do
        raise ArgumentError, "Cannot locate service config #{abs_service_config}" unless File.exist?(abs_service_config)
      end
    end
  
    logging_dir = "#{app_dir}/logs/#{service}"
    directory "#{logging_dir}" do
      owner "#{node[:username]}"
      group "#{node[:groupname]}"
      mode "0755"
    end
    
    logging_config = "#{logging_dir}/#{service}-logging.conf"
        
    template "#{logging_config}" do
      source "ionlogging.conf.erb"
      owner "#{node[:username]}"
      group "#{node[:groupname]}"
      variables(:service_name => service)
    end
    
    ion_conf_section = ""
    if service_spec.include? :ION_CONFIGURATION_SECTION
      ion_conf_section = service_spec[:ION_CONFIGURATION_SECTION]
    end
    
    start_script = File.join(app_dir, "start-#{service}.sh")
    template start_script do
      source "start-service.sh.erb"
      owner node[:username]
      group node[:groupname]
      mode 0755
      variables(:service => service, 
                :service_config => service_config, 
                :venv_dir => venv_dir,
                :app_dir => app_dir,
                :logging_config => logging_config, 
                :sysname => node[:pythoncc][:sysname], 
                :broker => node[:pythoncc][:broker],
                :broker_heartbeat => node[:pythoncc][:broker_heartbeat],
                :ION_CONFIGURATION_SECTION => ion_conf_section)
    end

    # add command to service definition
    service_spec[:command] = start_script
  end
else raise ArgumentError, "unknown install_method #{node[:apprun][:run_method]}"
end

########################################################################
# RUN SERVICES
########################################################################

# make a new hash with just the services where :autostart is missing or true
autostart_services = node[:services].reject do |k,v|
  v.include?(:autostart) and not v[:autostart]
end

case node[:apprun][:run_method]
when "sh"
  ######################################################################
  # RUN SH
  ######################################################################
  autostart_services.each do |service, service_spec|
    execute "start-service" do
      user node[:username]
      group node[:groupname]
      environment({
        "HOME" => "/home/#{node[:username]}"
      })
      command File.join(app_dir, "start-#{service}.sh")
    end
  end

when "supervised"
  ######################################################################
  # RUN SUPERVISED
  ######################################################################
  
  
  bash "install-supervisor" do
  code <<-EOH
  ACTIVATE=#{venv_dir}/bin/activate
  if [ -f $ACTIVATE ]; then
    source $ACTIVATE
  fi
  easy_install supervisor
  EOH
  end

  sup_conf = File.join(app_dir, "supervisor.conf")
  template sup_conf do
    source "supervisor.conf.erb"
    mode 0400
    owner node[:username]
    group node[:groupname]
    variables(:programs => autostart_services)
  end

  bash "start-supervisor" do
  user node[:username]
  group node[:groupname]
  environment({
    "HOME" => "/home/#{node[:username]}"
  })
  code <<-EOH
  ACTIVATE=#{venv_dir}/bin/activate
  if [ -f $ACTIVATE ]; then
    source $ACTIVATE
  fi
  supervisord -c #{sup_conf}
  EOH
end

else raise ArgumentError, "unknown install_method #{node[:apprun][:run_method]}"
end

