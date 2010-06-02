Chef cookbooks for the OOI CEI
==============================


Install on Ubuntu 10.04
-----------------------
See 'chef_install.sh' for complete Chef install script.


Examples
--------

- 'solo.rb' is the config file for 'chef-solo'. 
- 'attributes.rb' is where you put deploy specific vars.

Normal run, make sure cookbook dir is specified in 'solo.rb':

    $ chef-solo -l debug -c solo.rb -j attributes.rb

Use remote cookbook, in tarball that untars to dir specified in 'solo.rb':

    $ chef-solo -l debug -c solo.rb -j attributes.rb -r http://example.com/mycookbooks.tar.gz
