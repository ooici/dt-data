app_archive = "/tmp/app-archive.tar.gz"
app_dir = "/home/#{node[:username]}/app"
venv_dir = "/home/#{node[:username]}/app-venv"
monitor_dir = "/home/#{node[:username]}/appmonitor"

execute "Cleanup app dir" do
  command "rm -rf #{app_dir}"
end
execute "Cleanup monitor dir" do
  command "rm -rf #{monitor_dir}"
end
execute "Cleanup virtualenv dir" do
  command "rm -rf #{venv_dir}"
end

########################################################################
# RETRIEVAL
########################################################################

retrieve_app app_dir do
  conf node[:appretrieve]
  user node[:username]
  group node[:groupname]
end

########################################################################
# INSTALLATION
########################################################################

install_app app_dir do
  conf node[:appinstall]
  user node[:username]
  group node[:groupname]
  virtualenv venv_dir
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
  if [ -f /home/ubuntu/.ssh/authorized_keys ]; then
    cp /home/ubuntu/.ssh/authorized_keys /home/#{node[:username]}/.ssh/
  fi
  chown -R #{node[:username]}:#{node[:groupname]} /home/#{node[:username]}/.ssh
  EOH
end

########################################################################
# PREPARE SERVICES
########################################################################

# this hash is defined by the prepare process. it maps service names to 
# hashes of start information. at a minimum :command is required
autostart_services = {}


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
  
  bash "give-remote-user-ooici-properties-access" do
    code <<-EOH
    if [ -f /home/ubuntu/ ]; then
      cp #{app_dir}/ooici-conn.properties /home/ubuntu/
      chown ubuntu /home/ubuntu/ooici-conn.properties
    fi
    EOH
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

    # add command to services list if it is autostart
    if not service_spec.include?(:autostart) or service_spec[:autostart]
      autostart_services[service] = {:command => start_script} 
    end

  end
else raise ArgumentError, "unknown install_method #{node[:apprun][:run_method]}"
end

########################################################################
# RUN SERVICES
########################################################################

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
      command service_spec[:command]
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

  # start up the monitor process, if configured
  if node.include? :appmonitor 
    app_monitor monitor_dir do
      conf node[:appmonitor]
      user node[:username]
      group node[:groupname]
      virtualenv venv_dir
      pythoncc node[:pythoncc]
      universals node[:universal_app_confs]
      supervisor_socket File.join(app_dir, "supervisor.sock")
    end
  end
else raise ArgumentError, "unknown install_method #{node[:apprun][:run_method]}"
end

