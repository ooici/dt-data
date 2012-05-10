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

execute "Start couchdb" do
  command "couchdb -b"
end
