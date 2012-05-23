
case node[:platform]
  when "debian","ubuntu"
    
    bash "update apt" do
      code <<-EOH
      apt-get update
      EOH
    end

    # Easy to install packages
    node[:pyon][:debian_packages].each do |pkg|
      package pkg
    end
  when "centos","redhat"
    node[:pyon][:yum_packages].each do |pkg|
      package pkg
    end

  else
    raise "#{node[:platform]} is not supported by this recipe"
end
