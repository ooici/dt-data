# ran into this bug: http://tickets.opscode.com/browse/CHEF-422
# so nested defintions like this one cannot be called in block form
# without first dereferencing params. (w..t..f..)
define :virtualenv, :user => nil, :group => nil do
  venv_dir = params[:name]
  execute "create virtualenv" do
    user params[:user]
    group params[:group]
    command "#{params[:virtualenv_exe]} --python=#{params[:virtualenv_python]} --no-site-packages #{venv_dir}"
    creates File.join(venv_dir, "bin/activate")
  end
end

define :install_app, :conf => nil, :user => nil, :group => nil, 
  :virtualenv => nil do
  
  app_dir = params[:name]
  venv_dir = params[:virtualenv]
  
  # need to dereference params passed to nested definitions because of chef 
  # bug described above
  username = params[:user]
  groupname = params[:group]
  
  case node[:platform]
  when "debian","ubuntu"
    package "python-virtualenv" do
      action :install
    end
    virtualenv_exe = "virtualenv"
    virtualenv_python = "python2.6"
  else
    virtualenv_exe = "/opt/python2.5/bin/virtualenv"
    virtualenv_python = "python2.5"
  end
  
  conf = params[:conf]
  raise ArgumentError, 'app_dir must be specified' if app_dir.nil? or 
    app_dir.empty?
  raise ArgumentError, 'conf must be specified' if conf.nil?
  raise ArgumentError, 'user must be specified' if username.nil?
  raise ArgumentError, 'group must be specified' if groupname.nil?

  case conf[:install_method]
  when "py_venv_setup"
    virtualenv venv_dir do 
      user username
      group groupname
      virtualenv_exe virtualenv_exe
      virtualenv_python virtualenv_python
    end
    bash "run install" do
      cwd app_dir
      user username
      group groupname
      code <<-EOH
      source #{venv_dir}/bin/activate
      #{venv_dir}/bin/python setup.py install
      EOH
    end
  
  when "py_venv_buildout"
    virtualenv venv_dir do 
      user username
      group groupname
      virtualenv_exe virtualenv_exe
      virtualenv_python virtualenv_python
    end
    bash "run install" do
      cwd app_dir
      user username
      group groupname
      code <<-EOH
      source #{venv_dir}/bin/activate
      #{venv_dir}/bin/python ./bootstrap.py
      bin/buildout
      EOH
    end
  else raise ArgumentError, "unknown install_method #{conf[:install_method]}"
  end
end
