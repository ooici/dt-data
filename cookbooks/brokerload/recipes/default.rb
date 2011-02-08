# There is already an 'ioncore-python' directory in place.
bash "get-lcaarch" do
  code <<-EOH
  cd /home/#{node[:username]}
  cd ioncore-python
  git remote add thisone #{node[:capabilitycontainer][:git_lcaarch_repo]}
  git fetch --all
  git checkout -b activebranch thisone/#{node[:capabilitycontainer][:git_lcaarch_branch]}
  git pull
  git reset --hard #{node[:capabilitycontainer][:git_lcaarch_commit]}
  EOH
end

# Catch any dependency changes.  The burned requirements.txt is from commit
# caa5423d2c8293b077a8b381e6c6fd394a0987b3
bash "install-lcaarch-deps" do
  code <<-EOH
  cd /home/#{node[:username]}/ioncore-python
  pip install --quiet --find-links=#{node[:capabilitycontainer][:pip_package_repo]} --requirement=requirements.txt
  EOH
end

bash "twisted-plugin-issue" do
  code <<-EOH
  cp /home/#{node[:username]}/ioncore-python/twisted/plugins/cc.py /usr/local/lib/python2.6/dist-packages/twisted/plugins/
  EOH
end

bash "give-container-user-ownership" do
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


bash "load-test" do
  user node[:username]
  cwd "/home/#{node[:username]}/ioncore-python"
  environment({
    "HOME" => "/home/#{node[:username]}"
  })
  code <<-EOH
  set -e
  CPUS=`cat /proc/cpuinfo | grep ^'processor' | wc -l`
  nohup ion/test/loadtests/brokerload.sh --proc --count=$CPUS  -  --host "#{node[:capabilitycontainer][:broker]}" &
EOH
end

