
include_recipe "pyon_deps"
include_recipe "virtualenv"

venv_dir = node[:virtualenv][:path]

bash "get coi-services" do
  user node[:username]
  cwd "/home/#{node[:username]}/"
  code <<-EOH
  wget https://nodeload.github.com/ooici/coi-services/tarball/master -o coi-services.tar.gz
  tar xzf coi-services.tar.gz
  mv ooici-coi-services-* coi-services
  EOH
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
