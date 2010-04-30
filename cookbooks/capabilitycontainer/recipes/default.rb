bash "install-carrot" do
  user "root"
  code <<-EOH
  cd /home/#{node[:username]}
  git clone git://amoeba.ucsd.edu/carrot.git
  cd carrot
  git checkout -b txamqp origin/txamqp
  python setup.py install
  EOH
end


bash "install-carrot" do
  user "root"
  code <<-EOH
  cd /home/#{node[:username]}
  git clone git://amoeba.ucsd.edu/magnet.git
  cd magnet
  git checkout -b space origin/space
  python setup.py install
  EOH
end


bash "give-container-user-ownership" do
  user "root"
  code <<-EOH
  chown -R #{node[:username]}:#{node[:username]} /home/#{node[:username]}
  EOH
end


bash "start-capabilitycontainer" do
  user node[:username]
  code <<-EOH
  cd /home/#{node[:username]}/magnet
  twistd magnet -n -h #{node[:capabilitycontainer][:broker]} -b #{node[:capabilitycontainer][:bootscript]}
  EOH
end

