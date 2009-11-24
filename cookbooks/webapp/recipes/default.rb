include_recipe "twisted"

bash "run-webapp" do
  user "root"
  code <<-EOH
  twistd web --path #{node[:serve_path]} --port 80
  EOH
end

