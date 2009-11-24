package "nginx" do
  action :install
end

template "/etc/nginx/nginx.conf" do
  source "nginx.conf.erb"
  variables({
    :public_hostname => @node[:ec2][:public_hostname],
    :webapp_port => @node[:webapp_port],
    :webapps => @node[:webapp_ips]
  })
end

service "nginx" do
  action :restart
end
