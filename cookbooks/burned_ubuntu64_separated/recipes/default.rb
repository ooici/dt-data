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
    group node[:username]
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
  directory app_dir do
    owner node[:username]
    group node[:username]
    mode "0755"
    action :create
  end
  execute "clone the repository" do
    command "git clone #{node[:appretrieve][:git_repo]} #{app_dir}/"
  end
  execute "fetch all code" do
    cwd app_dir
    command "git fetch --all"
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
  package "python-virtualenv" do
    action :install
  end
  execute "create virtualenv" do
    command "virtualenv --no-site-packages #{venv_dir}"
  end
  bash "run install" do
    cwd app_dir
    code <<-EOH
    source #{venv_dir}/bin/activate
    #{venv_dir}/bin/python setup.py install
    EOH
  end
when "py_venv_buildout"
  raise ArgumentError, "not support 'py_venv_buildout' install_method just yet"
else raise ArgumentError, "unknown install_method #{node[:appinstall][:install_method]}"
end

bash "give-app-user-ownership" do
  code <<-EOH
  chown -R #{node[:username]}:#{node[:username]} /home/#{node[:username]}
  if [ -f /opt/cei_environment ]; then
    chown #{node[:username]}:#{node[:username]} /opt/cei_environment
  fi
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
  if [ -f /home/ubuntu/.ssh/authorized_keys ]; then
    cp /home/ubuntu/.ssh/authorized_keys /home/#{node[:username]}/.ssh/
  fi
  chown -R #{node[:username]} /home/#{node[:username]}/.ssh
  EOH
end

########################################################################
# RUN
########################################################################
   
case node[:apprun][:run_method]
when "sh"
  
  ######################################################################
  # RUN SH
  ######################################################################
    
  template "#{app_dir}/res/logging/loglevels.cfg" do
    source "loglevels.cfg.erb"
    owner "#{node[:username]}"
    variables(:log_level => node[:pythoncc][:log_level])
  end
  
  # The following excruciating ionlocal.config work should be a Ruby block
  bash "create ionlocal.config" do
    cwd app_dir
    user "#{node[:username]}" 
    code <<-EOH
    echo -e "{\n'epu.universal':{" > res/config/ionlocal.config
    EOH
  end
  node[:universal_app_confs].each do |u_key, u_value|
    bash "add universals to ionlocal.config" do
      cwd app_dir
      user "#{node[:username]}" 
      code <<-EOH
      echo "    '#{u_key}': '#{u_value}'," >> res/config/ionlocal.config
      EOH
    end
  end
  bash "modify ionlocal.config" do
    cwd app_dir
    user "#{node[:username]}" 
    code <<-EOH
    echo "}," >> res/config/ionlocal.config
    EOH
  end
  # Brutal:
  node[:local_app_confs].each do |section_name, keyvalue_dict|
    bash "add local section to ionlocal.config" do
      cwd app_dir
      user "#{node[:username]}" 
      code <<-EOH
      echo "'#{section_name}':{" >> res/config/ionlocal.config
      EOH
    end
    keyvalue_dict.each do |l_key, l_value|
      bash "add locals to ionlocal.config" do
        cwd app_dir
        user "#{node[:username]}" 
        code <<-EOH
        echo "    '#{l_key}': '#{l_value}'," >> res/config/ionlocal.config
        EOH
      end
    end
    bash "finish local section to ionlocal.config" do
      cwd app_dir
      user "#{node[:username]}" 
      code <<-EOH
      echo "}," >> res/config/ionlocal.config
      EOH
    end
  end
  bash "finish ionlocal.config" do
    cwd app_dir
    user "#{node[:username]}" 
    code <<-EOH
    echo "}" >> res/config/ionlocal.config
    EOH
  end
  
  node[:services].each do |service, service_config|
    
    abs_service_config = app_dir + "/" + service_config
    ruby_block "check-config" do
      block do
        raise ArgumentError, "Cannot locate service config #{abs_service_config}" unless File.exist?(abs_service_config)
      end
    end
  
    logging_dir = "#{app_dir}/logs/#{service}"
    directory "#{logging_dir}" do
      owner "#{node[:username]}"
      group "#{node[:username]}"
      mode "0755"
    end
    
    logging_config = "#{logging_dir}/#{service}-logging.conf"
        
    template "#{logging_config}" do
      source "ionlogging.conf.erb"
      owner "#{node[:username]}"
      variables(:service_name => service)
    end
  
    bash "service-script" do
      user node[:username]
      cwd app_dir
      code <<-EOH
      echo "#!/bin/bash" >> start-#{service}.sh
      if [ -f /opt/cei_environment ]; then
        source /opt/cei_environment
        echo "source /opt/cei_environment" >> start-#{service}.sh
      fi
      if [ -f #{venv_dir}/bin/activate ]; then
        echo "source #{venv_dir}/bin/activate" >> start-#{service}.sh
      fi
      echo "export ION_ALTERNATE_LOGGING_CONF=#{logging_config}" >> start-#{service}.sh
      echo "twistd --pidfile=#{service}-service.pid cc -n -h #{node[:pythoncc][:broker]} --broker_heartbeat=#{node[:pythoncc][:broker_heartbeat]} -a sysname=#{node[:pythoncc][:sysname]} #{service_config}" >> start-#{service}.sh
      chmod +x start-#{service}.sh
      EOH
    end
  
    execute "start-service" do
      not_if { node.include? :do_not_start and node[:do_not_start].include? service }
      user node[:username]
      cwd app_dir
      environment({
        "HOME" => "/home/#{node[:username]}",
        "ION_ALTERNATE_LOGGING_CONF" => "#{logging_config}"
      })
      command "./start-#{service}.sh"
    end
  end

when "supervised"
  
  ######################################################################
  # RUN SUPERVISED
  ######################################################################
  raise ArgumentError, "not support 'supervised' run_method just yet"

else raise ArgumentError, "unknown install_method #{node[:apprun][:run_method]}"
end

