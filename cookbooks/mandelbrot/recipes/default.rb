execute "Configure meta file" do
  command "cat <<EOF
amqp://#{node[:mandelbrot][:rabbitmq_username]}:#{node[:mandelbrot][:rabbitmq_password]}@#{node[:mandelbrot][:rabbitmq_host]}:5672/
SierraTes2
EOF > /usr/local/src/ExperimentBuilder"
end

execute "Run the worker process" do
  command "/usr/local/src/go.sh"
end
