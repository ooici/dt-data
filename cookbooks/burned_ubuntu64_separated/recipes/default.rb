app_archive = "/tmp/app-archive.tar.gz"
app_dir = "/home/#{node[:username]}/app"

bash "Cleanup app_dir" do
  code <<-EOH
  rm -rf #{app_dir}
  EOH
end

case node[:appretrieve][:retrieve_method]
when "archive"
  if node[:appretrieve][:archive_url] =~ /(.*)\.tar\.gz$/
    print "url is tar.gz"
  else
    raise ArgumentError, 'archive_url is not tar.gz file'
  end
  remote_file app_archive do
    source node[:appretrieve][:archive_url]
    owner node[:username]
    group node[:username]
  end
  bash "expand-archive" do
    code <<-EOH
    cd /tmp
    tar xzf #{app_archive}
    mv /tmp/app-archive #{app_dir}
    mv #{app_archive} /tmp/previous__app-archive.tar.gz
    EOH
  end
end
when "git"
  bash "get-git" do
    code <<-EOH
    mkdir -p #{app_dir}
    git clone #{node[:appretrieve][:git_repo]} #{app_dir}/
    cd #{app_dir}
    git fetch --all
    git checkout -b activebranch origin/#{node[:appretrieve][:git_branch]}
    git pull
    git reset --hard #{node[:appretrieve][:git_commit]}
    EOH
  end
end
else raise ArgumentError, 'retrieve_method is not "archive" or "git"'

bash "give-app-user-ownership" do
  code <<-EOH
  chown -R #{node[:username]}:#{node[:username]} /home/#{node[:username]}
  if [ -f /opt/cei_environment ]; then
    chown #{node[:username]}:#{node[:username]} /opt/cei_environment
  fi
  EOH
end

bash "give-remote-user-log-access" do
  code <<-EOH
  if [ ! -d /home/#{node[:username]}/.ssh ]; then
    mkdir /home/#{node[:username]}/.ssh
  fi
  if [ -f /home/ubuntu/.ssh/authorized_keys ]; then
    cp /home/ubuntu/.ssh/authorized_keys /home/#{node[:username]}/.ssh/
  fi
  chown -R #{node[:username]} /home/#{node[:username]}/.ssh
  EOH
end

