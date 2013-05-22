hostname = node[:ddns][:hostname]

# TODO: None is only ever passed here because of a bug in dtrs
if hostname and !hostname.empty? and hostname != "None"

  commands = <<-EOH
  server #{node[:ddns][:server]}
  update delete #{hostname} cname
  update add #{hostname} #{node[:ddns][:ttl]} cname #{node[:fqdn]}
  send
  EOH

  file "/tmp/ddns_nsupdate" do
    content commands
  end

  execute "update DDNS: #{hostname} -> #{node[:fqdn]}" do
    command "nsupdate /tmp/ddns_nsupdate"
  end

  # do nothing if hostname is not provided or is empty.
end
