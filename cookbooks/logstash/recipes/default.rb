#
# Cookbook Name:: logstash
# Recipe:: default
#
# Copyright 2012, University of Chicago
#

user node[:logstash][:username] do
  comment "Dynamically created user."
  gid "#{node[:logstash][:groupname]}"
  home "/home/#{node[:logstash][:username]}"
  shell "/bin/bash"
  supports :manage_home => true
end

case node[:platform]
when "debian","ubuntu"
  execute "Accept java licence" do
    command <<-EOH
    echo "sun-java6-jdk shared/accepted-sun-dlj-v1-1 select true" | debconf-set-selections
    echo "sun-java6-jre shared/accepted-sun-dlj-v1-1 select true" | debconf-set-selections
    EOH
  end
  package "default-jre-headless"
end

logstash_jar = "logstash-1.1.9-monolithic.jar"

remote_file "/home/#{node[:logstash][:username]}/#{logstash_jar}" do
  source "http://build.nimbusproject.org:8000/logstash/#{logstash_jar}"
  mode "0644"
  owner node[:logstash][:username]
  group node[:logstash][:groupname]
  checksum "e444e89a90583a75c2d6539e5222e2803621baa0ae94cb77dbbcebacdc0c3fc7"
end

cookbook_file "/home/#{node[:logstash][:username]}/logstash.conf" do
  source "logstash.conf"
  mode "0644"
  owner node[:logstash][:username]
  group node[:logstash][:groupname]
end

cookbook_file "/home/#{node[:logstash][:username]}/phantom-metrics.rb" do
  source "phantom-metrics.rb"
  mode "0644"
  owner node[:logstash][:username]
  group node[:logstash][:groupname]
end

execute "Run logstash" do
  user node[:logstash][:username]
  group node[:logstash][:groupname]
  cwd "/home/#{node[:logstash][:username]}"
  environment({
    'HOME' => "/home/#{node[:logstash][:username]}",
    'METRICS_USERNAME' => node[:logstash][:metrics_username],
    'METRICS_PASSWORD' => node[:logstash][:metrics_password]
  })
  command "nohup java -jar #{logstash_jar} agent -f logstash.conf &"
end
