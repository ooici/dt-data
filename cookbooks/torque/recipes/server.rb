#
# Cookbook Name:: torque
# Recipe:: server
#

include_recipe "torque::base"

bash "Install and Configure Torque Server #{node[:torque][:service][:src_version]}" do
  cwd "/tmp/torque-#{node[:torque][:service][:src_version]}"
  code <<-EOH
  ./torque-package-clients-* --install
  ./torque-package-server-* --install
  ./torque-package-devel-* --install
  echo "localhost np=1" | tee -a /var/spool/torque/server_priv/nodes
  #{node[:torque][:service][:location]}/sbin/pbs_server -t create
  #{node[:torque][:service][:location]}/sbin/pbs_sched
  #{node[:torque][:service][:location]}/bin/qmgr -c "set server scheduling=true"
  #{node[:torque][:service][:location]}/bin/qmgr -c "create queue default queue_type=execution"
  #{node[:torque][:service][:location]}/bin/qmgr -c "set queue default started=true"
  #{node[:torque][:service][:location]}/bin/qmgr -c "set queue default enabled=true"
  #{node[:torque][:service][:location]}/bin/qmgr -c "set queue default resources_default.nodes=1"
  #{node[:torque][:service][:location]}/bin/qmgr -c "set queue default resources_default.walltime=3600"
  #{node[:torque][:service][:location]}/bin/qmgr -c "set server default_queue=default"
  #{node[:torque][:service][:location]}/bin/qmgr -c "set server scheduler_iteration=30"
  #{node[:torque][:service][:location]}/bin/qmgr -c "set server managers+=cc@*"
  EOH
end
