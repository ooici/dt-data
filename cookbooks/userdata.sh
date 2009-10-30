#!/bin/bash
#user-data-file intended for AMI:ami-ccf615a5 (alestic.com Ubuntu 9.04 Jaunty)
set -e -x
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y
#install chef-solo ond ohai:
apt-get install -y ruby-dev rubygems
gem install chef ohai --no-ri --no-rdoc --source http://gems.opscode.com --source http://gems.rubyforge.org
ln -s /var/lib/gems/1.8/bin/chef-solo /usr/local/bin/
ln -s /var/lib/gems/1.8/bin/ohai /usr/local/bin/


