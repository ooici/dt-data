#Platform specific opts:
case platform
when "redhat","centos","fedora"
  set[:magnet][:foo] = "redhat-foo"
when "debian","ubuntu"
  set[:magnet][:foo] = "debian-foo"
end

#Tunable opts:
set_unless[:magnet][:broker_host] = "amoeba.ucsd.edu"
set_unless[:magnet][:broker_port] = "5672"
set_unless[:magnet][:username] = "guest"
set_unless[:magnet][:password] = "guest"
set_unless[:magnet][:vhost] = "/"
