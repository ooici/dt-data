include_recipe "couchdb"

case node[:platform]
  when "debian","ubuntu"
    # Easy to install packages
    %w{ libncurses5-dev swig libzmq-dev libevent-dev }.each do |pkg|
      package pkg
    end

  else
    raise "#{node[:platform]} is not supported by this recipe"
end
