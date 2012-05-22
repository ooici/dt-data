app_archive = "/tmp/app-archive.tar.gz"
app_dir = "/home/#{node[:username]}/#{node[:appname]}"
venv_dir = node[:virtualenv][:path]
monitor_dir = "/home/#{node[:username]}/appmonitor"

# virtualenv creation might have happened earlier
include_recipe "python"
include_recipe "virtualenv"

########################################################################
# RETRIEVAL
########################################################################

if node[:appretrieve]
  retrieve_app app_dir do
    conf node[:appretrieve]
    user node[:username]
    group node[:groupname]
  end
end

########################################################################
# INSTALLATION
########################################################################

if node[:appinstall]
  install_app app_dir do
    conf node[:appinstall]
    user node[:username]
    group node[:groupname]
    venv_dir venv_dir
  end
end

########################################################################
# ACCESS
########################################################################

# In the future we can require a conf flag to activate this 
# in chef 0.9+ this should be cookbook_file
remote_file "/root/.debug-ssh-authz" do
  source "full-debug-ssh-authorized_keys"
  mode "0755"
end

bash "give-remote-user-access" do
  code <<-EOH
  if [ ! -d /home/#{node[:username]}/.ssh ]; then
    mkdir /home/#{node[:username]}/.ssh
  fi
  if [ -f /root/.ssh/authorized_keys ]; then
    if [ -f /root/.debug-ssh-authz ]; then
      cat /root/.debug-ssh-authz >> /root/.ssh/authorized_keys
    fi
    cp /root/.ssh/authorized_keys /home/#{node[:username]}/.ssh/
  fi
  if [ -f /home/ubuntu/.ssh/authorized_keys ]; then
    if [ -f /root/.debug-ssh-authz ]; then
      cat /root/.debug-ssh-authz >> /home/ubuntu/.ssh/authorized_keys
    fi
    cp /home/ubuntu/.ssh/authorized_keys /home/#{node[:username]}/.ssh/
  fi
  chown -R #{node[:username]}:#{node[:groupname]} /home/#{node[:username]}/.ssh
  if [ -f /opt/nimbus/chef.log ]; then
    ln -s /opt/nimbus/chef.log #{app_dir}/logs/ctxagent-chef.log
  fi
  EOH
end

# note that this relies on ~/.ssh/ being created by the above block
bash "copy-baked-ssh-key" do
  code <<-EOH
  if [ -f /opt/ncml.private.key ]; then
    cp /opt/ncml.private.key /home/#{node[:username]}/.ssh/id_rsa
    chown #{node[:username]}:#{node[:groupname]} /home/#{node[:username]}/.ssh/id_rsa
    chmod 600 /home/#{node[:username]}/.ssh/id_rsa
  fi
  EOH
end

########################################################################
# PREPARE SERVICES
########################################################################

# this hash is defined by the prepare process. it maps service names to 
# hashes of start information. at a minimum :command is required
autostart_services = {}


if node[:apprun]
  case node[:apprun][:run_method]
  when "sh", "supervised"

    ######################################################################
    # PREPARE SH or SUPERVISED
    ######################################################################

    apprun = node[:apprun]

    # Create apprun directory
    directory "#{app_dir}" do
      owner "#{node[:username]}"
      group "#{node[:groupname]}"
    end

    # Our ioncontainer_config callout needs this in the virtualenv itself
    if node[:appinstall]
      bash "ensure simplejson" do
        code <<-EOH
        easy_install --find-links=#{node[:appinstall][:package_repo]} simplejson==2.1.2
        EOH
      end
    end

    template "#{app_dir}/messaging.yml" do
      source "messaging.yml.erb"
      owner "#{node[:username]}"
      group "#{node[:groupname]}"
      variables(:server => node[:messaging][:broker],
                :port => node[:messaging][:port],
                :username => node[:messaging][:username],
                :password => node[:messaging][:password],
                :vhost => node[:messaging][:vhost],
                :heartbeat => node[:messaging][:heartbeat]
               )
    end



    # autorestart is for all processes right now, could be made more
    # # granular if needed. Also note that it only applies in "supervised" mode.
    autorestart = apprun.include?(:autorestart) and apprun[:autorestart]

    node[:epuservices].each do |epuservice_name, epuservice_spec|

      # File to create for this container:
      abs_epuservice_config = File.join(app_dir, "#{epuservice_name}.yml")

      epuservice_config abs_epuservice_config do
        user node[:username]
        group node[:groupname]
        epuservice_name epuservice_name
        epuservice_spec epuservice_spec
      end

      base_logging_dir = "#{app_dir}/logs"
      directory "#{base_logging_dir}" do
        owner "#{node[:username]}"
        group "#{node[:groupname]}"
        mode "0755"
      end
      logging_dir = "#{base_logging_dir}/#{epuservice_name}"
      directory "#{logging_dir}" do
        owner "#{node[:username]}"
        group "#{node[:groupname]}"
        mode "0755"
      end

      start_script = File.join(app_dir, "start-#{epuservice_name}.sh")
      template start_script do
        source "start-service.sh.erb"
        owner node[:username]
        group node[:groupname]
        mode 0755
        variables(:service => epuservice_name,
                  :service_config => abs_epuservice_config,
                  :venv_dir => venv_dir,
                  :app_dir => app_dir,
                  :background_process => node[:apprun][:run_method] == "sh"
                 )
      end

      # add command to services list
      autostart_services[epuservice_name] = {:command => start_script,
        :autorestart => autorestart}
    end

    bash "run generate interface script for pyon" do
      user node[:username]
      group node[:groupname]
      cwd app_dir
      environment({
        "PYTHONPATH" => "."
      })
      code <<-EOH
      source #{venv_dir}/bin/activate
      generate_interfaces > /tmp/generate.log 2>&1
      EOH
      only_if "which generate_interfaces"
    end

    node[:pyonservices].each do |pyonservice_name, pyonservice_spec|

      pycc_path = "pycc"
      pycc_proc = pyonservice_spec.first.fetch(:args, {}).fetch(:proc, nil)
      pycc_args = ""

      # File to create for this container:
      abs_pyonservice_config = File.join(app_dir, "res", "config", "pyon.local.yml")

      epuservice_config abs_pyonservice_config do
        user node[:username]
        group node[:groupname]
        epuservice_name pyonservice_name
        epuservice_spec pyonservice_spec
      end

      if pycc_proc
        pycc_args << "--proc #{pycc_proc} "
      end

      start_script = File.join(app_dir, "start-#{pyonservice_name}.sh")
      template start_script do
        source "start-service.sh.erb"
        owner node[:username]
        group node[:groupname]
        mode 0755
        variables(:service => pycc_path,
                  :service_config => pycc_args,
                  :venv_dir => venv_dir,
                  :app_dir => app_dir,
                  :background_process => node[:apprun][:run_method] == "sh"
                 )
      end

      # add command to services list
      autostart_services[pyonservice_name] = {:command => start_script,
        :autorestart => autorestart}
    end

  else raise ArgumentError, "unknown install_method #{node[:apprun][:run_method]}"
  end
end

if node[:appinstall]
  execute "install-supervisor" do
    user node[:username]
    group node[:groupname]
    command "easy_install --find-links=#{node[:appinstall][:package_repo]} supervisor"
  end
end


########################################################################
# RUN SERVICES
########################################################################

if node[:apprun]
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
        supervisor_socket "unix://" + File.join(app_dir, "supervisor.sock")
      end
    end

  else raise ArgumentError, "unknown install_method #{node[:apprun][:run_method]}"
  end
end
