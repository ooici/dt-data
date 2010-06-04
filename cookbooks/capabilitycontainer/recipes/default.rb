bash "install-carrot" do
  code <<-EOH
  cd /home/#{node[:username]}
  git clone git://amoeba.ucsd.edu/carrot.git
  cd carrot
  git checkout -b txamqp origin/txamqp
  python setup.py install
  EOH
end


bash "install-magnet" do
  code <<-EOH
  cd /home/#{node[:username]}
  git clone git://amoeba.ucsd.edu/magnet.git
  cd magnet
  python setup.py install
  EOH
end

bash "install-lcaarch" do
  code <<-EOH
  cd /home/#{node[:username]}
  git clone http://github.com/clemesha-ooi/lcaarch.git
  cd lcaarch
  git checkout #{node[:capabilitycontainer][:lcaarch_branch]}
  git fetch
  git reset --hard #{node[:capabilitycontainer][:lcaarch_commit_hash]}
  EOH
end


bash "give-container-user-ownership" do
  code <<-EOH
  chown -R #{node[:username]}:#{node[:username]} /home/#{node[:username]}
  EOH
end

node[:services].each do |service, service_spec|

  service_config = "/home/#{node[:username]}/lcaarch/res/config/#{service}-ionservices.cfg"

  template "#{service_config}" do
    source "ionservices.cfg.erb"
    owner "#{node[:username]}"
    variables(:service_spec => service_spec)
  end

  bash "start-service" do
    user node[:username]
    code <<-EOH
    cd /home/#{node[:username]}/lcaarch
    twistd --pidfile=#{service}-service.pid --logfile=#{service}-service.log magnet -n -h #{node[:capabilitycontainer][:broker]} -a processes=#{service_config},sysname=#{node[:capabilitycontainer][:sysname]} #{node[:capabilitycontainer][:bootscript]}
    EOH
  end

end





