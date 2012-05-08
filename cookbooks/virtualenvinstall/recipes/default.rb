app_dir = node[:appdir]
venv_dir = node[:virtualenv][:path]

# need to dereference params passed to nested definitions because of chef 
# bug described above
username = params[:user]
groupname = params[:group]

execute "run install" do
    cwd app_dir
    user username
    group groupname
    command "python setup.py install"
end


