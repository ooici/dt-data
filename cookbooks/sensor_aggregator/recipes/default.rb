#Cookbook Name: sensor_aggregator

include_recipe "setuptools"
include_recipe "twisted"

package "rabbitmq-server" do
  action :install
end

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

bash "give-txrabbitmq-access-to-rabbitmq-erlang-cookie" do
  code <<-EOH
  cp /var/lib/rabbitmq/.erlang.cookie /home/#{node[:username]}/
  chown #{node[:username]}:#{node[:username]} /home/#{node[:username]}/.erlang.cookie
  EOH
end
