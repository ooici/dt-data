case node[:platform]
  when "debian","ubuntu"
    execute "update package index" do
      command "apt-get update"
      action :run
    end
    package "python-virtualenv" do
      action :install
    end
end
