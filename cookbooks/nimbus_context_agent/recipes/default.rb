#Cookbook Name: nimbus_context_agent

context_agent_tarball = "/tmp/nimbus-ctx-agent-2.3.0.tar.gz"
remote_file context_agent_tarball do
  source "http://www.nimbusproject.org/downloads/nimbus-ctx-agent-2.3.0-OOI.tar.gz"
  retries 20
end

bash "install-nimbus-context-agent" do
  code <<-EOH
    if [ ! -d /opt/nimbus ]; then
      tar zxf #{context_agent_tarball}
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

template "/opt/nimbus/ctx-scripts/3-data/dt-chef-solo" do
    source "dt-chef-solo"
    mode 755
    owner "root"
    group "root"
end

template "/opt/nimbus/ctx-scripts/3-data/dt-chef-solo.py" do
    source "dt-chef-solo.py"
    mode 755
    owner "root"
    group "root"
end
