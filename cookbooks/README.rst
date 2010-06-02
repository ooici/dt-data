Chef cookbooks for the OOICI
============================


Install on Ubuntu 10.04
-----------------------
See 'chef_install.sh' for complete Chef install script.


Intro
-----

- 'chefconf.rb' is the config file for 'chef-solo'. 
- 'chefroles.rb' is where you put 'cookbooks' to be executed, and deploy specific data.


Examples
--------

Normal run, with local cookbooks:

    $ sudo chef-solo -l debug -c /opt/chef/chefconf.rb -j /opt/chef/chefroles.json 


Use remote cookbooks, in tarball that untars to dir specified in 'chefconf.rb':

    $ sudo chef-solo -l debug -c chefconf.rb -j chefroles.json -r http://example.com/mycookbooks.tar.gz
