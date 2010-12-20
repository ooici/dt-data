group "sqlstream"

user "sqlstream" do
    comment "Dynamically created user sqlstream."
    home "/home/sqlstream"
    shell "/bin/bash"
    gid "sqlstream"
    gid "admin"
    supports :manage_home => true
end

directory "/usr/local/sqlstream" do
  owner "sqlstream"
  group "sqlstream"
  mode "0755"
  action :create
end

directory "/usr/local/lib/sqlstream" do
  owner "sqlstream"
  group "sqlstream"
  mode "0755"
  action :create
end

bash "adjust-sqlstream-bash-env" do
  code <<-EOH
  echo "export JAVA_HOME=/usr/local/JDK1.6" >> /home/sqlstream/.bashrc
  echo "export SQLSTREAM_HOME=/usr/local/sqlstream/SQLstream-2.5" >> /home/sqlstream/.bashrc
  echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> /home/sqlstream/.bashrc
  EOH
end

template "/home/sqlstream/.s3cfg" do
  source "dot.s3cfg.erb"
  owner "sqlstream"
  variables(
      :aws_access_key => node[:sqlstream][:binary_retrieve_id],
      :aws_access_secret => node[:sqlstream][:binary_retrieve_secret]
  )
end

bash "retrieve-sqlstream-binary" do
  code <<-EOH
  mkdir /home/sqlstream/binary
  cd /home/sqlstream/binary
  #{node[:sqlstream][:binary_retrieve_command]}
  chown -R sqlstream /home/sqlstream/binary
  EOH
end


