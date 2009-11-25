include_recipe "twisted"

bash "index-page" do
  user "root"
  code <<-EOH
  echo "This node's IP is '#{node[:ec2][:public_ipv4]}'" > #{node[:serve_path]}/index.html
  EOH
end

bash "run-webapp" do
  user "root"
  code <<-EOH
  twistd web --path #{node[:serve_path]} --port 80
  EOH
end
