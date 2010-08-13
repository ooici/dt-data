#Cookbook Name: sensor_aggregator

include_recipe "setuptools"
include_recipe "twisted"

bash "install-twotp" do
  user "root"
  code "easy_install twotp"
end

bash "install-txrabbitmq" do
  code <<-EOH
  cd /home/#{node[:username]}
  git clone http://github.com/clemesha-ooi/txrabbitmq.git
  cd txrabbitmq
  python setup.py install
  EOH
end
