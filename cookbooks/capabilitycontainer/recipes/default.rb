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


bash "start-capabilitycontainer" do
  user node[:username]
  code <<-EOH
  cd /home/#{node[:username]}/lcaarch
  twistd magnet -n -h #{node[:capabilitycontainer][:broker]} -a sysname=#{node[:capabilitycontainer][:sysname]} #{node[:capabilitycontainer][:bootscript]}
  EOH
end

