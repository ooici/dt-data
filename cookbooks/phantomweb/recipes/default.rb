app_dir = node[:appdir]

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

exe = File.join(app_dir, "phantomweb/settings.py")
template exe do
    source "settings.py.erb"
    owner node[:username]
    group node[:groupname]
    mode 0755
end

logdir = node[:phantomweb][:logdir]
directory logdir do
  owner node[:phantomweb][:apacheuser]
  group node[:phantomweb][:apachegroup]
  mode "0777"
  action :create
end

execute "run install" do
    cwd app_dir
    user "root"
    group "root"
    command "python setup.py install"
end

execute "syncdb" do
    cwd app_dir
    user "root"
    group "root"
    command "python manage.py syncdb --noinput"
end
execute "collect static" do
    cwd app_dir
    user "root"
    group "root"
    command "python manage.py collectstatic --noinput"
end

conf = File.join(app_dir, "fixture.json")
template conf do
    source "fixture.json.erb"
    owner node[:username]
    group node[:groupname]
    mode 0644
    action :create
end
execute "do fixtures" do
    cwd app_dir
    user "root"
    group "root"
    command "python manage.py loaddata #{conf}"
end


conf = "/etc/apache2/httpd.conf"
template conf do
    source "httpd.conf.erb"
    owner node[:username]
    group node[:groupname]
    mode 0644
    action :create
end

execute "remove logs" do
    cwd logdir
    user "root"
    group "root"
    command "rm -f #{logdir}/*"
end

execute "restart apache2" do
    cwd app_dir
    user "root"
    group "root"
    command "/etc/init.d/apache2 restart"
end

