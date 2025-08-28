#!/bin/bash
# this script runs on rpiconnect.katogana.de
#
# Puts encrypted and signed commands 'enabled' or 'disabled'
# into the html root of the web server.
# Names of the created files match <hostname>.txt.asc
# A cronjob on a Raspberry Pi checks the existence of a file
# http://rpiconnect.katogana.de/<hostname>.txt.asc, downloads,
# and decrypts it. Depending on the content the Raspberry Pi
# switches rpi-connect on or off.
#
# to prepare a Oracle Linux 9 instance:
# sudo dnf -y install httpd
# sudo systemctl enable httpd
# sudo systemctl start httpd
# firewall-cmd --get-active-zones
# sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
# sudo firewall-cmd --reload
HTML_DIR="/var/www/html"

# filename of this script
THIS_SCRIPT="$(basename ${BASH_SOURCE})"

if [[ "$EUID" -ne 0 ]]; then
    exec sudo "${BASH_SOURCE}" "$@"
fi

usage() {
echo -e "\nUsage:\n======"
echo -e "         ${THIS_SCRIPT} {raspi4|raspi5|piserv|grok} {enable|disable}"
echo -e "           write the enable/disable file to ${HTML_DIR}"
echo -e ""
echo -e "         ${THIS_SCRIPT} ALL {enable|disable}"
echo -e "           write all enable/disable files at once"
echo -e ""
echo -e "         ${THIS_SCRIPT} {raspi4|raspi5|piserv|grok|ALL} rm"
echo -e "           remove the enable/disable file(s) from ${HTML_DIR}"
}

write_enable_file() {
  case $1 in
    raspi4|raspi5|piserv|grok)
      cat > "${HTML_DIR}/${1}.txt.asc" << EOF
-----BEGIN PGP MESSAGE-----

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
=pRXK
-----END PGP MESSAGE-----
EOF
      ;;

    ALL)
      write_enable_file raspi4
      write_enable_file raspi5
      write_enable_file piserv
      write_enable_file grok
      ;;

    *)
      usage
      ;;
  esac
}

write_disable_file() {
  case $1 in
    raspi4|raspi5|piserv|grok)
      cat > "${HTML_DIR}/${1}.txt.asc" << EOF
-----BEGIN PGP MESSAGE-----

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
=aEp9
-----END PGP MESSAGE-----
EOF
      ;;

    ALL)
      write_disable_file raspi4
      write_disable_file raspi5
      write_disable_file piserv
      write_disable_file grok
      ;;

    *)
      return;
      ;;
  esac
}

delete_file() {
  case $1 in
    raspi4|raspi5|piserv|grok)
      rm -f "${HTML_DIR}/${1}.txt.asc" 
      ;;

    ALL)
      rm -f "${HTML_DIR}/raspi4.txt.asc" 
      rm -f "${HTML_DIR}/raspi5.txt.asc" 
      rm -f "${HTML_DIR}/piserv.txt.asc" 
      rm -f "${HTML_DIR}/grok.txt.asc" 
      ;;

    *)
      return;
      ;;
  esac
}

if [ "$#" != "2" ]; then
  usage
  exit
fi
case $1 in
  raspi4|raspi5|piserv|grok|ALL)
    ;;
  
  *)
    usage
    exit
    ;;
esac

case $2 in
  enable)
    write_enable_file $1
    ;;
  disable)
    write_disable_file $1
    ;;
  rm)
    delete_file $1
    ;;
  
  *)
    usage
    exit
    ;;
esac

