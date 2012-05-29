#
# Cookbook Name:: epu
# Recipe:: default
#
# Copyright 2012, University of Chicago
#

require 'tmpdir'

user node[:epu][:username] do
    comment "Dynamically created user."
    gid "#{node[:epu][:groupname]}"
    home "/home/#{node[:epu][:username]}"
    shell "/bin/bash"
    supports :manage_home => true
end

include_recipe "python"

ve_exe = node[:epu][:virtualenv][:virtualenv]
py_exe = node[:epu][:virtualenv][:python]
ve_dir = node[:epu][:virtualenv][:path]

case node[:platform]
  when "debian","ubuntu"
    execute "update package index" do
      command "apt-get update"
      action :run
    end
    package "python-virtualenv" do
      action :install
    end
end

execute "create virtualenv" do
  user node[:epu][:username]
  group node[:epu][:groupname]
  creates File.join(ve_dir, "bin/activate")
  command "#{ve_exe} --python=#{py_exe} #{ve_dir}"
end

ruby_block "set virtualenv environment variables" do
  block do
    ENV["VIRTUAL_ENV"] = ve_dir
    ENV["PATH"] = File.join(ve_dir, "bin") + ":" + ENV["PATH"]
  end
  not_if {ENV["VIRTUAL_ENV"] == ve_dir}
end

# Other dependencies
%w{ libevent-dev libncurses5-dev libzmq-dev swig }.each do |pkg|
  package pkg
end

src_dir = "#{Dir.tmpdir}/epu"

if node[:epu][:action].include?("retrieve")
  case node[:epu][:retrieve_config][:retrieve_method]
  when "git"
    include_recipe "git"

    git src_dir do
      repository node[:epu][:retrieve_config][:git_repo]
      reference node[:epu][:retrieve_config][:git_reference]
      action :sync
      user node[:epu][:username]
      group node[:epu][:groupname]
    end
  else
    abort "retrieve_method #{node[:epu][:retrieve_config][:retrieve_method]} not implemented yet"
  end
end

if node[:epu][:action].include?("install")
  case node[:epu][:install_config][:install_method]
  when "py_venv_setup"
    execute "run install" do
      cwd src_dir
      user node[:epu][:username]
      group node[:epu][:groupname]
      command "env >/tmp/env ; python setup.py install"
    end
    execute "install-supervisor" do
      user node[:epu][:username]
      group node[:epu][:groupname]
      command "easy_install --find-links=#{node[:epu][:install_config][:package_repo]} supervisor"
    end
  else
    abort "install_method #{node[:epu][:install_config][:install_method]} not implemented yet"
  end
end

if node[:epu][:action].include?("run")
  # Create run directory
  run_dir = node[:epu][:run_config][:run_directory]

  # Create run directory
  directory run_dir do
    owner node[:epu][:username]
    group node[:epu][:groupname]
  end

  # autorestart is for all processes right now, could be made more
  # granular if needed. Also note that it only applies in "supervised" mode.
  autorestart = node[:epu][:run_config].fetch("autorestart", false)

  # Name of the service
  epuservice_name = node[:epu][:run_config][:program]

  # Configuration file for this service
  epu_config_file = File.join(run_dir, "#{epuservice_name}.yml")

  epu_config epu_config_file do
    user node[:epu][:username]
    group node[:epu][:groupname]
    epuservice_name epuservice_name
    epuservice_spec node[:epu][:run_config][:config]
  end

  base_logging_dir = "#{run_dir}/logs"
  directory "#{base_logging_dir}" do
    owner "#{node[:epu][:username]}"
    group "#{node[:epu][:groupname]}"
    mode "0755"
  end

  start_script = File.join(run_dir, "start-#{epuservice_name}.sh")
  template start_script do
    source "start-service.sh.erb"
    owner node[:epu][:username]
    group node[:epu][:groupname]
    mode 0755
    variables(:service => epuservice_name,
              :service_config => epu_config_file,
              :venv_dir => ve_dir,
              :run_dir => run_dir,
              :background_process => node[:epu][:run_config][:run_method] == "sh"
             )
  end

  # add command to services list
  epuservice = {
    :program => epuservice_name,
    :command => start_script,
    :autorestart => autorestart
  }

  case node[:epu][:run_config][:run_method]
  when "supervised"
    sup_conf = File.join(run_dir, "supervisor.conf")
    template sup_conf do
      source "supervisor.conf.erb"
      mode 0400
      owner node[:epu][:username]
      group node[:epu][:groupname]
      variables(:epuservice => epuservice)
    end

    bash "start-supervisor" do
      user node[:epu][:username]
      group node[:epu][:groupname]
      environment({
        "HOME" => "/home/#{node[:epu][:username]}"
      })
      code <<-EOH
      supervisord -c #{sup_conf}
      EOH
    end

=begin
    # start up the monitor process, if configured
    if node.include? :appmonitor
      app_monitor monitor_dir do
        conf node[:appmonitor]
        user node[:epu][:username]
        group node[:epu][:groupname]
        virtualenv ve_dir
        supervisor_socket "unix://" + File.join(run_dir, "supervisor.sock")
      end
    end
=end

  else
    abort "run_method #{node[:epu][:run_config][:run_method]} not implemented yet"
  end
end
