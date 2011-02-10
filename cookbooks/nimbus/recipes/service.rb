#
# Cookbook Name:: nimbus
# Recipe:: service
#
# Copyright 2010, Example Com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

bash "Cleanup /nimbus" do
  code <<-EOH
  if [ -f #{node[:nimbus][:service][:location]}/bin/nimbusctl ]; then #{node[:nimbus][:service][:location]}/bin/nimbusctl stop; fi
  rm -rf /tmp/nimbus_install
  rm -rf #{node[:nimbus][:service][:location]}
  EOH
end

group node[:nimbus][:service][:group] do
end

user node[:nimbus][:service][:user] do
  gid node[:nimbus][:service][:group]
  home node[:nimbus][:service][:location]
end

directory "/tmp/nimbus_install" do
  owner node[:nimbus][:service][:user]
  group node[:nimbus][:service][:group]
  mode 0755
end

link node[:nimbus][:service][:location] do
  to "/tmp/nimbus_install"
end

# hitting this bug when using java recipe from opscode:
# http://tickets.opscode.com/browse/OHAI-234
# using our own package list for now

#include_recipe "java"

case node[:platform]
when "debian","ubuntu"
  include_recipe "apt"
  %w{ ant sqlite3 default-jre default-jdk uuid-runtime }.each do |pkg|
    package pkg
  end
end

remote_file "#{Chef::Config[:file_cache_path]}/#{node[:nimbus][:service][:src_name]}" do
  checksum node[:nimbus][:service][:src_checksum]
  source node[:nimbus][:service][:src_mirror]
  owner node[:nimbus][:service][:user]
  group node[:nimbus][:service][:group]
end

bash "Install Nimbus #{node[:nimbus][:service][:src_version]}" do
  cwd "/tmp"
  user node[:nimbus][:service][:user]
  group node[:nimbus][:service][:group]
  code <<-EOH
  rm -rf nimbus-#{node[:nimbus][:service][:src_version]}-src
  tar -xzf #{Chef::Config[:file_cache_path]}/#{node[:nimbus][:service][:src_name]}
  cd nimbus-#{node[:nimbus][:service][:src_version]}-src
  yes '' | ./install #{node[:nimbus][:service][:location]}
  EOH
  creates "#{node[:nimbus][:service][:location]}/bin/nimbusctl"
end

case node[:cloud][:provider]
when "ec2"
  fqdn = node[:ec2][:public_hostname]
else
  fqdn = node[:fqdn]
end

bash "Set Nimbus hostname to #{fqdn}" do
  cwd node[:nimbus][:service][:location]
  user node[:nimbus][:service][:user]
  group node[:nimbus][:service][:group]
  code <<-EOH
  #{node[:nimbus][:service][:location]}/bin/nimbus-configure -H #{fqdn}
  EOH
end

node[:nimbus][:users].each do |name, user|
  bash "Create #{name} user" do
    cwd node[:nimbus][:service][:location]
    user node[:nimbus][:service][:user]
    group node[:nimbus][:service][:group]

    # don't create user if it already exists
    not_if "#{node[:nimbus][:service][:location]}/bin/nimbus-edit-user #{name}"
    code <<-EOH
    bin/nimbus-new-user -s "#{name}" -a "#{user[:access_id]}" -p "#{user[:secret]}" -P "#{name}"
    EOH
  end
end

service "workspace_service" do
  start_command "su #{node[:nimbus][:service][:user]} sh -c '#{node[:nimbus][:service][:location]}/bin/nimbusctl start'"
  stop_command "su #{node[:nimbus][:service][:user]} sh -c '#{node[:nimbus][:service][:location]}/bin/nimbusctl stop'"
  status_command "su #{node[:nimbus][:service][:user]} sh -c '#{node[:nimbus][:service][:location]}/bin/nimbusctl status'"
  restart_command "su #{node[:nimbus][:service][:user]} sh -c '#{node[:nimbus][:service][:location]}/bin/nimbusctl restart'"
  supports [ :start, :stop, :status, :restart ]
  action [ :restart ]
end
