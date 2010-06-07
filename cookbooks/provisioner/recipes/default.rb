#Cookbook Name: provisioner

bash "install-nimboss" do
  code <<-EOH
  cd /home/#{node[:username]}
  git clone http://github.com/clemesha-ooi/nimboss.git
  cd nimboss
  python setup.py install
  EOH
end

