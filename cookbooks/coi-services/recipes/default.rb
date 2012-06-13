
include_recipe "pyon_deps"
include_recipe "virtualenv"

venv_dir = node[:epu][:virtualenv][:path]

user node[:epu][:username] do
  comment "Dynamically created user."
  gid "#{node[:epu][:groupname]}"
  home "/home/#{node[:epu][:username]}"
  shell "/bin/bash"
  supports :manage_home => true
end

include_recipe "python"
include_recipe "virtualenv"

ve_dir = node[:epu][:virtualenv][:path]

[ :create, :activate ].each do |act|
  virtualenv ve_dir do
    owner node[:epu][:username]
    group node[:epu][:groupname]
    python node[:epu][:virtualenv][:python]
    virtualenv node[:epu][:virtualenv][:virtualenv]
    args node[:epu][:virtualenv][:args]
    action act
  end
end

git "/home/#{node[:epu][:username]}/coi-services" do
  user node[:epu][:username]
  repository node[:coi_services][:git_repo]
  reference node[:coi_services][:git_branch]
  enable_submodules true
  action :sync
end

bash "prepare cache" do
  cwd "/tmp"
  code <<-EOH
  set -e
  if [ ! -d /opt/cache/eggs ]; then
    rm -rf /opt/cache
    mkdir /opt/cache
    cd /opt/cache
    wget #{node[:coi_services][:super_cache]}
    tar xzf *.tar.gz
    chmod -R 777 /opt/cache
  fi
  EOH
end

bash "setup coi-services" do
  user node[:epu][:username]
  cwd "/home/#{node[:epu][:username]}/coi-services"
  returns [1,0]
  code <<-EOH
  python bootstrap.py

  ./bin/buildout -O -c #{node[:coi_services][:buildout_config]}
  ./bin/generate_interfaces
  EOH
end
