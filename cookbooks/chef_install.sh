#!/bin/bash
#
# Note: this script is intended to work on Ubuntu 10.04 server.
#
set -e -x
export DEBIAN_FRONTEND=noninteractive
#install chef-solo ond ohai:
sudo apt-get install -y ruby-dev libopenssl-ruby rubygems
sudo gem install chef ohai --no-ri --no-rdoc --source http://gems.opscode.com --source http://gems.rubyforge.org
sudo ln -s /var/lib/gems/1.8/bin/chef-solo /usr/local/bin/
sudo ln -s /var/lib/gems/1.8/bin/ohai /usr/local/bin/
