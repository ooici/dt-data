#Cookbook Name: rabbitmq_cookie

bash "copy-rabbitmq-erlang-cookie" do
  code <<-EOH
  cp /var/lib/rabbitmq/.erlang.cookie /home/#{node[:username]}/
  chown #{node[:username]}:#{node[:groupname]} /home/#{node[:username]}/.erlang.cookie
  EOH
end
