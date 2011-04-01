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

if node[:rabbitmq].include? :users and not node[:rabbitmq][:users].empty?

  execute "Remove default guest user" do
    returns [0,2] # if the guest user doesn't exist, that's ok
    command "rabbitmqctl -q delete_user guest"
  end

  node[:rabbitmq][:users].each do |username, password|
    execute "Add user #{username}" do
      command "rabbitmqctl -q add_user #{username} #{password}"
    end
  end
end
