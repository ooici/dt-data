
# Git resource seems broken?
script "Extract OpenTSDB" do
  interpreter "bash"
  code <<-EOH
  git clone #{node[:opentsdb][:git_url]} opentsdb
  EOH
  cwd "/opt"
end

package "gnuplot" do
  action :install
end

execute "Build OpenTSDB" do
  command "./build.sh"
  cwd "/opt/opentsdb"
end

execute "Install OpenTSDB" do
  command "make install"
  cwd "/opt/opentsdb/build/"
end

execute "Create HBase Tables" do
  command "./src/create_table.sh"
  cwd "/opt/opentsdb"
  environment ({'COMPRESSION' => 'none', 'HBASE_HOME' => node[:hbase][:location], 'JAVA_HOME' => '/usr/lib/jvm/java'})
end

directory "/tmp/tsd" do
  action :create
end

bash "Start TSD" do
  code <<-EOH
  tsdb tsd --port=#{node[:opentsdb][:port]} --staticroot=/usr/local/share/opentsdb/static --cachedir=/tmp/tsd --auto-metric &
  EOH
end
