case node[:platform]
  when "debian","ubuntu"
    package "python-virtualenv" do
      action :install
    end
end
