#Cookbook Name: user

user node[:username] do
    comment "Dynamically created user."
    uid "1000"
    gid "cc"
    home "/home/#{node[:username]}"
    shell "/bin/bash"
    supports :manage_home => true
end
