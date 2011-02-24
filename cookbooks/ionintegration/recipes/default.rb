bash "get-ion-integration" do
  code <<-EOH
  cd /home/#{node[:username]}
  git clone #{node[:ionintegration][:git_ion_integration_repo]}
  cd #{node[:ionintegration][:git_repo_dirname]}
  git checkout #{node[:ionintegration][:git_ion_integration_branch]}
  git fetch
  git reset --hard #{node[:ionintegration][:git_ion_integration_commit]}
  EOH
end

%w{ python-dev python-pip swig python-virtualenv ant}.each do |pkg|
  package pkg
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

bash "buildout-ion-integration" do
    user node[:username]
    cwd "/home/#{node[:username]}/#{node[:ionintegration][:git_repo_dirname]}"
  code <<-EOH
  virtualenv --no-site-packages ionenv
  . ionenv/bin/activate
  python ./bootstrap.py
  bin/buildout
  EOH
end

template "/home/#{node[:username]}/#{node[:ionintegration][:git_repo_dirname]}/res/logging/loglevels.cfg" do
  source "loglevels.cfg.erb"
  owner "#{node[:username]}"
  variables(:log_level => node[:ionintegration][:log_level])
end

template "/home/#{node[:username]}/#{node[:ionintegration][:git_repo_dirname]}/ooici-conn.properties" do
  source "ooici-conn.properties.erb"
  owner "#{node[:username]}"
  variables(:exchange_scope => node[:ionintegration][:sysname],
            :broker => node[:ionintegration][:broker])
end

node[:services].each do |service, service_spec|

  service_config = "/home/#{node[:username]}/#{node[:ionintegration][:git_repo_dirname]}/res/config/#{service}-ionservices.cfg"

  template "#{service_config}" do
    source "ionservices.cfg.erb"
    owner "#{node[:username]}"
    variables(:service_spec => service_spec)
  end
  
  logging_dir = "/home/#{node[:username]}/#{node[:ionintegration][:git_repo_dirname]}/logs/#{service}"
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
    cwd "/home/#{node[:username]}/#{node[:ionintegration][:git_repo_dirname]}"
    code <<-EOH
    echo "#!/bin/bash" >> start-#{service}.sh
    echo "export ION_ALTERNATE_LOGGING_CONF=#{logging_config}" >> start-#{service}.sh
    echo "bin/twistd --pidfile=#{service}-service.pid cc -n -h #{node[:ionintegration][:broker]} --broker_heartbeat=#{node[:ionintegration][:broker_heartbeat]} -a processes=#{service_config},sysname=#{node[:ionintegration][:sysname]} #{node[:ionintegration][:bootscript]}" >> start-#{service}.sh
    chmod +x start-#{service}.sh
    ./start-#{service}.sh
    EOH
  end

end
