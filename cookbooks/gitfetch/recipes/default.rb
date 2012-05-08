app_dir = "#{node['appdir']}"

########################################################################
# RETRIEVAL
########################################################################

git_retrieve_app app_dir do
    conf node[:gitfetch]
    user node[:username]
    group node[:groupname]
end
