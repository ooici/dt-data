include_recipe "python"
include_recipe "virtualenv"

case node[:platform]
  when "debian","ubuntu"
    package "python-zookeeper" do
      action :install
    end
end

execute "install kazoo" do
  user node[:username]
  group node[:groupname]
  command "pip install -e 'git+git://github.com/nimbusproject/kazoo.git#egg=kazoo'"
end
