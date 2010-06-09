#Cookbook Name: nimbus_context_agent

directory "/opt/nimbus" do
  mode "0755"
  action :create
  not_if "test -d /opt/nimbus"
end

bash "install-nimbus-context-agent" do
  code <<-EOH
    wget http://workspace.globus.org/downloads/nimbus-ctx-agent-2.2.1.tar.gz
    tar zxf nimbus-ctx-agent-2.2.1.tar.gz
    mv nimbus-ctx-agent-2.2.1/* /opt/nimbus/
    chmod -R +x /opt/nimbus/ctx-scripts/*
    cp /opt/chef/cookbooks/nimbus_context_agent/resources/chef-install-work-consumer /opt/nimbus/ctx-scripts/3-data/
  EOH
end
