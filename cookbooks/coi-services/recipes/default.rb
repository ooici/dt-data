
include_recipe "pyon_deps"
include_recipe "virtualenv"

venv_dir = node[:virtualenv][:path]

bash "get coi-services" do
  user node[:username]
  cwd "/home/#{node[:username]}/"
  code <<-EOH
  git clone https://github.com/ooici/coi-services.git
  EOH
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
    tar xzf *
    chmod -R 777 /opt/cache
  fi
  EOH
end

bash "setup coi-services" do

  cwd "/home/#{node[:username]}/coi-services"
  code <<-EOH
  source #{venv_dir}/bin/activate
  git submodule update --init
  python bootstrap.py

  ./bin/buildout -O -c production.cfg
  ./bin/generate_interfaces
  EOH
end
