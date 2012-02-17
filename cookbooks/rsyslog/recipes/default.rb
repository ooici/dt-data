package "rsyslog" do
  action :install
end

directory node[:rsyslog][:directory] do
  owner node[:rsyslog][:user]
  group node[:rsyslog][:user]
  mode "0755"
  action :create
end

template "/etc/rsyslog.d/#{node[:rsyslog][:config_priority]}-#{node[:rsyslog][:name]}.conf" do
  source "rsyslog.conf.erb"
  owner node[:rsyslog][:user]
  group node[:rsyslog][:user]
end

bash "register with loggly" do
    code <<-EOH
    curl -X POST -u #{node[:rsyslog][:loggly][:username]} http://#{node[:rsyslog][:loggly][:subdomain]}.loggly.com/api/inputs/#{node[:rsyslog][:loggly][:port]}/adddevice
    EOH
    only_if {node[:rsyslog][:loggly] &&
             node[:rsyslog][:loggly][:port] &&
             node[:rsyslog][:loggly][:subdomain] &&
             node[:rsyslog][:loggly][:username]}
end

service "rsyslog" do
  supports :restart => true
  action [:enable, :restart]
end
