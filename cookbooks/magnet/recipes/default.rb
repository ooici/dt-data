include_recipe "twisted"
include_recipe "txamqp"

remote_file "/tmp/magnet.tar.gz" do
  source "http://sddevrepo.oceanobservatories.org/cpe/resources/magnet-latest.tar.gz"
end

bash "untar-magnet" do
  code "(cd /tmp; tar -zxvf magnet.tar.gz)"
end

bash "install-magnet" do
  code "(cd /tmp/magnet; python setup.py install)"
end
