require "base64"

sec_dir = "/home/#{node[:pyon_security][:username]}/pyonsecurity"
keystore_dir = "#{sec_dir}/keystore"
certstore_dir = "#{sec_dir}/certstore"

[sec_dir, keystore_dir, certstore_dir].each do |dir_path|
  directory dir_path do
    owner node[:pyon_security][:username]
    group node[:pyon_security][:groupname]
    mode "0700"
  end
end

file "#{certstore_dir}/root.crt" do
  owner node[:pyon_security][:username]
  group node[:pyon_security][:groupname]
  mode "0644"
  content Base64.decode64(node[:pyon_security][:root_cert])
end

file "#{certstore_dir}/container.crt" do
  owner node[:pyon_security][:username]
  group node[:pyon_security][:groupname]
  mode "0644"
  content Base64.decode64(node[:pyon_security][:cert])
end

file "#{keystore_dir}/container.key" do
  owner node[:pyon_security][:username]
  group node[:pyon_security][:groupname]
  mode "0600"
  content Base64.decode64(node[:pyon_security][:key])
end
