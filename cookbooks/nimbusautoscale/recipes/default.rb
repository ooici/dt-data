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

retrieve_method = node[:autoscale][:retrieve_method]
src_dir = unpack_dir = "#{Dir.tmpdir}/Phantom"

directory app_dir do
  owner node[:username]
  group node[:groupname]
end

directory "#{app_dir}/logs" do
  owner node[:username]
  group node[:groupname]
end

if retrieve_method == "offline_archive"
  archive_path = "#{Dir.tmpdir}/Phantom-#{Time.now.to_i}.tar.gz"

  remote_file archive_path do
    source node[:autoscale][:retrieve_config][:archive_url]
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

  execute "Synchronize Phantom sandbox repository" do
    user node[:username]
    group node[:groupname]
    command "rm -rf #{app_dir}/sandbox && cp -R #{unpack_dir}/Phantom/sandbox #{app_dir}/sandbox"
  end
else
  git app_dir do
    repository node[:autoscale][:git_repo]
    reference node[:autoscale][:git_branch]
    action :sync
    user node[:username]
    group node[:groupname]
  end
end

install_method = node[:autoscale][:install_method]

if install_method == "py_venv_offline_setup"
  execute "run install" do
    cwd src_dir
    user node[:username]
    group node[:groupname]
     environment({
       "HOME" => "/home/#{node[:username]}"
     })
    command "env >/tmp/env ; pip install -r ./Phantom/requirements.txt --index-url=file://`pwd`/packages/simple/ ./Phantom"
  end
  execute "install-supervisor" do
    cwd src_dir
    user node[:username]
    group node[:groupname]
     environment({
       "HOME" => "/home/#{node[:username]}"
     })
    command "pip install --index-url=file://`pwd`/packages/simple supervisor"
  end
else
  execute "run install" do
    cwd app_dir
    user node[:username]
    group node[:groupname]
    command "python setup.py install"
  end
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
