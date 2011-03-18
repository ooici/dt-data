#Cookbook Name: nimbus_context_agent

bash "install-nimbus-context-agent" do
  code <<-EOH
    if [ ! -d /opt/nimbus ]; then
      wget http://www.nimbusproject.org/downloads/nimbus-ctx-agent-2.3.0.tar.gz
      tar zxf nimbus-ctx-agent-2.3.0.tar.gz
      mv nimbus-ctx-agent-2.3.0/ /opt/nimbus/
    fi
  EOH
end

template "/opt/nimbus/ctx-scripts/3-data/chef-install-work-consumer" do
    source "chef-install-work-consumer"
    mode 755
    owner "root"
    group "root"
end
