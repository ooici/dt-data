
tarball_location = "#{Chef::Config[:file_cache_path]}/#{node[:hsflowd][:src_name]}"

directory "#{Chef::Config[:file_cache_path]}" do
end

remote_file tarball_location do
  checksum node[:hsflowd][:checksum]
  source node[:hsflowd][:src_tarball_url]
end

bash "Install Host sFlow #{node[:hsflowd][:src_version]}" do
  cwd "/tmp"
  code <<-EOH
  rm -rf hsflowd-#{node[:hsflowd][:src_version]}
  tar xf #{tarball_location}
  cd hsflowd-#{node[:contextbroker][:src_version]}
  make
  make install
  EOH
  creates "/usr/sbin/hsflowd"
end

template node[:hsflowd][:config_file] do
  source "hsflowd.conf.erb"
  mode "0644"
end

service "hsflowd" do
  supports :restart => true
  action [:enable, :restart]
end
