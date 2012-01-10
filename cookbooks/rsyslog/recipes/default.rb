package "rsyslog" do
  action :install
end

directory node[:rsyslog][:directory] do
  owner node[:rsyslog][:user]
  group node[:rsyslog][:user]
  mode "0755"
  action :create
end

template "/etc/rsyslog.d/#{node[:rsyslog][:config_priority]}-epu.conf" do
  source "epu.conf.erb"
  owner node[:rsyslog][:user]
  group node[:rsyslog][:user]
end

service "rsyslog" do
  supports :restart => true
  action [:enable, :restart]
end
