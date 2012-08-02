sshkeys = data_bag('sshkeys')

authorized_keys = ""

sshkeys.each do |key|
    sshkey = data_bag_item('sshkeys', key)

    pubkey = sshkey['pubkey']
    authorized_keys << "#{pubkey}\n"
end

log "Authz keys:\n #{authorized_keys}"
