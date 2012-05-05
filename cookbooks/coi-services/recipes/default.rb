
include_recipe "pyon_deps"
include_recipe "virtualenv"

venv_dir = node[:virtualenv][:path]

bash "get coi-services" do
  user node[:username]
  cwd "/home/#{node[:username]}/"
  code <<-EOH
  git clone https://github.com/ooici/coi-services.git
  git submodule update --init
  EOH
end


directory "/opt/cache" do
  owner node[:username]
  mode "0755"
  action :create
end

bash "setup coi-services" do

  cwd "/home/#{node[:username]}/coi-services"
  code <<-EOH
  source #{venv_dir}/bin/activate
  python bootstrap.py

  ./bin/buildout -O -c production.cfg
  ./bin/generate_interfaces
  EOH
end
