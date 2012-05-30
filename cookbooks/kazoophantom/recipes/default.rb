include_recipe "python"
include_recipe "virtualenv"

execute "install kazoo deps" do
  user node[:username]
  group node[:groupname]
  command "easy_install zc-zookeeper-static"
end

execute "install kazoo" do
  user node[:username]
  group node[:groupname]
  command "pip install -e 'git+git://github.com/nimbusproject/kazoo.git#egg=kazoo'"
end
