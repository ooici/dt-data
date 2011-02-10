set_unless[:nimbus][:service][:location] = "/opt/nimbus"
set_unless[:nimbus][:service][:user] = "nimbus"
set_unless[:nimbus][:service][:group] = "nimbus"
set_unless[:nimbus][:service][:src_checksum] = "814c804a8b3aa2e04d6ce94b66f5e90e"
set_unless[:nimbus][:service][:src_version] = "2.6"
set_unless[:nimbus][:service][:src_name] = "nimbus-#{nimbus[:service][:src_version]}-src.tar.gz"
set_unless[:nimbus][:service][:src_mirror] = "http://www.nimbusproject.org/downloads/#{nimbus[:service][:src_name]}"
set_unless[:nimbus][:users] = []
