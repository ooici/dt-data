#
# Cookbook Name:: contextbroker
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
  if [ -f #{node[:contextbroker][:location]}/bin/brokerctl ]; then #{node[:contextbroker][:location]}/bin/brokerctl stop; fi
  rm -rf #{node[:contextbroker][:location]}
  EOH
end

group node[:contextbroker][:group] do
end

user node[:contextbroker][:user] do
  home "/home/#{node[:contextbroker][:user]}"
  gid node[:contextbroker][:group]
end

directory node[:contextbroker][:location] do
  owner node[:contextbroker][:user]
  group node[:contextbroker][:group]
  mode 0755
end

# hitting this bug when using java recipe from opscode:
# http://tickets.opscode.com/browse/OHAI-234
# using our own package list for now

#include_recipe "java"

case node[:platform]
when "debian","ubuntu"
  include_recipe "apt"

  execute "enable oracle java ppa" do
      command "add-apt-repository -y ppa:webupd8team/java"
      action :run
  end

  execute "force update apt" do
      command "apt-get update"
      action :run
  end

  %w{ ant sqlite3 oracle-java7-installer uuid-runtime }.each do |pkg|
    package pkg
  end

when "redhat","centos"
  %w{ java-1.6.0-openjdk ant sqlite }.each do |pkg|
    package pkg
  end
end

tarball_location = "#{Chef::Config[:file_cache_path]}/#{node[:contextbroker][:src_name]}"

directory "#{Chef::Config[:file_cache_path]}" do
end

remote_file tarball_location do
  checksum node[:contextbroker][:checksum]
  retries node[:contextbroker][:download_retries]
  source node[:contextbroker][:src_mirror]
  user node[:contextbroker][:user]
  group node[:contextbroker][:group]
end

bash "Install Context Broker #{node[:contextbroker][:src_version]}" do
  cwd "/tmp"
  user node[:contextbroker][:user]
  group node[:contextbroker][:group]
  code <<-EOH
  rm -rf nimbus-ctxbroker-#{node[:contextbroker][:src_version]}-src
  tar xf #{tarball_location}
  cd nimbus-ctxbroker-#{node[:contextbroker][:src_version]}-src
  yes '' | ./install #{node[:contextbroker][:location]}
  EOH
  creates "#{node[:contextbroker][:location]}/bin/brokerctl"
end

case node[:cloud][:provider]
when "ec2"
  fqdn = node[:ec2][:public_hostname]
else
  fqdn = node[:fqdn]
end

bash "Set Context Broker hostname to #{fqdn}" do
  cwd node[:contextbroker][:location]
  user node[:contextbroker][:user]
  group node[:contextbroker][:group]
  code <<-EOH
  #{node[:contextbroker][:location]}/bin/broker-configure -H #{fqdn}
  EOH
end

template File.join(node[:contextbroker][:location], "services", "etc", "nimbus-context-broker", "user-mapfile") do
    source "user-mapfile.erb"
    mode 0644
    owner node[:contextbroker][:user]
    group node[:contextbroker][:group]
    variables(:users => node[:contextbroker][:users])
end

context_broker_init = File.join("", "etc", "init.d", "contextbroker")
template context_broker_init do
  source "contextbroker.erb"
  mode 0755
  owner node[:contextbroker][:user]
  group node[:contextbroker][:group]
  variables(:user => node[:contextbroker][:user], :init_path => "#{node[:contextbroker][:location]}/bin/brokerctl")
end

service "contextbroker" do
  supports [ :start, :stop, :status, :restart ]
  action [ :restart ]
end

