set_unless[:contextbroker][:location] = "/usr/local/context-broker"
set_unless[:contextbroker][:user] = "contextbroker"
set_unless[:contextbroker][:group] = "contextbroker"
set_unless[:contextbroker][:src_checksum] = "1d93a3c04434fa9023af29f757f03c62"
set_unless[:contextbroker][:src_version] = "2.9"
set_unless[:contextbroker][:src_name] = "nimbus-ctxbroker-#{contextbroker[:src_version]}-src.tar.gz"
set_unless[:contextbroker][:src_mirror] = "http://www.nimbusproject.org/downloads/#{contextbroker[:src_name]}"
set_unless[:contextbroker][:users] = []
