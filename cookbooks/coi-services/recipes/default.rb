
include_recipe "pyon_deps"
include_recipe "virtualenv"

venv_dir = node[:virtualenv][:path]

git "/home/#{node[:username]}/coi-services" do
  user node[:username]
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
    wget #{node[:appinstall][:super_cache]}
    tar xzf *.tar.gz
    chmod -R 777 /opt/cache
  fi
  EOH
end

bash "setup coi-services" do
  user node[:username]
  cwd "/home/#{node[:username]}/coi-services"
  returns [1,0]
  code <<-EOH
  python bootstrap.py

  ./bin/buildout -O -c #{node[:coi_services][:buildout_config]}
  ./bin/generate_interfaces
  EOH
end
