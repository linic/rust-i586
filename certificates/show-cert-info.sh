#!/bin/sh
openssl x509 -in  $1 -text -noout
openssl x509 -in $1 -noout -pubkey | openssl asn1parse -noout -inform pem -out $1.key
openssl dgst -sha256 $1.key

