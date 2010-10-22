bash "get-lcaarch" do
  code <<-EOH
  cd /home/#{node[:username]}
  git clone #{node[:capabilitycontainer][:git_lcaarch_repo]}
  cd lcaarch
  git checkout #{node[:capabilitycontainer][:git_lcaarch_branch]}
  git fetch
  git reset --hard #{node[:capabilitycontainer][:git_lcaarch_commit]}
  EOH
end

bash "install-lcaarch-deps" do
  code <<-EOH
  apt-get -y install python-dev
  easy_install msgpack-python
  cd /home/#{node[:username]}/lcaarch
  pip install --find-links=http://ooici.net/packages --requirement=requirements.txt --use-mirrors
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


template "/home/#{node[:username]}/lcaarch/res/logging/loglevels.cfg" do
  source "loglevels.cfg.erb"
  owner "#{node[:username]}"
  variables(:log_level => node[:capabilitycontainer][:log_level])
end


node[:services].each do |service, service_spec|

  service_config = "/home/#{node[:username]}/lcaarch/res/config/#{service}-ionservices.cfg"

  template "#{service_config}" do
    source "ionservices.cfg.erb"
    owner "#{node[:username]}"
    variables(:service_spec => service_spec)
  end

  bash "start-service" do
    user node[:username]
    code <<-EOH
    if [ -f /opt/cei_environment ]; then
      source /opt/cei_environment
    fi
    cd /home/#{node[:username]}/lcaarch
    twistd --pidfile=#{service}-service.pid --logfile=#{service}-service.log magnet -n -h #{node[:capabilitycontainer][:broker]} --broker_heartbeat=#{node[:capabilitycontainer][:broker_heartbeat]} -a processes=#{service_config},sysname=#{node[:capabilitycontainer][:sysname]} #{node[:capabilitycontainer][:bootscript]}
    EOH
  end

end
