set_unless[:torque][:service][:user] = "ubuntu"
set_unless[:torque][:service][:group] = "ubuntu"
set_unless[:torque][:service][:src_version] = "2.5.5"
set_unless[:torque][:service][:location] = "/opt/torque-#{torque[:service][:src_version]}"
set_unless[:torque][:service][:src_name] = "torque-#{torque[:service][:src_version]}.tar.gz"
set_unless[:torque][:service][:src_mirror] = "http://www.clusterresources.com/downloads/torque/#{torque[:service][:src_name]}"
set_unless[:torque][:users] = []
