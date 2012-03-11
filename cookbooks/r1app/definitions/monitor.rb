define :app_monitor, :conf => nil, :user => nil, :group => nil,
  :virtualenv => nil, :supervisor_socket => nil do

  [:name, :conf, :user, :group, :supervisor_socket].each do |p|
    raise ArgumentError, "#{p} must be specified" if params[p].nil? or
      params[p].empty?
  end

  # gotta deref params because of this bug:
  #   http://tickets.opscode.com/browse/CHEF-422
  monitor_dir = params[:name]
  config = params[:conf]
  username = params[:user]
  groupname = params[:group]
  venv_dir = params[:virtualenv]
  supervisor_socket = params[:supervisor_socket]

  if config[:retrieve_method]
    retrieve_app monitor_dir do
      conf config
      user username
      group groupname
    end
  end

  if config[:install_method]
    install_app monitor_dir do
      conf config
      user username
      group groupname
      venv_dir venv_dir
    end
  end

  service_name = "epu-agent"
  abs_epuagent_config = File.join(monitor_dir, "#{service_name}.yml")

  epuagent_config = config[:config].to_hash
  epuagent_config["epuagent"].merge!({ "supervisor_socket" => supervisor_socket})

  epuagent_config abs_epuagent_config do
    user node[:username]
    group node[:groupname]
    epuagent_spec epuagent_config
  end

  base_logging_dir = "#{monitor_dir}/logs"
  directory "#{base_logging_dir}" do
    owner "#{node[:username]}"
    group "#{node[:groupname]}"
    mode "0755"
  end
  logging_dir = "#{base_logging_dir}/#{service_name}"
  directory "#{logging_dir}" do
    owner "#{node[:username]}"
    group "#{node[:groupname]}"
    mode "0755"
  end

  start_script = File.join(monitor_dir, "start-#{service_name}.sh")
  template start_script do
    source "start-service.sh.erb"
    owner node[:username]
    group node[:groupname]
    mode 0755
    variables(:service => service_name,
              :service_config => abs_epuagent_config,
              :venv_dir => venv_dir,
              :app_dir => monitor_dir)
  end

  # app monitor is itself run via supervisord, configured to restart
  # it on failure

  sup_conf = File.join(monitor_dir, "supervisor.conf")
  template sup_conf do
    source "supervisor.conf.erb"
    mode 0400
    owner username
    group groupname
    variables(:programs => {"appmonitor" =>
              {:command => start_script, :autorestart => true}})
  end

  execute "start-monitor" do
    user username
    group groupname
    environment({"HOME" => "/home/#{node[:username]}"})
    command "supervisord -c #{sup_conf}"
  end
end
