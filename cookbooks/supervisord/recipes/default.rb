app_dir = node[:appdir]

execute "install-supervisor" do
    user node[:username]
    group node[:groupname]
    if node[:supervisord][:supd_package_repo]
        command "easy_install --find-links=#{node[:supd_package_repo]} supervisor"
    else
        command "easy_install supervisor"
    end
end

template "#{app_dir}/supervisor.conf" do
    source "supervisor.conf.erb"
    owner node[:username]
    group node[:groupname]
    mode 0644
end
