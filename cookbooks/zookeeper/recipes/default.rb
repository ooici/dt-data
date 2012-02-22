case node[:platform]
  when "debian","ubuntu"
    execute "update package index" do
      command "apt-get update"
      action :run
    end
    package "zookeeperd" do
      action :install
    end
end

template "/etc/zookeeper/conf/zoo.cfg" do
    source "zoo.cfg.erb"
end

# Template for replicated zookeeper servers
template "#{node[:zookeeper][:dataDir]}/myid" do
    source "myid.erb"
    variables(
        :myid => node[:zookeeper][:name].split("-")[1]
    )
    only_if { node[:zookeeper][:name].split("-")[1] }
end

service "zookeeper" do                                                          
  supports :status => true, :restart => true, :reload => true                   
  action [ :enable, :start ]                                                    
end    
