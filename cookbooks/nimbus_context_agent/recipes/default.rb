#Cookbook Name: nimbus_context_agent

directory "/opt/nimbus" do
  mode "0755"
  action :create
  not_if "test -d /opt/nimbus"
end

bash "install-nimbus-context-agent" do
  code <<-EOH
    wget http://www.nimbusproject.org/downloads/nimbus-ctx-agent-2.2.1.tar.gz
    tar zxf nimbus-ctx-agent-2.2.1.tar.gz
    mv nimbus-ctx-agent-2.2.1/* /opt/nimbus/
    chmod -R +x /opt/nimbus/ctx-scripts/*
  EOH
end

template "/opt/nimbus/ctx-scripts/3-data/chef-install-work-consumer" do
    source "chef-install-work-consumer"
    mode 755
    owner "root"
    group "root"
end
