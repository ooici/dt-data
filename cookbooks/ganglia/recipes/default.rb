

case node[:platform]
  when "debian","ubuntu"
    package "python-software-properties"

    # ganglia in Ubuntu is too old for sflow support
    execute "enable ganglia ppa" do
      command "apt-add-repository -y ppa:rufustfirefly/ganglia"
    end
    execute "update apt" do
      command "apt-get update"
    end

    package "ganglia-monitor"

  else
    raise "#{node[:platform]} is not supported by this recipe"
end

template "/etc/ganglia/gmond.conf" do
  mode "644"
  source "gmond.conf.erb"
end

service "ganglia-monitor" do
  action :restart
end
