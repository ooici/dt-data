log_server = node[:graylog2][:server]
if log_server
  include_recipe "chef_handler::default"

  chef_gem "chef-gelf" do
    action :nothing
    ignore_failure true
  end.run_action(:install)

  # gracefully fail if gem wasn't installed. this shouldn't fail the node.
  begin
    require 'chef/gelf'

    chef_handler "Chef::GELF::Handler" do
      source "chef/gelf"
      ignore_failure true
      arguments({
        :server => log_server
      })

      supports :exception => true, :report => true
    end.run_action(:enable)
  rescue LoadError
    Chef::Log.warn("Failed to load Chef GELF handler. Results will not be reported to graylog2.")
  end
end

