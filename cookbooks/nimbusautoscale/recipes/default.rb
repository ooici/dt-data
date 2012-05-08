app_dir = node[:appdir]


template "#{app_dir}/phantomautoscale.yml" do
    source "config.yml.erb"
    owner node[:username]
    group node[:groupname]
    mode 0644
    action :create
end

template "#{app_dir}/start-phantom.sh" do
    source "start_phantom.sh.erb"
    owner node[:username]
    group node[:groupname]
    mode 0755
end

