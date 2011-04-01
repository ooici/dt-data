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

if node[:rabbitmq].include? :vhosts
  node[:rabbitmq][:vhosts].each do |vhost|
    execute "Add vhost #{vhost}" do
      return [0,2] # ok if vhost already exists
      command "rabbitmqctl -q add_vhost #{vhost}"
    end
  end
end

if node[:rabbitmq].include? :users and not node[:rabbitmq][:users].empty?

  execute "Remove default guest user" do
    returns [0,2] # if the guest user doesn't exist, that's ok
    command "rabbitmqctl -q delete_user guest"
  end

  node[:rabbitmq][:users].each do |username, spec|
    execute "Add user #{username}" do
      command "rabbitmqctl -q add_user #{username} #{spec[:password]}"
    end
    
    if spec.include? :permissions
      spec[:permissions].each do |vhost, perms|
        execute "Set permissions for user=#{username} vhost=#{vhost}" do
          command "rabbitmqctl -q set_permissions -p #{vhost} #{username} "+
            "'#{perms[:conf]}' '#{perms[:write]}' '#{perms[:read]}'"
        end
      end
    end
  end
end
