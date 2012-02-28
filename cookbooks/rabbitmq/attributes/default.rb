default[:rabbitmq][:nodename]  = "rabbit"
default[:rabbitmq][:address]  = "0.0.0.0"
default[:rabbitmq][:port]  = "5672"
default[:rabbitmq][:erl_args]  = "+K true +A 30 \
-kernel inet_default_listen_options [{nodelay,true},{sndbuf,16384},{recbuf,4096}] \
-kernel inet_default_connect_options [{nodelay,true}]"
default[:rabbitmq][:start_args] = ""
default[:rabbitmq][:logdir] = "/var/log/rabbitmq"
default[:rabbitmq][:mnesiadir] = "/var/lib/rabbitmq/mnesia"
default[:rabbitmq][:cluster] = "no"
default[:rabbitmq][:cluster_config] = "/etc/rabbitmq/rabbitmq_cluster.config"
default[:rabbitmq][:cluster_disk_nodes] = []
default[:rabbitmq][:users] = {}

#ssl
default[:rabbitmq][:ssl] = false
default[:rabbitmq][:ssl_port] = '5671'
default[:rabbitmq][:ssl_cacert] = '/etc/ssl/rabbitmq/testca/cacert.pem'
default[:rabbitmq][:ssl_cert] = '/etc/ssl/rabbitmq/server/cert.pem'
default[:rabbitmq][:ssl_key] = '/etc/ssl/rabbitmq/server/key.pem'

