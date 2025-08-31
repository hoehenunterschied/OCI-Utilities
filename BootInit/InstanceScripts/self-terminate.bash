#!/usr/bin/env bash

export OCI_CLI_AUTH="instance_principal"

idiot_counter()
{
   ############################################################
   # force user to type a random string to avoid
   # accidental execution of potentially damaging functions
   ############################################################
   # if tr does not work in the line below, try this:
   #  export STUPID_STRING=$(cat /dev/urandom|LC_ALL=C tr -dc "[:alnum:]"|fold -w 6|head -n 1)
   ############################################################
   export STUPID_STRING="k4JgHrt"
   if [ -e /dev/urandom ];then
     export STUPID_STRING=$(cat /dev/urandom|LC_CTYPE=C tr -dc "[:alnum:]"|fold -w 6|head -n 1)
   fi
   echo -e "#### type \"${STUPID_STRING}\" to approve the above operation ####\n"
   idiot_counter=0
   while true; do
     read line
     case $line in
       ${STUPID_STRING}) break;;
       *)
         idiot_counter=$(($(($idiot_counter+1))%2));
         if [[ $idiot_counter == 0 ]];then
           echo -e "###\n### YOU FAIL !\n###\n### exiting..."; exit;
         fi
         echo "#### type \"${STUPID_STRING}\" to approve the operation above, CTRL-C to abort";
         ;;
     esac
   done
}

if [[ "${DONT_ASK}" != "true"  ]]; then
  idiot_counter
fi

oci compute instance terminate --force --instance-id "$(oci-instanceid)"
