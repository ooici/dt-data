bash "adjust-sqlstream-bash-env" do
  code <<-EOH
  echo "export JAVA_HOME=/usr/local/JDK1.6" >> /home/#{node[:username]}/.bashrc
  echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> /home/#{node[:username]}/.bashrc
  EOH
end

template "/home/#{node[:username]}/.s3cfg" do
  source "dot.s3cfg.erb"
  owner "#{node[:username]}"
  variables(
      :aws_access_key => node[:sqlstream][:binary_retrieve_id],
      :aws_access_secret => node[:sqlstream][:binary_retrieve_secret]
  )
end

directory "/home/#{node[:username]}/ooici.supplemental.packages" do
  owner "#{node[:username]}"
  mode "0755"
  action :create
end

execute "#{node[:sqlstream][:binary_retrieve_command]}" do
  user "#{node[:username]}"
  cwd "/home/#{node[:username]}/ooici.supplemental.packages"
  action :run
  environment ({'HOME' => '/home/#{node[:username]}'})
end


