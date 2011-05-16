app_archive = "/tmp/app-archive.tar.gz"
app_dir = "/home/#{node[:username]}/app"
venv_dir = node[:virtualenv][:path]
monitor_dir = "/home/#{node[:username]}/appmonitor"

# virtualenv creation might have happened earlier
include_recipe "virtualenv"

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
  venv_dir venv_dir
end

########################################################################
# ACCESS
########################################################################

bash "give-remote-user-access" do
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
  if [ -f /opt/nimbus/chef.log ]; then
    ln -s /opt/nimbus/chef.log #{app_dir}/logs/ctxagent-chef.log
  fi
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
    if [ -d /home/ubuntu/ ]; then
      cp #{app_dir}/ooici-conn.properties /home/ubuntu/
      chown ubuntu /home/ubuntu/ooici-conn.properties
    fi
    EOH
  end
  
  # Our ioncontainer_config callout needs this in the virtualenv itself
  bash "ensure simplejson" do
    code <<-EOH
    easy_install simplejson==2.1.2
    EOH
  end

  broker_username = node[:pythoncc][:broker_username]
  broker_password = node[:pythoncc][:broker_password]
  if broker_username and broker_password
    broker_credfile = File.join(app_dir, "broker_creds.txt")
    file broker_credfile do
      owner node[:username]
      group node[:groupname]
      mode "0600"
      content "#{broker_username} #{broker_password}"
    end
  else
    broker_credfile = nil
  end
  
  template "#{app_dir}/messaging.conf" do
    source "messaging.conf.erb"
    owner "#{node[:username]}"
    group "#{node[:groupname]}"
    variables(:exchange => node[:pythoncc][:sysname],
              :server => node[:pythoncc][:broker],
              :broker_credfile => broker_credfile)
  end
  
  bash "give-remote-user-messaging-conf-access" do
    code <<-EOH
    if [ -d /home/ubuntu/ ]; then
      if [ -f #{app_dir}/broker_creds.txt ]; then
        cp #{app_dir}/broker_creds.txt /home/ubuntu/
        chown ubuntu /home/ubuntu/broker_creds.txt
      fi
    fi
    EOH
  end
  
  template "/home/ubuntu/messaging.conf" do
    not_if do ! File.exists?("/home/ubuntu/ooici-conn.properties") end
    source "messaging.conf.erb"
    owner "ubuntu"
    variables(:exchange => node[:pythoncc][:sysname],
              :server => node[:pythoncc][:broker],
              :broker_credfile => "/home/ubuntu/broker_creds.txt")
  end
    
  ionlocal_config File.join(app_dir, "res/config/ionlocal.config") do
    user node[:username]
    group node[:groupname]
    universals node[:universal_app_confs]
    locals node[:local_app_confs]
  end
  
  node[:ioncontainers].each do |ioncontainer_name, ioncontainer_spec|
    
    # File to create for this container:
    abs_ioncontainer_config = File.join(app_dir, "res/deploy/#{ioncontainer_name}.rel")
    
    ioncontainer_config abs_ioncontainer_config do
      user node[:username]
      group node[:groupname]
      ioncontainer_name ioncontainer_name
      ioncontainer_spec ioncontainer_spec
    end

    logging_dir = "#{app_dir}/logs/#{ioncontainer_name}"
    directory "#{logging_dir}" do
      owner "#{node[:username]}"
      group "#{node[:groupname]}"
      mode "0755"
    end

    logging_config = "#{logging_dir}/#{ioncontainer_name}-logging.conf"

    template "#{logging_config}" do
      source "ionlogging.conf.erb"
      owner "#{node[:username]}"
      group "#{node[:groupname]}"
      variables(:service_name => ioncontainer_name)
    end
    
    ion_conf_section = ""
    
    start_script = File.join(app_dir, "start-#{ioncontainer_name}.sh")
    template start_script do
      source "start-service.sh.erb"
      owner node[:username]
      group node[:groupname]
      mode 0755
      variables(:service => ioncontainer_name, 
                :service_config => abs_ioncontainer_config, 
                :venv_dir => venv_dir,
                :app_dir => app_dir,
                :logging_config => logging_config, 
                :sysname => node[:pythoncc][:sysname], 
                :broker => node[:pythoncc][:broker],
                :broker_heartbeat => node[:pythoncc][:broker_heartbeat],
                :broker_credfile => broker_credfile,
                :ION_CONFIGURATION_SECTION => ion_conf_section)
    end

    # add command to services list if it is autostart
    if not ioncontainer_spec.include?(:autostart) or ioncontainer_spec[:autostart]
      autostart_services[ioncontainer_name] = {:command => start_script} 
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
  
  execute "install-supervisor" do
    user node[:username]
    group node[:groupname]
    command "easy_install supervisor"
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

