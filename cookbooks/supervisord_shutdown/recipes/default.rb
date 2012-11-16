cookbook_file "/usr/local/bin/kill-supd.sh" do
  source "kill-supd.sh"
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file "/etc/init/kill-supd.conf" do
  source "kill-supd.conf"
  owner "root"
  group "root"
  mode "0644"
end
