
case node[:platform]
  when "debian","ubuntu"
    
    bash "update apt" do
      code <<-EOH
      apt-get update
      EOH
    end

    bash "upgrade apt" do
      code <<-EOH
      apt-get upgrade
      EOH
    end

    # Easy to install packages
    node[:pyon][:debian_packages].each do |pkg|
      package pkg
    end

  else
    raise "#{node[:platform]} is not supported by this recipe"
end
