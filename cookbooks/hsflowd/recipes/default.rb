
tarball_location = "#{Chef::Config[:file_cache_path]}/#{node[:hsflowd][:src_name]}"
hsflow_source_path = "/tmp/hsflowd-#{node[:hsflowd][:src_version]}"

directory "#{Chef::Config[:file_cache_path]}" do
end


if node[:hsflowd][:svn_repository]
  package "subversion" do
    action :install
  end

  subversion "Get latest Host sFlow" do
    repository node[:hsflowd][:svn_repository]
    revision "HEAD"
    destination hsflow_source_path
    action :sync
  end

else
  remote_file tarball_location do
    checksum node[:hsflowd][:checksum]
    source node[:hsflowd][:src_tarball_url]
  end

  bash "Untar Host sFlow #{node[:hsflowd][:src_version]}" do
    cwd "/tmp"
    code <<-EOH
    rm -rf hsflowd-#{node[:hsflowd][:src_version]}
    tar xf #{tarball_location}
    EOH
  end
end

node[:hsflowd][:patches].each do |patch|
  patch_path = File.join(hsflow_source_path, "hsflow.patch")
  remote_file patch_path do
    source patch
  end
  bash "Apply patch from #{patch}" do
    cwd hsflow_source_path
    code <<-EOH
    patch -p0 -i #{patch_path}
    EOH
  end
end

bash "Install Host sFlow #{node[:hsflowd][:src_version]}" do
  cwd "/tmp"
  code <<-EOH
  cd hsflowd-#{node[:hsflowd][:src_version]}
  make
  make install
  EOH
  if node[:hsflowd][:force_install]
    creates "/usr/sbin/hsflowd"
  end
end

template node[:hsflowd][:config_file] do
  source "hsflowd.conf.erb"
  mode "0644"
end

service "hsflowd" do
  supports :restart => true
  action [:enable, :restart]
end
