define :app_monitor, :conf => nil, :user => nil, :group => nil, 
  :virtualenv => nil, :pythoncc => nil, :universals => nil,
  :supervisor_socket => nil do
  
  [:name, :conf, :user, :group, :pythoncc, :supervisor_socket].each do |p|
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
  pythoncc = params[:pythoncc]
  universal_confs = params[:universals]
  supervisor_socket = params[:supervisor_socket]

  retrieve_app monitor_dir do
    conf config
    user username
    group groupname
  end

  install_app monitor_dir do
    conf config
    user username
    group groupname
    venv_dir venv_dir
  end

  template "#{monitor_dir}/res/logging/loglevels.cfg" do
    source "loglevels.cfg.erb"
    owner username
    group groupname
    variables(:log_level => pythoncc[:log_level])
  end

  # build up local confs
  agent_vars = {"supervisor_socket" => supervisor_socket}
  [:node_id, :heartbeat_dest, :heartbeat_op, :heartbeat_period].each do |k|
    agent_vars[k.to_s] = config[k]
  end
  local_confs = {"epuagent.agent" => agent_vars}

  ionlocal_config File.join(monitor_dir, "res/config/ionlocal.config") do
    user username
    group groupname
    universals universal_confs
    locals local_confs
  end

  broker_username = pythoncc[:broker_username]
  broker_password = pythoncc[:broker_password]
  if broker_username and broker_password
    broker_credfile = File.join(monitor_dir, "broker_creds.txt")
    file broker_credfile do
      owner node[:username]
      group node[:groupname]
      mode "0600"
      content "#{broker_username} #{broker_password}"
    end
  else
    broker_credfile = nil
  end

  service = "monitor"
  start_script = File.join(monitor_dir, "start-#{service}.sh")
  template start_script do
    source "start-service.sh.erb"
    owner node[:username]
    group node[:groupname]
    mode 0755
    variables(:service => service,
              :service_config => config[:service_config],
              :venv_dir => venv_dir,
              :app_dir => monitor_dir,
              :sysname => pythoncc[:sysname],
              :broker => pythoncc[:broker],
              :broker_heartbeat => pythoncc[:broker_heartbeat],
              :broker_credfile => broker_credfile)
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
