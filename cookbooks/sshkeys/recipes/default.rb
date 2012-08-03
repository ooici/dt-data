sshkeys = data_bag('sshkeys')

authorized_keys = ""

sshkeys.each do |key|
    sshkey = data_bag_item('sshkeys', key)

    pubkey = sshkey['pubkey']
    authorized_keys << "#{pubkey}\n"
end

directory node[:ssh][:directory] do
    user node[:ssh][:user]
    group node[:ssh][:user]
    mode "0700"
    action :create
end

file File.join(node[:ssh][:directory], "authorized_keys") do
    user node[:ssh][:user]
    group node[:ssh][:user]
    mode "0600"
    content authorized_keys
    action :create
end
