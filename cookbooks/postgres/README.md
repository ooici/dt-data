postgres Cookbook
==============
Configures postgres users for OOI image

Requirements
------------
Assumes postgres server is already installed

Attributes
----------

postgres::username = db username (default = ion)
postgres::password = db password
postgres::admin_username = admin user (postgres super user)
postgres::admin_password = admin password


Usage
-----

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[postgres]"
  ]
}
```


License and Authors
-------------------
Authors: abrust@ucsd.edu
