execute "Enable RabbitMQ Management Plugin" do
  command "rabbitmq-plugins enable rabbitmq_management"
end

# Restart rabbit for older versions of rabbit
service "rabbitmq-server" do
  supports :restart => true
  action :restart
end
