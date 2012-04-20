include_recipe "couchdb"

case node[:platform]
  when "debian","ubuntu"
    # Easy to install packages
    node[:pyon][:debian_packages].each do |pkg|
      package pkg
    end

  else
    raise "#{node[:platform]} is not supported by this recipe"
end
