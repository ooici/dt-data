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

  java_home = ""

when "redhat","centos"
  %w{ java-1.6.0-openjdk ant sqlite }.each do |pkg|
    package pkg
  end
  java_home = "/usr/lib/jvm/java-1.6.0"
end

remote_file "/tmp/hbase-0.95-SNAPSHOT.tar.gz" do
  source node[:hbase][:source]
end

script "Extract HBase" do
  interpreter "bash"
  code <<-EOH
  tar xzvf /tmp/hbase-0.95-SNAPSHOT.tar.gz
  mv hbase* hbase
  EOH
  cwd "/opt"
end

template "/opt/hbase/conf/hbase-site.xml" do
  source "hbase-site.xml.erb"
end

script "Start HBase" do
  interpreter "bash"
  environment ({"JAVA_HOME" => java_home})
  code <<-EOH
  ./bin/start-hbase.sh
  EOH
  cwd "/opt/hbase/"
end
