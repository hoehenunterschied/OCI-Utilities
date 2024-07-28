# Resource Lists
### About
Scripts to display resources created by user, resources of selected resource types created by user in a compartment, all resources

### resourcelist.bash
```
Usage:
========
           list instances and autonomous databases : resourcelist.bash
                      list selected resource types : resourcelist.bash <resource list>

  Example for <resource list> : instance,autonomousdatabase,vnic

  For possible resource types, see
  https://docs.oracle.com/en-us/iaas/Content/Search/Concepts/queryoverview.htm#resourcetypes

```
### userresources.bash
The script assumes resources created by a user are identified by defined tags. Set the values for `TAG_NAMESPACE`, `TAG_KEY` and `USER` in the script. A single command line parameter overrides the value for `USER`.