#
# Cookbook Name:: postgres
# Recipe:: default
#
# Copyright 2013, Copyright 2011, Ocean Observatories Initiative, UCSD
#
# All rights reserved - Do Not Redistribute
#

template "/var/lib/pgsql/9.3/data/pg_hba.conf" do
  owner "postgres"
  mode 0600
  source "pg_hba.conf.erb"
end

service "postgresql-9.3" do
  action :restart
end

execute "create-admin-user" do
    code = <<-EOH
    psql -U postgres -c "select * from pg_user;" | grep -c #{node['postgres']['admin_username']}
    EOH
    user "postgres"
    command <<-EOH
    echo "CREATE ROLE #{node['postgres']['admin_username']} ENCRYPTED PASSWORD '#{node['postgres']['admin_password']}' SUPERUSER CREATEDB CREATEROLE INHERIT LOGIN;" | psql
    EOH
    not_if code 
end

execute "create-db-user" do
    code = <<-EOH
    psql -U postgres -c "select * from pg_user;" | grep -c #{node['postgres']['username']}
    EOH
    user "postgres"
    command <<-EOH
    echo "CREATE ROLE #{node['postgres']['username']} ENCRYPTED PASSWORD '#{node['postgres']['password']}' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;" | psql
    EOH
    not_if code 
end

