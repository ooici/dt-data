app_dir = node[:appdir]

include_recipe "git"
include_recipe "python"

case node[:platform]
when "debian", "ubuntu"
  %w{ apache2 libapache2-mod-wsgi }.each do |pkg|
      package pkg
  end
end

retrieve_method = node[:phantomweb][:retrieve_method]
src_dir = unpack_dir = "#{Dir.tmpdir}/PhantomWebApp"

if retrieve_method == "offline_archive"
  archive_path = "#{Dir.tmpdir}/PhantomWebApp-#{Time.now.to_i}.tar.gz"

  remote_file archive_path do
    source node[:phantomweb][:retrieve_config][:archive_url]
    owner node[:username]
    group node[:groupname]
  end

  directory unpack_dir do
    owner node[:username]
    group node[:groupname]
    mode "0755"
  end

  execute "unpack #{archive_path} into #{unpack_dir}" do
    user node[:username]
    group node[:groupname]
    command "tar xzf #{archive_path} -C #{unpack_dir}"
  end

  execute "copy PhantomWebApp repository" do
    user node[:username]
    group node[:groupname]
    command "cp -R #{unpack_dir}/PhantomWebApp #{app_dir}"
  end
else
  git app_dir do
    repository node[:phantomweb][:git_repo]
    reference node[:phantomweb][:git_branch]
    action :sync
    user node[:username]
    group node[:groupname]
  end
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

install_method = node[:phantomweb][:install_method]

if node[:phantomweb][:install_config][:extras] and node[:phantomweb][:install_config][:extras].length > 0
  extras = node[app][:install_config][:extras].join(",")
  extras = "[#{extras}]"
else
  extras = ""
end

if install_method == "py_venv_offline_setup"
  execute "Install newer pip" do
    # The version of pip included in python-pip on our VM doesn't work with
    # package directories created by pip2pi
    command "pip install pip"
  end

  execute "run install" do
    cwd app_dir
    command "env >/tmp/env ; pip install --index-url=file://#{unpack_dir}/packages/simple/ .#{extras}"
  end
  execute "install-supervisor" do
    cwd app_dir
    command "pip install --index-url=file://#{unpack_dir}/packages/simple supervisor"
  end
else
  execute "run install" do
      cwd app_dir
      user "root"
      group "root"
      command "python setup.py install"
  end
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
    owner "root"
    group "root"
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
