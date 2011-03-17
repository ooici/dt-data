package "rabbitmq-server" do
  action :install
end

service "rabbitmq-server" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

template "/etc/rabbitmq/rabbitmq.conf" do
  source "rabbitmq.config.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "rabbitmq-server"), :immediately
end
