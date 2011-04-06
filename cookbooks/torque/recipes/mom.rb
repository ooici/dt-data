#
# Cookbook Name:: torque
# Recipe:: mom
#

bash "Install Torque Mom #{node[:torque][:service][:src_version]}" do
  cwd "/tmp/torque-#{node[:torque][:service][:src_version]}"
  code <<-EOH
  ./torque-package-mom-* --install
  echo #{node[:torque][:torque_headnode_ip_address]} > /var/spool/torque/server_name
  #{node[:torque][:service][:location]}/sbin/pbs_mom
  EOH
end
