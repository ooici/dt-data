ve_exe = node[:virtualenv][:virtualenv]
py_exe = node[:virtualenv][:python]
ve_dir = node[:virtualenv][:path]

case node[:platform]
  when "debian","ubuntu"
#TODO: Causes problems on vagrant
#    execute "update package index" do
#      command "apt-get update"
#      action :run
#    end
    package "python-virtualenv" do
      action :install
    end
end

execute "create virtualenv" do
  user node[:username]
  group node[:groupname]
  command "#{ve_exe} --python=#{py_exe} --no-site-packages #{ve_dir}"
  creates File.join(ve_dir, "bin/activate")
end

ruby_block "set virtualenv environment variables" do
  block do
    ENV["VIRTUAL_ENV"] = ve_dir
    ENV["PATH"] = File.join(ve_dir, "bin") + ":" + ENV["PATH"]
  end
  not_if {ENV["VIRTUAL_ENV"] == ve_dir}
end
