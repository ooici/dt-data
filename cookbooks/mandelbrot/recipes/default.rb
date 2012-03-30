execute "Configure meta file" do
  command "cat > /usr/local/src/ExperimentBuilder/meta <<EOF
amqp://#{node[:mandelbrot][:rabbitmq_username]}:#{node[:mandelbrot][:rabbitmq_password]}@#{node[:mandelbrot][:rabbitmq_host]}:5672/
SierraTes2
EOF"
end

execute "Run the worker process" do
  command "/usr/local/src/go.sh"
end
