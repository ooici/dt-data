package "rsyslog" do
  action :install
end

directory node[:rsyslog][:directory] do
  mode "0755"
  action :create
end

template "/etc/rsyslog.d/#{node[:rsyslog][:config_priority]}-#{node[:rsyslog][:name]}.conf" do
  source "rsyslog.conf.erb"
end

bash "register with loggly" do
    code <<-EOH
    curl -X POST -u #{node[:rsyslog][:loggly][:username]}:#{node[:rsyslog][:loggly][:password]} http://#{node[:rsyslog][:loggly][:subdomain]}.loggly.com/api/inputs/#{node[:rsyslog][:loggly][:inputid]}/adddevice
    EOH
    only_if {node[:rsyslog][:loggly] &&
             node[:rsyslog][:loggly][:inputid] &&
             node[:rsyslog][:loggly][:port] &&
             node[:rsyslog][:loggly][:subdomain] &&
             node[:rsyslog][:loggly][:username] &&
             node[:rsyslog][:loggly][:password]}
end

service "rsyslog" do
  supports :restart => true
  action [:enable, :restart]
end
