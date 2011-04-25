#
# Cookbook Name:: pbs_python
# Recipe:: default
#

case node[:platform]
when "debian","ubuntu"
  include_recipe "apt"
  %w{ build-essential }.each do |pkg|
    package pkg
  end
end

bash "Install PBS Python #{node[:pbs_python][:pbs_python][:src_version]}" do
  cwd "/tmp"
  code <<-EOH
  export PATH=/opt/torque-2.5.5/bin:$PATH
  wget ftp://ftp.sara.nl/pub/outgoing/pbs_python.tar.gz
  rm -rf pbs_python-#{node[:pbs_python][:pbs_python][:src_version]}
  tar -xzf /tmp/#{node[:pbs_python][:pbs_python][:src_name]}
  cd pbs_python-#{node[:pbs_python][:pbs_python][:src_version]}
  ./configure
  make
  python setup.py install
  echo "/opt/torque-2.5.5/lib/" | tee /etc/ld.so.conf.d/torque.conf && ldconfig
  EOH
end
