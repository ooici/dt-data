hostname = node[:ddns][:hostname]

if hostname and !hostname.empty?

  bash "update DDNS: #{hostname} -> #{node[:fqdn]}" do
    code <<-EOH

    nsupdate << EOF
    server #{node[:ddns][:server]}
    update delete #{hostname} cname
    update add #{hostname} #{node[:ddns][:ttl]} cname #{node[:fqdn]}
    send
    EOF
    EOH
  end

  # do nothing if hostname is not provided or is empty.

end
