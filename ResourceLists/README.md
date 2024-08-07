# Resource Lists
### About
Scripts to display resources created by user, resources of selected resource types created by user in a compartment, all resources<br>
The scripts assume resources created by a user are identified by defined tags. Set the values for `TAG_NAMESPACE`, `TAG_KEY` and `USER` in the scripts. The value of `USER` is appended to the string `oracleidentitycloudservice/` to form the tag key value the script is searching for. If this does not apply in your environment, change the scripts.

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
A single command line parameter overrides the value for `USER`. The value of `USER` is appended to the string `oracleidentitycloudservice/` to form the tag key value the script is searching for. If this does not apply in your environment, change the script.
