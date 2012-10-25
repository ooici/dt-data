template node[:hsflowd][:config_file] do
  source "hsflowd.conf.erb"
  mode "0644"
end

service "hsflowd" do
  supports :restart => true
  action [:enable, :restart]
end

