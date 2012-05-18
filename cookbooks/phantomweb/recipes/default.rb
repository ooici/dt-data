app_dir = node[:appdir]
venv_dir = node[:virtualenv][:path]

include_recipe "git"

case node[:platform]
when "debian", "ubuntu"
  execute "apt-get update" do
    command "apt-get update"
  end

  %w{ apache2 libapache2-mod-wsgi }.each do |pkg|
      package pkg
  end
end

git app_dir do
  repository node[:phantomweb][:git_repo]
  reference node[:phantomweb][:git_branch]
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

conf = "/etc/apache2/httpd.conf"
template conf do
    source "httpd.conf.erb"
    owner node[:username]
    group node[:groupname]
    mode 0644
    action :create
end

exe = File.join(venv_dir, "bin/venvdjango.py")
template exe do
    source "venvdjango.py.erb"
    owner node[:username]
    group node[:groupname]
    mode 0755
end

exe = File.join(app_dir, "phantomweb/settings.py")
template exe do
    source "settings.py.erb"
    owner node[:username]
    group node[:groupname]
    mode 0755
end

execute "restart apache2" do
    cwd app_dir
    user "root"
    group "root"
    command "/etc/init.d/apache2 restart"
end

