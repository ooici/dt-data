default[:rsyslog][:port] = 514
default[:rsyslog][:protocol] = "udp"
default[:rsyslog][:directory] = "/var/log/external"
default[:rsyslog][:facility] = "local0"
default[:rsyslog][:user] = "syslog"
default[:rsyslog][:config_priority] = 10
