
include_recipe "pyon_deps"

user node[:epu][:username] do
  comment "Dynamically created user."
  gid "#{node[:epu][:groupname]}"
  home "/home/#{node[:epu][:username]}"
  shell "/bin/bash"
  supports :manage_home => true
end

include_recipe "python"

src_dir = "/home/#{node[:epu][:username]}/coi-services"
archive_path = "#{Dir.tmpdir}/coi-services-#{Time.now.to_i}.tar.gz"

remote_file archive_path do
  source node[:coi_services][:archive_url]
  owner node[:epu][:username]
  group node[:epu][:groupname]
end

directory src_dir do
  owner node[:epu][:username]
  group node[:epu][:groupname]
  mode "0755"
end

# using this funny style of untarring so that we don't have to care what
# directory name is actually inside the tarball.
execute "unpack #{archive_path} into #{src_dir}" do
  user node[:epu][:username]
  group node[:epu][:groupname]
  command "tar xzf #{archive_path} -C #{src_dir} --strip 1"
end
