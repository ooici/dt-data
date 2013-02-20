app_dir = node[:appdir]
ve_dir = node[:virtualenv][:path]

include_recipe "python"
include_recipe "virtualenv"

[ :create, :activate ].each do |act|
  virtualenv ve_dir do
    owner node[:username]
    group node[:groupname]
    python node[:virtualenv][:python]
    virtualenv node[:virtualenv][:virtualenv]
    action act
  end
end

execute "install-supervisor" do
    user node[:username]
    group node[:groupname]
    if node[:supervisord][:supd_package_repo]
        command "easy_install --find-links=#{node[:supd_package_repo]} supervisor"
    else
        command "easy_install supervisor"
    end
end

if node[:supervisord][:memmon]
  execute "install-superlance" do
      user node[:username]
      group node[:groupname]
      if node[:supervisord][:supd_package_repo]
          command "easy_install --find-links=#{node[:supd_package_repo]} superlance"
      else
          command "easy_install superlance"
      end
  end
end

sup_conf = File.join(app_dir, "supervisor.conf")
template sup_conf do
    source "supervisor.conf.erb"
    owner node[:username]
    group node[:groupname]
    mode 0644
end

logsdir = File.join(app_dir, "logs")

directory logsdir do
    owner node[:username]
    group node[:groupname]
    mode "0755"
    action :create
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

