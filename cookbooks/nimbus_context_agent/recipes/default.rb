#Cookbook Name: nimbus_context_agent

bash "install-nimbus-context-agent" do
  code <<-EOH
    if [ -d /etc/apt ]; then
      wget http://ooi.s3.amazonaws.com/nimbus-ctx-agent-2.3.0-ALT.tar.gz
      tar zxf nimbus-ctx-agent-2.3.0-ALT.tar.gz
      mv nimbus-ctx-agent-2.3.0-ALT/ /opt/nimbus/
    else
      if [ ! -d /opt/nimbus ]; then
        wget http://www.nimbusproject.org/downloads/nimbus-ctx-agent-2.3.0.tar.gz
        tar zxf nimbus-ctx-agent-2.3.0.tar.gz
        mv nimbus-ctx-agent-2.3.0/ /opt/nimbus/
      fi
      if [ -d /opt/nimbus/nimbus-ctx-agent-2.3.0 ]; then
        mv /opt/nimbus/ /opt/oldnimbus
        mv /opt/oldnimbus/nimbus-ctx-agent-2.3.0 /opt/nimbus
      fi
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
