#
# Cookbook Name:: epu
# Recipe:: default
#
# Copyright 2012, University of Chicago
#

require 'tmpdir'

[ :epu, :epuagent, :pyon ].each do |app|

  next if node[app].nil?

  user node[app][:username] do
      comment "Dynamically created user."
      gid "#{node[app][:groupname]}"
      home "/home/#{node[app][:username]}"
      shell "/bin/bash"
      supports :manage_home => true
  end

  include_recipe "python"
  include_recipe "virtualenv"

  ve_dir = node[app][:virtualenv][:path]

  [ :create, :activate ].each do |act|
    virtualenv ve_dir do
      owner node[app][:username]
      group node[app][:groupname]
      python node[app][:virtualenv][:python]
      virtualenv node[app][:virtualenv][:virtualenv]
      action act
    end
  end

  # Other dependencies
  case node[:platform]
    when "debian","ubuntu"
      %w{ libevent-dev libncurses5-dev swig }.each do |pkg|
        package pkg
      end
    # dependencies expected to be present on other platforms
  end

  src_dir = "#{Dir.tmpdir}/#{app}"

  if node[app][:action].include?("retrieve")
    case node[app][:retrieve_config][:retrieve_method]
    when "git"
      include_recipe "git"

      git src_dir do
        repository node[app][:retrieve_config][:git_repo]
        reference node[app][:retrieve_config][:git_reference]
        action :sync
        enable_submodules true
        user node[app][:username]
        group node[app][:groupname]
      end
    else
      abort "retrieve_method #{node[app][:retrieve_config][:retrieve_method]} not implemented yet"
    end
  end

  if node[app][:action].include?("install")
    case node[app][:install_config][:install_method]
    when "py_venv_setup"
      execute "run install" do
        cwd src_dir
        user node[app][:username]
        group node[app][:groupname]
        command "env >/tmp/env ; python setup.py install"
      end
      execute "install-supervisor" do
        user node[app][:username]
        group node[app][:groupname]
        command "easy_install --find-links=#{node[app][:install_config][:package_repo]} supervisor"
      end
    when "py_venv_buildout"
      execute "bootstrap buildout" do
        cwd src_dir
        user node[app][:username]
        group node[app][:groupname]
        command "env >/tmp/env ; python bootstrap.py"
      end
      execute "run buildout" do
        cwd src_dir
        user node[app][:username]
        group node[app][:groupname]
        command "./bin/buildout -O -c #{node[app][:install_config][:buildout_file]}"
      end
      execute "run generate_interfaces" do
        cwd src_dir
        user node[app][:username]
        group node[app][:groupname]
        command "./bin/generate_interfaces"
        only_if "test -x ./bin/generate_interfaces"
      end
    else
      abort "install_method #{node[app][:install_config][:install_method]} not implemented yet"
    end
  end

  if node[app][:action].include?("run")
    # Set up run directory
    case node[:app]
    when "pyon"
      run_dir = src_dir
    else
      run_dir = node[app][:run_config][:run_directory]

      # Create run directory
      directory run_dir do
        owner node[app][:username]
        group node[app][:groupname]
      end
    end

    # autorestart is for all processes right now, could be made more
    # granular if needed. Also note that it only applies in "supervised" mode.
    autorestart = node[app][:run_config].fetch("autorestart", false)

    # Name of the service
    epuservice_name = node[app][:run_config][:program]

    # Configuration file for this service
    epu_config_file = File.join(run_dir, "#{epuservice_name}.yml")
    epu_spec = node[app][:run_config][:config].to_hash
    if app == :epuagent
      supervisor_socket = "unix://" + File.join(node[:epu][:run_config][:run_directory], "supervisor.sock")
      epu_spec["epuagent"].merge!({ "supervisor_socket" => supervisor_socket})
    end

    epu_config epu_config_file do
      user node[app][:username]
      group node[app][:groupname]
      epuservice_name epuservice_name
      epuservice_spec epu_spec
    end

    base_logging_dir = "#{run_dir}/logs"
    directory "#{base_logging_dir}" do
      owner "#{node[app][:username]}"
      group "#{node[app][:groupname]}"
      mode "0755"
    end

    case node[app]
    when "pyon"
      rel = File.join(run_dir, "#{epuservice_name}-rel.yml")

      template rel do
        source "pyon-rel.yml.erb"
        owner node[app][:username]
        group node[app][:groupname]
        mode 0644
        variables(:name => node[app][:run_config][:name],
                  :module => node[app][:run_config][:module],
                  :class => node[app][:run_config][:class],
                 )
      end
    else
      rel = nil
    end

    start_script = File.join(run_dir, "start-#{epuservice_name}.sh")

    template start_script do
      source "start-service.sh.erb"
      owner node[app][:username]
      group node[app][:groupname]
      mode 0755
      variables(:service => epuservice_name,
                :service_config => epu_config_file,
                :venv_dir => ve_dir,
                :run_dir => run_dir,
                :rel => rel,
                :background_process => node[app][:run_config][:run_method] == "sh"
               )
    end

    epuservice = {
      :program => epuservice_name,
      :command => start_script,
      :autorestart => autorestart
    }

    case node[app][:run_config][:run_method]
    when "supervised"
      sup_conf = File.join(run_dir, "supervisor.conf")
      template sup_conf do
        source "supervisor.conf.erb"
        mode 0400
        owner node[app][:username]
        group node[app][:groupname]
        variables(:epuservice => epuservice)
      end

      bash "start-supervisor" do
        user node[app][:username]
        group node[app][:groupname]
        environment({
          "HOME" => "/home/#{node[app][:username]}"
        })
        code <<-EOH
        supervisord -c #{sup_conf}
        EOH
      end

    else
      abort "run_method #{node[app][:run_config][:run_method]} not implemented yet"
    end
  end
end
