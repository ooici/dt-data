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

service "zookeeper" do                                                          
  supports :status => true, :restart => true, :reload => true                   
  action [ :enable, :start ]                                                    
end    
