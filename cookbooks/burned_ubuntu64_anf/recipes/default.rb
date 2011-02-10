# The node was burned with ioncore-python but we are going to install something else
bash "get-code" do
  code <<-EOH
  cd /home/#{node[:username]}
  rm -rf ioncore-python
  rm -rf #{node[:capabilitycontainer][:git_repo_dirname]}
  git clone #{node[:capabilitycontainer][:git_lcaarch_repo]}
  cd #{node[:capabilitycontainer][:git_repo_dirname]}
  git fetch --all
  git checkout -b activebranch thisone/#{node[:capabilitycontainer][:git_lcaarch_branch]}
  git pull
  git reset --hard #{node[:capabilitycontainer][:git_lcaarch_commit]}
  EOH
end

bash "install-code" do
  cwd "/home/#{node[:username]}/#{node[:capabilitycontainer][:git_repo_dirname]}"
  code <<-EOH
  set -e
  python setup.py install
  EOH
end

directory "/home/#{node[:username]}/#{node[:capabilitycontainer][:git_repo_dirname]}/logs" do
  owner "#{node[:username]}"
  group "#{node[:username]}"
  mode "0755"
end

# Temporary workarounds
  bash "workaround1" do
    cwd "/usr/lib/python2.6/dist-packages/twisted/plugins"
    code <<-EOH
    echo "#!/usr/bin/env python" > cc.py
    echo "from twisted.application.service import ServiceMaker" >> cc.py
    echo 'CC = ServiceMaker(name="ION CapabilityContainer", module="ion.core.cc.service", description="ION Capability Container", tapname="cc")' >> cc.py
    EOH
  end
  bash "workaround2" do
    cwd "/home/#{node[:username]}/#{node[:capabilitycontainer][:git_repo_dirname]}"
    code <<-EOH
    mkdir /home/#{node[:username]}/ioncore-python
    ln -s logs /home/#{node[:username]}/ioncore-python/logs
    EOH
  end

bash "give-container-user-ownership" do
  code <<-EOH
  chown -R #{node[:username]}:#{node[:username]} /home/#{node[:username]}
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


template "/home/#{node[:username]}/#{node[:capabilitycontainer][:git_repo_dirname]}/res/logging/loglevels.cfg" do
  source "loglevels.cfg.erb"
  owner "#{node[:username]}"
  variables(:log_level => node[:capabilitycontainer][:log_level])
end


node[:services].each do |service, service_spec|

  service_config = "/home/#{node[:username]}/#{node[:capabilitycontainer][:git_repo_dirname]}/res/config/#{service}-ionservices.cfg"

  template "#{service_config}" do
    source "ionservices.cfg.erb"
    owner "#{node[:username]}"
    variables(:service_spec => service_spec)
  end
  
  logging_dir = "/home/#{node[:username]}/#{node[:capabilitycontainer][:git_repo_dirname]}/logs/#{service}"
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
    cwd "/home/#{node[:username]}/#{node[:capabilitycontainer][:git_repo_dirname]}"
    code <<-EOH
    echo "#!/bin/bash" >> start-#{service}.sh
    echo "export ION_ALTERNATE_LOGGING_CONF=#{logging_config}" >> start-#{service}.sh
    echo "twistd --pidfile=#{service}-service.pid cc -n -h #{node[:capabilitycontainer][:broker]} --broker_heartbeat=#{node[:capabilitycontainer][:broker_heartbeat]} -a processes=#{service_config},sysname=#{node[:capabilitycontainer][:sysname]} #{node[:capabilitycontainer][:bootscript]}" >> start-#{service}.sh
    chmod +x start-#{service}.sh
    EOH
  end

  bash "start-service" do
    not_if { node.include? :do_not_start and node[:do_not_start].include? service }
    user node[:username]
    cwd "/home/#{node[:username]}/#{node[:capabilitycontainer][:git_repo_dirname]}"
    environment({
      "HOME" => "/home/#{node[:username]}",
      "ION_ALTERNATE_LOGGING_CONF" => "#{logging_config}"
    })
    code <<-EOH
    set -e
    ./start-#{service}.sh
    EOH
  end
end
