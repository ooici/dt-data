include_recipe "python"
include_recipe "virtualenv"
include_recipe "git"

case node[:platform]
  when "debian","ubuntu"
    package "python-zookeeper" do
      action :install
    end
end

user node[:kazoo][:username] do
    comment "Dynamically created user."
    gid "#{node[:kazoo][:groupname]}"
    home "/home/#{node[:kazoo][:username]}"
    shell "/bin/bash"
    supports :manage_home => true
end

[ :create, :activate ].each do |act|
  virtualenv node[:kazoo][:virtualenv][:path] do
    owner node[:kazoo][:username]
    group node[:kazoo][:groupname]
    python node[:kazoo][:virtualenv][:python]
    virtualenv node[:kazoo][:virtualenv][:virtualenv]
    action act
  end
end

execute "install kazoo" do
  user node[:kazoo][:username]
  group node[:kazoo][:groupname]
  command "pip install -e 'git+git://github.com/nimbusproject/kazoo.git#egg=kazoo'"
end
