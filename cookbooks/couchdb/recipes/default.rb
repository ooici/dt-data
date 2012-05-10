

case node[:platform]
  when "debian","ubuntu"
    #package "python-software-properties"

    #couch is now in oneiric
    #execute "enable couchdb ppa" do
      #command "apt-add-repository ppa:ericdrex/couchdb"
    #end

    package "couchdb"

  else
    raise "#{node[:platform]} is not supported by this recipe"
end

template "/etc/couchdb/local.ini" do
  source "local.ini.erb"
end

# Work around https://bugs.launchpad.net/ubuntu/+source/couchdb/+bug/448682
bash "Kill Couch" do
  code <<-EOH
  pkill couchdb
  EOH
end

execute "Start couchdb" do
  command "couchdb -b"
end
