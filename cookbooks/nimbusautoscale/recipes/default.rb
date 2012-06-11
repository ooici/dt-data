app_dir = node[:appdir]
ve_dir = node[:virtualenv][:path]

include_recipe "git"
include_recipe "python"
include_recipe "virtualenv"

[ :create, :activate ].each do |act|
  virtualenv ve_dir do
    owner node[:username]
    group node[:groupname]
    python node[:virtualenv][:python]
    virtualenv node[:virtualenv][:virtualenv]
    action act
  end
end

case node[:platform]
when "debian", "ubuntu"
  %w{ libmysqlclient-dev python-dev }.each do |pkg|
      package pkg
  end
end

git app_dir do
  repository node[:autoscale][:git_repo]
  reference node[:autoscale][:git_branch]
  action :sync
  user node[:username]
  group node[:groupname]
end

execute "run install" do
    cwd app_dir
    user node[:username]
    group node[:groupname]
    command "python setup.py install"
end

conf = File.join(app_dir, "phantomautoscale.yml")
template conf do
    source "config.yml.erb"
    owner node[:username]
    group node[:groupname]
    mode 0644
    action :create
end

exe = File.join(app_dir, "start-phantom.sh")
template exe do
    source "start_phantom.sh.erb"
    owner node[:username]
    group node[:groupname]
    mode 0755
end
