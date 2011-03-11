This directory contains deployable type (DT) information. There are two file
components for each DT: a JSON definition and an XML contextualization 
document template. Every DT has a distinc JSON file, keyed by its name but 
the XML document can be shared.

For the "foo" DT, there will be a foo.json file. This file may look like this:

{
    "document" : "common.xml",
    "vars" : {
        "a_var" : "a_value",
        "an_int" : 6
    },
    "sites" : {
        "ec2-east" : {
            "node1" : {
                "image" : "ami-12345678",
                "allocation" : "m1.large"
            },
            "node2" : {
                "image" : "ami-12345678",
                "allocation" : "m1.large"
            }
        },
        "ec2-west" : {
            "node1" : {
                "image": "ami-87654321",
                "allocation" : "m1.large"
            },
            "node2" : {
                "image": "ami-87654321",
                "allocation" : "m1.large"
            }
        }
    }
}


There are three components to note:
1. A contextualization document template. If this key/value pair was omitted,
   the document would be expected to be found in the foo.xml file (the DT name
   with a .xml extension).

2. Optional default values for insertion into the document template (vars).
   These values are overridden by ones passed into the DTRS at runtime.

3. Per-"site" IaaS information. These must correspond to the sites known by 
   the provisioner. For each site, there must be a dictionary of key/value
   pairs for each node in the cluster.

The contextualization documents are Nimbus cluster documents with optional
template variables of the form ${somename}.
