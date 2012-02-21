case node[:platform]
  when "debian","ubuntu"
#TODO: Causes problems on vagrant
#    execute "update package index" do
#      command "apt-get update"
#      action :run
#    end
    package "hadoop-zookeeper-server" do
      action :install
    end
end

service "hadoop-zookeeper-server" do                                                          
  supports :status => true, :restart => true, :reload => true                   
  action [ :enable, :start ]                                                    
end    
