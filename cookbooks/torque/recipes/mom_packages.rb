#
# Cookbook Name:: torque
# Recipe:: mom
#

# we assume the Torque 2.5.5 packages are already built and in:
# /software/torque/
# packages are configure to install to /opt/torque-2.5.5

#include_recipe "torque::base"

bash "Install Torque Mom #{node[:torque][:service][:src_version]}" do
  cwd "/software/torque/"
  code <<-EOH
  /software/torque/torque-package-mom-* --install
  echo #{node[:torque][:torque_headnode_ip_address]} > /var/spool/torque/server_name
  #{node[:torque][:service][:location]}/sbin/pbs_mom
  EOH
end
