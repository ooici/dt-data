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
  not_if "test -f /etc/apt/sources.list.d/apache.list"
  code <<-EOH
  echo "deb http://www.apache.org/dist/cassandra/debian unstable main" >> /etc/apt/sources.list.d/apache.list
  echo "deb-src http://www.apache.org/dist/cassandra/debian unstable main" >> /etc/apt/sources.list.d/apache.list
  gpg --keyserver pgp.mit.edu --recv-keys F758CE318D77295D
  gpg --export --armor F758CE318D77295D | sudo apt-key add -
  apt-get update
  EOH
end

package "openjdk-6-jdk" do
  action :install
end

package "cassandra" do
  action :install
  version node[:cassandra][:version]
end

service "cassandra" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

user "cassandra" do
  gid "nogroup"
  shell "/bin/false"
end

template "/etc/cassandra/cassandra.yaml" do
  source "cassandra.yaml.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "cassandra")
end

template "/etc/cassandra/passwd.properties" do
  source "passwd.properties.erb"
  owner "cassandra"
  group "cassandra"
  mode 0600
  notifies :restart, resources(:service => "cassandra")
end

bash "add-cassandra-system-property" do
  not_if "grep passwd.properties /etc/cassandra-env.sh"
  code <<-EOH
  echo 'JVM_OPTS="$JVM_OPTS -Dpasswd.properties=/etc/cassandra/passwd.properties"' >> /etc/cassandra/cassandra-env.sh
  EOH
end
