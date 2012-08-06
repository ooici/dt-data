sshkeys = data_bag('sshkeys')

authorized_keys = ""

sshkeys.each do |key|
  sshkey = data_bag_item('sshkeys', key)

  pubkey = sshkey['pubkey']
  authorized_keys << "#{pubkey}\n"
end

if node[:ssh][:directory]
  ssh_directory = node[:ssh][:directory]

elsif node[:ssh][:user]
  ssh_user = node[:ssh][:user]

else

  case node[:platform]                                                           
    when "ubuntu"
      ssh_directory = "/home/ubuntu/.ssh"
      ssh_user = "ubuntu"
    else
      ssh_directory = "/root/.ssh"
      ssh_user = "root"
  end
end

directory node[:ssh][:directory] do
    user node[:ssh][:user]
    group node[:ssh][:user]
    mode "0700"
    action :create
end


authorized_keys_file = File.join(node[:ssh][:directory], "authorized_keys")

old_authz_keys_file = File.open(authorized_keys_file, "rb")
old_authz_keys = old_authz_keys_file.read
old_authz_keys_file.close

authorized_keys = "#{old_authz_keys}\n#{authorized_keys}"

# remove duplicate entries
authorized_keys_list = authorized_keys.split("\n")
authorized_keys_list = authorized_keys_list.map{|x| x.strip }
authorized_keys_list.uniq!
authorized_keys = authorized_keys_list.join("\n")

file authorized_keys_file do
    user node[:ssh][:user]
    group node[:ssh][:user]
    mode "0600"
    content authorized_keys
    action :create
end
