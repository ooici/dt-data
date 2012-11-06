
template node[:hsflowd][:config_file] do
  source "hsflowd.conf.erb"
  mode "0644"
  only_if "which hsflowd"
end

service "hsflowd" do
  supports :restart => true
  action [:enable, :restart]
  only_if "which hsflowd"
end

