app_dir = node[:appdir]

conf = File.join(app_dir, "phantomautoscale.yml")
template conf do
    source "config.yml.erb"
    owner node[:username]
    group node[:groupname]
    mode 0644
    action :create
end

exe = File.join(app_dir, "start-phantom.sh")
template exe do
    source "start_phantom.sh.erb"
    owner node[:username]
    group node[:groupname]
    mode 0755
end

