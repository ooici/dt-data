#
# Author:: Benjamin Black (<b@b3k.us>)
# Cookbook Name:: cassandra
# Recipe:: default
#
# Copyright 2010, Benjamin Black
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

bash "add-cassandra-repo" do
  code <<-EOH
  echo "deb http://www.apache.org/dist/cassandra/debian unstable main" >> /etc/apt/sources.list
  echo "deb-src http://www.apache.org/dist/cassandra/debian unstable main" >> /etc/apt/sources.list
  gpg --keyserver wwwkeys.eu.pgp.net --recv-keys F758CE318D77295D
  gpg --export --armor F758CE318D77295D | sudo apt-key add -
  apt-get update
  EOH
end

package "openjdk-6-jdk" do
  action :install
end

package "cassandra" do
  action :install
end

service "cassandra" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

user "cassandra" do
  gid "nogroup"
  shell "/bin/false"
end

directory "/var/lib/cassandra" do
  owner "cassandra"
  group "root"
  mode "0775"
  action :create
end

directory "/var/lib/cassandra/saved_caches" do
  owner "cassandra"
  group "root"
  mode "0775"
  action :create
end

directory "/var/log/cassandra" do
  owner "cassandra"
  group "root"
  mode "0775"
  action :create
end

directory "/etc/cassandra" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  not_if "test -d /etc/cassandra"
end

template "/etc/cassandra/storage-conf.xml" do
  source "storage-conf.xml.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "cassandra")
end
