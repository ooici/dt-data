template "/opt/bigcouch/etc/local.ini" do
  owner "bigcouch"
  mode "600"
  source "local.ini.erb"
end

service "bigcouch" do
  action :restart
end
