#
# Cookbook Name:: torque
# Recipe:: base
#

case node[:platform]
when "debian","ubuntu"
  include_recipe "apt"
  %w{ build-essential }.each do |pkg|
    package pkg
  end
end

remote_file "/tmp/#{node[:torque][:service][:src_name]}" do
  source node[:torque][:service][:src_mirror]
end

bash "Download and Build Torque #{node[:torque][:service][:src_version]}" do
  cwd "/tmp"
  code <<-EOH
  rm -rf torque-#{node[:torque][:service][:src_version]}
  tar -xzf /tmp/#{node[:torque][:service][:src_name]}
  cd torque-#{node[:torque][:service][:src_version]}
  ./configure --prefix=#{node[:torque][:service][:location]} --disable-gui --with-scp --disable-gcc-warnings
  make -j4
  make packages
  EOH
end
