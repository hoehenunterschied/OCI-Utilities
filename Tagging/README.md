# Tagging Utilities

## About

The scripts manipulate defined tags of resources. Defined tags can be read from resources and saved, restored to the saved state or bulk updated.
All scripts read a file params.txt which sets up environment variables for the script. Not all environment variables are used by all scripts. See the comment section at the top of the scripts to check which variables are used by a script.<br>
All scripts use OCI CLI. A section of the scripts tries to activate a Python virtual environment. If your OCI CLI installation does not use a virtual environment, the section between the lines
 `# Begin VENV setup` and `# End VENV setup` can be commented out. But the command `oci` must work after the line `# End VENV setup`.

### save-tags.bash
The script works on compartment level. Structured search is used to retrieve a list of OCI resources of resource types as defined by `RESOURCES_TO_PROCESS` in params.txt. The OCID of the resource is used as the filename to store the defined tags of the resource. The location of the created files is defined by `RESOURCE_LIST_DIR`in params.txt. The path definition of `RESOURCE_LIST_DIR` in `params_template.txt` ends with the compartment ocid as name of the subdirectory to write files into.
### restore-tags.bash
When defined tag information has been saved by using `save-tags.bash`, this script can write back the saved defined tags to the resources. Note that tags for some resources can't be changed after their creation. Vnics of databases inherit the defined tags of the dbsystem or autonomous-database at the time of provisioning. Changing the tags of a dbsystem or autonomous-database does not propagate the change to the vnic. When the defined tags of a resource can't be updated, the error message is displayed and the script continues to process the next resource.
### bulk-apply-tags.bash
In its current form the script bulk updates all resources of the specified types (see `RESOURCES_TO_PROCESS` in params_template.txt) in the compartment given by `COMPARTMENT_ID` to the same set of defined tags. Either change the structured search which is used in the script to generate the list of resources to change, or edit the generated resource list before bulk applying the defined tags to limit which resources are updated.
### db-system-vnic-tag.bash
Used to demonstrate the unmutable defined tags of a vnic that has been created as part of database provisioning. Provision a new demo database of the Base Database Service and set its `DISPLAY_NAME` and `COMPARTMENT_ID` in params.txt. Make sure the database is provisionied with some defined tags at the time of provisioning. The script displays the defined tags of the the database system and the vnic, then removes the defined tags from the databse. This change of defined tags is not propagated to the vnic. When trying to change the defined tags of the vnic, an error message is displayed.
### work-request.bash
Display the tagging work request given as command line parameter. When the parameter is omitted, the most recent accepted tagging work request.