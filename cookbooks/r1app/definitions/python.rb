require 'json'
require 'tempfile'

define :python_datafile, :data => nil do
  t = Tempfile.open("chef_python_datafile")
  ruby_block "write json tempfile" do
    block do
      js = JSON.generate(params[:data])
      t.write(js)
      t.close()
    end
  end
  
  # in chef 0.9+ this should be cookbook_file
  remote_file "/tmp/json2py.py" do
    source "json2py.py"
    mode "0755"
  end

  file params[:name] do
    owner node[:username]
    group node[:groupname]
    mode "0600"
  end
  execute "/tmp/json2py.py #{t.path} #{params[:name]}"
end
