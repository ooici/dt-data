service_name = nil
case node[:platform]
  when "debian","ubuntu"
    package "zookeeperd" do
      action :install
    end

    service_name = "zookeeper"

  when "redhat","centos"
    yum_key "RPM-GPG-KEY-cloudera" do
      url "http://archive.cloudera.com/cdh4/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera"
      action :add
    end

    yum_repository "cloudera-cdh4" do
      description "Cloudera"
      url "http://archive.cloudera.com/cdh4/redhat/6/x86_64/cdh/4/"
      key "RPM-GPG-KEY-cloudera"
      action :add
    end

    package "zookeeper-server"

    service_name = "zookeeper-server"
end

template "/etc/zookeeper/conf/zoo.cfg" do
    source "zoo.cfg.erb"
    mode 0755
end

# Template for replicated zookeeper servers
template "#{node[:zookeeper][:dataDir]}/myid" do
    source "myid.erb"
    variables(
        :myid => node[:zookeeper][:name].split("-")[1]
    )
    only_if { node[:zookeeper][:name].split("-")[1] }
end

case node[:platform]
  when "redhat","centos"
    execute "/etc/init.d/zookeeper-server init"
end

service service_name do
  supports :status => true, :restart => true, :reload => true                   
  action [ :enable, :restart ]                                                    
end    
