bash "set-lcaarch" do
  code <<-EOH
  cd /home/#{node[:username]}/lcaarch
  git fetch
  git reset --hard #{node[:burned_worker][:lcaarch_commit_hash]}
  EOH
end

template "/home/#{node[:username]}/lcaarch/res/logging/loglevels.cfg" do
  source "loglevels.cfg.erb"
  owner "#{node[:username]}"
  variables(:log_level => node[:burned_worker][:log_level])
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
    cd /home/#{node[:username]}/lcaarch
    twistd --pidfile=#{service}-service.pid --logfile=#{service}-service.log magnet -n -h #{node[:burned_worker][:broker]} --broker_heartbeat=#{node[:burned_worker][:broker_heartbeat]} -a processes=#{service_config},sysname=#{node[:burned_worker][:sysname]} #{node[:burned_worker][:bootscript]}
    EOH
  end

end
