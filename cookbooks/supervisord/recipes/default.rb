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

sup_conf = File.join(app_dir, "supervisor.conf")
template sup_conf do
    source "supervisor.conf.erb"
    owner node[:username]
    group node[:groupname]
    mode 0644
end

bash "start-supervisor" do
  user node[:username]
  group node[:groupname]
  environment({
    "HOME" => "/home/#{node[:username]}"
  })
  code <<-EOH
  supervisord -c #{sup_conf}
  EOH
end

