#!/bin/sh

###################################################################
# Copyright (C) 2025  linic@hotmail.ca Subject to GPL-3.0 license.#
# https://github.com/linic/rust-i586                              #
###################################################################

##################################################################
# cargo gave me certificate validation issues and this script
# helps with manual validation of the certificates.
##################################################################

CERTIFICATE_PATH=$1
DER=$2
echo $DER
if [ ! -z $DER ]; then
  echo "Converting $CERTIFICATE_PATH because $DER"
  cp $CERTIFICATE_PATH $CERTIFICATE_PATH.der
  openssl x509 -in $CERTIFICATE_PATH -inform DER -out $CERTIFICATE_PATH -outform PEM
fi
openssl x509 -in $CERTIFICATE_PATH -text -noout
openssl x509 -in $CERTIFICATE_PATH -noout -pubkey | openssl asn1parse -noout -inform pem -out $CERTIFICATE_PATH.key
openssl dgst -sha256 $CERTIFICATE_PATH.key

