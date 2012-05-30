#
# Author:: Seth Chisamore <schisamo@opscode.com>, Pierre Riteau <priteau@ci.uchicago.edu>
# Cookbook Name:: virtualenv
# Provider:: default
#
# Copyright:: 2011, Opscode, Inc <legal@opscode.com> and 2012, University of Chicago
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This LWP is based on the virtualenv LWP from the python cookbook, modified to
# fit ours needs.

action :create do
  unless exists?
    Chef::Log.info("Creating virtualenv #{@new_resource} at #{@new_resource.path}")
    execute "#{@new_resource.virtualenv} --python=#{@new_resource.python} #{@new_resource.path}" do
      user new_resource.owner if new_resource.owner
      group new_resource.group if new_resource.group
    end
  end
end

action :activate do
  ruby_block "set virtualenv environment variables" do
    block do
      ENV["VIRTUAL_ENV"] = new_resource.path
      ENV["PATH"] = ::File.join(new_resource.path, "bin") + ":" + ENV["PATH"]
    end
    not_if {ENV["VIRTUAL_ENV"] == new_resource.path}
  end
end

def virtualenv_cmd()
  if "#{node['python']['install_method']}".eql?("source")
    ::File.join("#{node['python']['prefix_dir']}","/bin/virtualenv")
  else
    "virtualenv"
  end
end

private
def exists?
  ::File.exist?(@new_resource.path) && ::File.directory?(@new_resource.path) \
    && ::File.exists?("#{@new_resource.path}/bin/activate")
end
