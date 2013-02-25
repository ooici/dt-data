#
# Cookbook Name:: epu
# Recipe:: default
#
# Copyright 2012, University of Chicago
#

require 'tmpdir'
require 'uuidtools'
require 'yaml'

[:pyon, :epu, :epuagent, :eeagent].each do |app|

  next if node[app].nil? or node[app][:action] == []

  user node[app][:username] do
      comment "Dynamically created user."
      gid "#{node[app][:groupname]}"
      home "/home/#{node[app][:username]}"
      shell "/bin/bash"
      supports :manage_home => true
  end

  include_recipe "python"

  if node[app].include?(:virtualenv) and node[app][:virtualenv].include?(:path)
    include_recipe "virtualenv"
    ve_dir = node[app][:virtualenv][:path]

  else
    ve_dir = nil
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

    if node[app][:retrieve_config].include?("retrieve_directory")
      src_dir = node[app][:retrieve_config][:retrieve_directory]
    end

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

    when "archive", "virtualenv_archive", "offline_archive"
      archive_path = "#{Dir.tmpdir}/#{app}-#{Time.now.to_i}.tar.gz"
      remote_file archive_path do
        source node[app][:retrieve_config][:archive_url]
        owner node[app][:username]
        group node[app][:groupname]
      end

      # virtualenv archives get unpacked directly to the virtualenv path
      if node[app][:retrieve_config][:retrieve_method] == "virtualenv_archive"
        unpack_dir = node[app][:virtualenv][:path]
      else
        unpack_dir = src_dir
      end

      directory unpack_dir do
        owner node[app][:username]
        group node[app][:groupname]
        mode "0755"
      end

      execute "unpack #{archive_path} into #{unpack_dir}" do
        user node[app][:username]
        group node[app][:groupname]

        if node[app][:retrieve_config][:retrieve_method] == "offline_archive"
          command "tar xzf #{archive_path} -C #{unpack_dir}"
        else
          # using this funny style of untarring so that we don't have to care what
          # directory name is actually inside the tarball.
          command "tar xzf #{archive_path} -C #{unpack_dir} --strip 1"
        end
      end

      # virtualenv archives must be reconfigured after unpacking
      if node[app][:retrieve_config][:retrieve_method] == "virtualenv_archive"
        virtualenv ve_dir do
          owner node[app][:username]
          group node[app][:groupname]
          python node[app][:virtualenv][:python]
          virtualenv node[app][:virtualenv][:virtualenv]
          args node[app][:virtualenv][:args]
          action :reconfigure
        end
      end

    else
      abort "retrieve_method #{node[app][:retrieve_config][:retrieve_method]} not implemented yet"
    end
  end

  if node[app][:action].include?("install")

    if not ve_dir.nil?
      [ :create, :activate ].each do |act|
        virtualenv ve_dir do
          owner node[app][:username]
          group node[app][:groupname]
          python node[app][:virtualenv][:python]
          virtualenv node[app][:virtualenv][:virtualenv]
          args node[app][:virtualenv][:args]
          action act
        end
      end
    end

    if node[app][:install_config][:extras] and node[app][:install_config][:extras].length > 0
      extras = node[app][:install_config][:extras].join(",")
      extras = "[#{extras}]"
    else
      extras = nil
    end

    case node[app][:install_config][:install_method]
    when "py_venv_setup"
      execute "run install" do
        cwd src_dir
        user node[app][:username]
        group node[app][:groupname]
        command "env >/tmp/env ; python setup.py install"
      end

      if not extras.nil?
        execute "install extras" do
          cwd src_dir
          user node[app][:username]
          group node[app][:groupname]
          command "pip install #{app}#{extras}"
        end
      end

      execute "install-supervisor" do
        user node[app][:username]
        group node[app][:groupname]
        command "easy_install --allow-hosts '*.ooici.net,*.python.org' --find-links=#{node[app][:install_config][:package_repo]} supervisor"
      end
    when "py_venv_offline_setup"
      execute "run install" do
        cwd src_dir
        user node[app][:username]
        group node[app][:groupname]
         environment({
           "HOME" => "/home/#{node[app][:username]}"
         })
        command "env >/tmp/env ; pip install -r ./#{app}/requirements.txt --index-url=file://`pwd`/packages/simple/ #{app}"
      end
      if not extras.nil?
        execute "install extras" do
          cwd src_dir
          user node[app][:username]
          group node[app][:groupname]
          command "pip install #{app}#{extras}"
        end
      end
      execute "install-supervisor" do
        cwd src_dir
        user node[app][:username]
        group node[app][:groupname]
         environment({
           "HOME" => "/home/#{node[app][:username]}"
         })
        command "pip install --index-url=file://`pwd`/packages/simple supervisor"
      end
    when "py_venv_buildout"
      execute "bootstrap buildout" do
        cwd src_dir
        user node[app][:username]
        group node[app][:groupname]
        command "env >/tmp/env ; python bootstrap.py"
      end
      directory "/opt/cache" do
        owner node[app][:username]
        group node[app][:groupname]
      end
      bash "prepare cache" do
        cwd "/tmp"
        code <<-EOH
        set -e
        if [ ! -d /opt/cache/eggs ]; then
          cd /opt/cache
          wget #{node[app][:install_config][:egg_cache]}
          tar xzf *.tar.gz
          chmod -R 777 /opt/cache
        fi
        EOH
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
        only_if "test -x #{src_dir}/bin/generate_interfaces"
      end
      execute "install-supervisor" do
        user node[app][:username]
        group node[app][:groupname]
        command "easy_install --allow-hosts '*.ooici.net,*.python.org' --find-links=#{node[app][:install_config][:package_repo]} supervisor"
      end
    else
      abort "install_method #{node[app][:install_config][:install_method]} not implemented yet"
    end
  end

  if node[app][:action].include?("configure")
    case app
    when :pyon
      if node[app][:configure_config].include?("config_file")
        config_file = node[app][:configure_config][:config_file]
      else
        config_file = "#{src_dir}/res/config/pyon.local.yml"
      end

      # TODO rename this definition to be more generic
      epu_config config_file do
        user node[app][:username]
        group node[app][:groupname]
        epuservice_name "pyon"
        epuservice_spec node[app][:configure_config][:config]
      end

      if node[app][:configure_config].include?("logging_config")

        if node[app][:configure_config].include?("logging_config_file")
          logging_config_file = node[app][:configure_config][:logging_config_file]
        else
          logging_config_file = "#{src_dir}/res/config/logging.local.yml"
        end

        # TODO rename this definition to be more generic
        epu_config logging_config_file do
          user node[app][:username]
          group node[app][:groupname]
          epuservice_name "pyon"
          epuservice_spec node[app][:configure_config][:logging_config]
        end
      end

    else
      abort "configure action for app #{app} not implemented yet"
    end
  end

  if node[app][:action].include?("run")

    # venv may not have been activated yet in this chef run
    if not ve_dir.nil?
      virtualenv ve_dir do
        owner node[app][:username]
        group node[app][:groupname]
        action :activate
      end
    end

    # Ensure ZooKeeper path exists if in use
    config = node[app][:run_config][:config].to_hash
    if config['server'] && config['server']['zookeeper']
      zk_hosts = config['server']['zookeeper']['hosts']
      zk_path = config['server']['zookeeper']['path']
      zk_username = config['server']['zookeeper']['username']
      zk_password = config['server']['zookeeper']['password']

      script "Ensure ZooKeeper path" do
        interpreter "python"
        user node[app][:username]
        group node[app][:groupname]
        cwd "/tmp"
        code <<-EOH
from kazoo.client import KazooClient
from kazoo.security import make_digest_acl

def get_auth_data_and_acl(username, password):
    if username and password:
        auth_scheme = "digest"
        auth_credential = "%s:%s" % (username, password)
        auth_data = [(auth_scheme, auth_credential)]
        default_acl = [make_digest_acl(username, password, all=True)]
    elif username or password:
        raise ValueError("both username and password must be specified, if any")
    else:
        auth_data = None
        default_acl = None

    return auth_data, default_acl

def get_kazoo_kwargs(username=None, password=None, timeout=None):
    """Get KazooClient optional keyword arguments as a dictionary
    """
    kwargs = {}

    auth_data, default_acl = get_auth_data_and_acl(username, password)
    if auth_data:
        kwargs['auth_data'] = auth_data
        kwargs['default_acl'] = default_acl

    if timeout:
        kwargs['timeout'] = timeout

    return kwargs

kwargs = get_kazoo_kwargs(username='#{zk_username}', password='#{zk_password}',
    timeout=5)
zk = KazooClient(hosts='#{zk_hosts}', **kwargs)
zk.start()

zk.ensure_path('#{zk_path}')
        EOH
      end
    end

    # Set up run directory
    run_dir = node[app][:run_config][:run_directory]

    # Create run directory
    directory run_dir do
      owner node[app][:username]
      group node[app][:groupname]
    end

    # autorestart is for all processes right now, could be made more
    # granular if needed. Also note that it only applies in "supervised" mode.
    autorestart = node[app][:run_config].fetch("autorestart", false)

    # Name of the service
    epuservice_name = node[app][:run_config][:program]
    replicas = node[app][:run_config][:replicas]
    replicas = replicas.to_i

    epuservice_list = []

    1.upto(replicas) do |i|
      unique_tag = i
      epuservice_name_unique = "#{epuservice_name}_#{unique_tag}"

      # Configuration file for this service
      epu_config_file = File.join(run_dir, "#{epuservice_name_unique}.yml")
      epu_spec = node[app][:run_config][:config].to_hash
      if app == :epuagent
       supervisor_socket = "unix://" + File.join(node[:epu][:run_config][:run_directory], "supervisor.sock")
       epu_spec["epuagent"].merge!({ "supervisor_socket" => supervisor_socket})
      end

      if epuservice_name == "eeagent"
        persistence_dir = epu_spec["eeagent"]["launch_type"]["persistence_directory"]
        persistence_dir = File.join(persistence_dir, "#{epuservice_name}-#{unique_tag}")
        epu_spec["eeagent"]["launch_type"]["persistence_directory"] = persistence_dir

        directory persistence_dir do
          owner "#{node[app][:username]}"                                          
          group "#{node[app][:groupname]}"                                         
          recursive true
          mode "0755"                                                              
        end           

        eeagent_name = "eeagent_#{unique_tag}"
        epu_spec["eeagent"]["name"] = eeagent_name
        epu_spec["agent"]["resource_id"] = eeagent_name
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

      case app
      when :pyon
        rel = File.join(run_dir, "#{epuservice_name_unique}-rel.yml")
  
        template rel do
          source "pyon-rel.yml.erb"
          owner node[app][:username]
          group node[app][:groupname]
          mode 0644
          variables(:name => node[app][:run_config][:name],
                    :module => node[app][:run_config][:module],
                    :class => node[app][:run_config][:class],
                    :unique_tag => unique_tag
                   )
        end
      else
        rel = nil
      end
  
      start_script = File.join(run_dir, "start-#{epuservice_name_unique}.sh")

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
                  :system_name => node[app][:run_config][:system_name],
                  :background_process => node[app][:run_config][:run_method] == "sh"
                 )
      end
  
      epuservice = {
        :program => epuservice_name_unique,
        :command => start_script,
        :autorestart => autorestart
      }

      epuservice_list << epuservice
  
    end

    case node[app][:run_config][:run_method]
     when "supervised"
       sup_conf = File.join(run_dir, "supervisor.conf")
       template sup_conf do
         source "supervisor.conf.erb"
         mode 0400
         owner node[app][:username]
         group node[app][:groupname]
         variables(:epuservice_list => epuservice_list)
       end

       bash "start-supervisor" do
         user node[app][:username]
         group node[app][:groupname]
         cwd run_dir
         environment({
           "HOME" => "/home/#{node[app][:username]}"
         })
         code <<-EOH
         #{node[app][:run_config][:supervisord_path]} -c #{sup_conf}
         EOH
       end

   else
     abort "run_method #{node[app][:run_config][:run_method]} not implemented yet"
   end
 end
end
