
directory "/etc/ssl/rabbitmq/" do
  owner "root"
  mode 0755
end

directory "/etc/ssl/rabbitmq/testca/" do
  owner "root"
  mode 0755
end

directory "/etc/ssl/rabbitmq/server" do
  owner "root"
  mode 0755
end

directory "/etc/ssl/rabbitmq/testca/certs" do
  owner "root"
  mode 0755
end

directory "/etc/ssl/rabbitmq/testca/private" do
  owner "root"
  mode 0700
end

template "/etc/ssl/rabbitmq/testca/openssl.cnf" do
  source "openssl.cnf.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/etc/ssl/rabbitmq/testca/serial" do
  source "serial.erb"
  owner "root"
  group "root"
  mode 0644
end

template "/etc/ssl/rabbitmq/testca/index.txt" do
  source "index.txt.erb"
  owner "root"
  group "root"
  mode 0644
end


bash "Create SSL CA" do
  
  cwd "/etc/ssl/rabbitmq/testca"
  code <<-EOH

  openssl req -x509 -config openssl.cnf -newkey rsa:2048 -days 365 \
    -out cacert.pem -outform PEM -subj /CN=MyTestCA/ -nodes
  openssl x509 -in cacert.pem -out cacert.cer -outform DER

  EOH
  not_if { File.exists?("/etc/ssl/rabbitmq/testca/cacert.pem") }
end

bash "Create SSL Certificates" do

  cwd "/etc/ssl/rabbitmq/server"
  code <<-EOH

  openssl genrsa -out key.pem 2048
  openssl req -new -key key.pem -out req.pem -outform PEM \
    -subj /CN=$(hostname)/O=server/ -nodes

  EOH
  not_if { File.exists?("/etc/ssl/rabbitmq/server/req.pem") }
end

bash "Create SSL Server Certificates" do

  cwd "/etc/ssl/rabbitmq/testca"
  code <<-EOH

openssl ca -config openssl.cnf -in ../server/req.pem -out \
    ../server/cert.pem -notext -batch -extensions server_ca_extensions

  EOH
  not_if { File.exists?("/etc/ssl/rabbitmq/server/cert.pem") }
end

