bash "get-lcaarch" do
  code <<-EOH
  cd /home/#{node[:username]}
  git clone #{node[:capabilitycontainer][:git_lcaarch_repo]}
  cd #{node[:capabilitycontainer][:git_repo_dirname]}
  git checkout #{node[:capabilitycontainer][:git_lcaarch_branch]}
  git fetch
  git reset --hard #{node[:capabilitycontainer][:git_lcaarch_commit]}
  EOH
end

%w{ python-dev python-pip swig }.each do |pkg|
  package pkg
end

bash "install-lcaarch-deps" do
  code <<-EOH
  cd /home/#{node[:username]}/#{node[:capabilitycontainer][:git_repo_dirname]}
  pip install --find-links=#{node[:capabilitycontainer][:pip_package_repo]} --requirement=requirements.txt
  EOH
end

bash "remove-twisted-plugin-dropin.cache.new-error" do
  code <<-EOH
  twistd --help &>/dev/null
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

directory "/home/#{node[:username]}/.ssh" do
  owner node[:username]
  group node[:username]
  mode 0700
end

bash "give-remote-user-log-access" do
  code <<-EOH
  if [ -f /home/ubuntu/.ssh/authorized_keys ]; then
    cp /home/ubuntu/.ssh/authorized_keys /home/#{node[:username]}/.ssh/
    chown #{node[:username]}:#{node[:username]} /home/#{node[:username]}/.ssh/authorized_keys
  fi
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
  

  bash "start-service" do
    user node[:username]
    environment({
      "HOME" => "/home/#{node[:username]}",
      "ION_ALTERNATE_LOGGING_CONF" => "#{logging_config}"
    })
    cwd "/home/#{node[:username]}/#{node[:capabilitycontainer][:git_repo_dirname]}"
    code <<-EOH
    echo "#!/bin/bash" >> start-#{service}.sh
    if [ -f /opt/cei_environment ]; then
      source /opt/cei_environment
      echo "source /opt/cei_environment" >> start-#{service}.sh
    fi
    echo "export ION_ALTERNATE_LOGGING_CONF=#{logging_config}" >> start-#{service}.sh
    echo "twistd --pidfile=#{service}-service.pid cc -n -h #{node[:capabilitycontainer][:broker]} --broker_heartbeat=#{node[:capabilitycontainer][:broker_heartbeat]} -a processes=#{service_config},sysname=#{node[:capabilitycontainer][:sysname]} #{node[:capabilitycontainer][:bootscript]}" >> start-#{service}.sh
    chmod +x start-#{service}.sh
    ./start-#{service}.sh
    EOH
  end

end
