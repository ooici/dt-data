# There is already an 'ioncore-python' directory in place.
bash "get-lcaarch" do
  code <<-EOH
  cd /home/#{node[:username]}
  cd ioncore-python
  git remote add thisone #{node[:capabilitycontainer][:git_lcaarch_repo]}
  git fetch --all
  git checkout -b activebranch thisone/#{node[:capabilitycontainer][:git_lcaarch_branch]}
  git pull
  git reset --hard #{node[:capabilitycontainer][:git_lcaarch_commit]}
  EOH
end

# Catch any dependency changes.  The burned requirements.txt is from commit
# caa5423d2c8293b077a8b381e6c6fd394a0987b3
bash "install-lcaarch-deps" do
  code <<-EOH
  cd /home/#{node[:username]}/ioncore-python
  pip install --quiet --find-links=#{node[:capabilitycontainer][:pip_package_repo]} --requirement=requirements.txt
  EOH
end

bash "twisted-plugin-issue" do
  code <<-EOH
  cp /home/#{node[:username]}/ioncore-python/twisted/plugins/cc.py /usr/local/lib/python2.6/dist-packages/twisted/plugins/
  EOH
end

bash "give-container-user-ownership" do
  code <<-EOH
  chown -R #{node[:username]}:#{node[:username]} /home/#{node[:username]}
  if [ -f /opt/cei_environment ]; then
    chown #{node[:username]}:#{node[:username]} /opt/cei_environment
  fi
  EOH
end

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


template "/home/#{node[:username]}/ioncore-python/res/logging/loglevels.cfg" do
  source "loglevels.cfg.erb"
  owner "#{node[:username]}"
  variables(:log_level => node[:capabilitycontainer][:log_level])
end


node[:services].each do |service, service_spec|

  service_config = "/home/#{node[:username]}/ioncore-python/res/config/#{service}-ionservices.cfg"

  template "#{service_config}" do
    source "ionservices.cfg.erb"
    owner "#{node[:username]}"
    variables(:service_spec => service_spec)
  end
  
  logging_dir = "/home/#{node[:username]}/ioncore-python/logs/#{service}"
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
    cwd "/home/#{node[:username]}/ioncore-python"
    code <<-EOH
    echo "#!/bin/bash" >> start-#{service}.sh
    if [ -f /opt/cei_environment ]; then
      source /opt/cei_environment
      echo "source /opt/cei_environment" >> start-#{service}.sh
    fi
    echo "export ION_ALTERNATE_LOGGING_CONF=#{logging_config}" >> start-#{service}.sh
    echo "twistd --pidfile=#{service}-service.pid cc -n -h #{node[:capabilitycontainer][:broker]} --broker_heartbeat=#{node[:capabilitycontainer][:broker_heartbeat]} -a processes=#{service_config},sysname=#{node[:capabilitycontainer][:sysname]} #{node[:capabilitycontainer][:bootscript]}" >> start-#{service}.sh
    chmod +x start-#{service}.sh
    EOH
  end

  bash "start-service" do
    not_if { node.include? :do_not_start and node[:do_not_start].include? service }
    user node[:username]
    cwd "/home/#{node[:username]}/ioncore-python"
    environment({
      "HOME" => "/home/#{node[:username]}",
      "ION_ALTERNATE_LOGGING_CONF" => "#{logging_config}"
    })
    code <<-EOH
    ./start-#{service}.sh
    EOH
  end
end
