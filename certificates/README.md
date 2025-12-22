# Certificates
For some reason I don't know yet, cargo doesn't seem to use the certificates that are in tinycore. The ca-certificates are installed, but it doesn't seem to use them.
Here is why I have the workaround documented below. While working on the workaround, I learned some things that I documented below.
Eventually, I would like to have cargo use the certificates already installed in tinycore and not rely on the workaround below.

## Cross Certification
I found it odd that openssl s_client and firefox do not give me the same root CA.

Here are the reasons:
- [a forum answer here](https://serverfault.com/questions/798991/ssl-certificates-certificate-chain-different-between-openssl-and-browsers)
- claud.ai answered with "A certificate can effectively be signed by two different CAs through the cross-certificate mechanism, though it's not quite the same as having two signatures on a single certificate.
What actually happens is:

Multiple valid paths: The certificate itself has one direct issuer, but cross-certificates create multiple valid certification paths that lead to different trusted roots.
Path options: When validating a certificate, software can find and verify different paths through the PKI hierarchy to reach a trusted root.

For example:

A website certificate might be issued by "Intermediate CA X"
This intermediate could have two valid parent certificates:

One signed by "Root CA A"
Another signed by "Root CA B" (via cross-signing)

This means clients could validate the website certificate through either root, depending on which roots they trust.
This approach is commonly used during root CA transitions. When introducing a new root CA, the new root might issue certificates for the same intermediates as the old root. This ensures that clients trusting either the old or new root can validate certificates issued by those intermediates during the transition period.
So while the certificate itself has just one direct issuer, cross-certificates create multiple valid trust paths, effectively giving the certificate multiple trust anchors."

# index.crates.io and crates.io
## 2025-12-21 - 1.92.0
I got some issues with certificates again. I copied `get-certificate.sh` in this folder to get the
changed certificates. I don't validate manually with Firefox manually anymore. The certificates I
used are in the repo if further validation is needed.
After `compare-certificate.sh` worked I stil had an issue on `./x.py dist` as it would still fail
with SSL error 60, I have no idea what changed in tinycore's tczs to cause this. The fix is to add
the following environment variables
`SSL_CERT_FILE=/usr/local/etc/ssl/certs/ca-certificates.crt SSL_CERT_DIR=/usr/local/etc/ssl/certs`.
## 2025-11-01
The server uses "Amazon RSA 2048 M04" as the CA. I checked using Debian 11 and Firefox that I get
the same information when going at https://index.crates.io.
The new validity is Not Before: Oct 26 00:00:00 2025 GMT, Not After : Nov 24 23:59:59 2026 GMT and
the X509v3 Authority Key Identifier is keyid:1F:52:92:61:56:82:54:7F:81:66:D8:1D:3D:0A:AA:32:5C:87:DD:08.
I got the certificate using
`echo "Q" | openssl s_client -showcerts -timeout -servername index.crates.io index.crates.io:443 2>&1 | sed --quiet '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > 2025-11-01_index-crates-io.crt`
and read the certificate information with
`openssl x509 -in  2025-11-01_index-crates-io.crt -text -noout`
. I got also the 2025-11-01_crates.io certificate in a similar way. I replaced the
crates-io-chain.crt with it. I got 2025-11-01_amazon-rsa-2048-m04.pem and
2025-11-01_amazon-root-ca-1.pem using firefox. As far as I can see. Using these certificates is right.
## 2025-04
I could validate that [crates-io-chain.crt](./crates-io-chain.crt) taken with openssl s_client gives this root CA
```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            06:7f:94:4a:2a:27:cd:f3:fa:c2:ae:2b:01:f9:08:ee:b9:c4:c6
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = US, ST = Arizona, L = Scottsdale, O = "Starfield Technologies, Inc.", CN = Starfield Services Root Certificate Authority - G2
        Validity
            Not Before: May 25 12:00:00 2015 GMT
            Not After : Dec 31 01:00:00 2037 GMT
        Subject: C = US, O = Amazon, CN = Amazon Root CA 1
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:b2:78:80:71:ca:78:d5:e3:71:af:47:80:50:74:
                    7d:6e:d8:d7:88:76:f4:99:68:f7:58:21:60:f9:74:
                    84:01:2f:ac:02:2d:86:d3:a0:43:7a:4e:b2:a4:d0:
                    36:ba:01:be:8d:db:48:c8:07:17:36:4c:f4:ee:88:
                    23:c7:3e:eb:37:f5:b5:19:f8:49:68:b0:de:d7:b9:
                    76:38:1d:61:9e:a4:fe:82:36:a5:e5:4a:56:e4:45:
                    e1:f9:fd:b4:16:fa:74:da:9c:9b:35:39:2f:fa:b0:
                    20:50:06:6c:7a:d0:80:b2:a6:f9:af:ec:47:19:8f:
                    50:38:07:dc:a2:87:39:58:f8:ba:d5:a9:f9:48:67:
                    30:96:ee:94:78:5e:6f:89:a3:51:c0:30:86:66:a1:
                    45:66:ba:54:eb:a3:c3:91:f9:48:dc:ff:d1:e8:30:
                    2d:7d:2d:74:70:35:d7:88:24:f7:9e:c4:59:6e:bb:
                    73:87:17:f2:32:46:28:b8:43:fa:b7:1d:aa:ca:b4:
                    f2:9f:24:0e:2d:4b:f7:71:5c:5e:69:ff:ea:95:02:
                    cb:38:8a:ae:50:38:6f:db:fb:2d:62:1b:c5:c7:1e:
                    54:e1:77:e0:67:c8:0f:9c:87:23:d6:3f:40:20:7f:
                    20:80:c4:80:4c:3e:3b:24:26:8e:04:ae:6c:9a:c8:
                    aa:0d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
            X509v3 Subject Key Identifier: 
                84:18:CC:85:34:EC:BC:0C:94:94:2E:08:59:9C:C7:B2:10:4E:0A:08
            X509v3 Authority Key Identifier: 
                keyid:9C:5F:00:DF:AA:01:D7:30:2B:38:88:A2:B8:6D:4A:9C:F2:11:91:83

            Authority Information Access: 
                OCSP - URI:http://ocsp.rootg2.amazontrust.com
                CA Issuers - URI:http://crt.rootg2.amazontrust.com/rootg2.cer

            X509v3 CRL Distribution Points: 

                Full Name:
                  URI:http://crl.rootg2.amazontrust.com/rootg2.crl

            X509v3 Certificate Policies: 
                Policy: X509v3 Any Policy

    Signature Algorithm: sha256WithRSAEncryption
         62:37:42:5c:bc:10:b5:3e:8b:2c:e9:0c:9b:6c:45:e2:07:00:
         7a:f9:c5:58:0b:b9:08:8c:3e:ed:b3:25:3c:b5:6f:50:e4:cd:
         35:6a:a7:93:34:96:32:21:a9:48:44:ab:9c:ed:3d:b4:aa:73:
         6d:e4:7f:16:80:89:6c:cf:28:03:18:83:47:79:a3:10:7e:30:
         5b:ac:3b:b0:60:e0:77:d4:08:a6:e1:1d:7c:5e:c0:bb:f9:9a:
         7b:22:9d:a7:00:09:7e:ac:46:17:83:dc:9c:26:57:99:30:39:
         62:96:8f:ed:da:de:aa:c5:cc:1b:3e:ca:43:68:6c:57:16:bc:
         d5:0e:20:2e:fe:ff:c2:6a:5d:2e:a0:4a:6d:14:58:87:94:e6:
         39:31:5f:7c:73:cb:90:88:6a:84:11:96:27:a6:ed:d9:81:46:
         a6:7e:a3:72:00:0a:52:3e:83:88:07:63:77:89:69:17:0f:39:
         85:d2:ab:08:45:4d:d0:51:3a:fd:5d:5d:37:64:4c:7e:30:b2:
         55:24:42:9d:36:b0:5d:9c:17:81:61:f1:ca:f9:10:02:24:ab:
         eb:0d:74:91:8d:7b:45:29:50:39:88:b2:a6:89:35:25:1e:14:
         6a:47:23:31:2f:5c:9a:fa:ad:9a:0e:62:51:a4:2a:a9:c4:f9:
         34:9d:21:18
```
which is the Amazon Root CA 1 as far as I can understand by reading 
[How to Prepare for AWS’s Move to Its Own Certificate Authority](https://aws.amazon.com/blogs/security/how-to-prepare-for-aws-move-to-its-own-certificate-authority/)
isolating the root CA in its own PEM/.crt file and running these commands:
``
openssl x509 -in amazon-root-ca1-via-openssl.crt -noout -pubkey | openssl asn1parse -noout -inform pem -out amazon-root-ca1-via-openssl.crt.key
openssl dgst -sha256 amazon-root-ca1-via-openssl.crt.key
```
which results in `fbe3018031f9586bcbf41727e417b7d1c45c2f47f93be372a17b96b50757d5a2`.
which matches the [Amazon Root CA 1 of the Amazon Trust Services page](https://www.amazontrust.com/repository/).

I put in the certificates folder:
- [AmazonRootCA1.pem](./AmazonRootCA1.pem) which I took from [the Amazon Trust Services page](https://www.amazontrust.com/repository/) 
- [amazon-root-ca1-via-openssl.crt](./amazon-root-ca1-via-openssl.crt) which I got from openssl s_client
- [amazon-root-ca1-via-firefox.crt](./amazon-root-ca1-via-firefox.crt) which I got from manually inspecting the certificate with firefox.
Using `diff -u -Z certificates/AmazonRootCA1.pem certificates/amazon-root-ca1-via-firefox.crt` certs are matching.
Using `diff -u -Z certificates/AmazonRootCA1.pem certificates/amazon-root-ca1-via-openssl.crt` certs are different.

Here's some more info:
```
$ openssl x509 -in certificates/AmazonRootCA1.pem -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            06:6c:9f:cf:99:bf:8c:0a:39:e2:f0:78:8a:43:e6:96:36:5b:ca
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = US, O = Amazon, CN = Amazon Root CA 1
        Validity
            Not Before: May 26 00:00:00 2015 GMT
            Not After : Jan 17 00:00:00 2038 GMT
        Subject: C = US, O = Amazon, CN = Amazon Root CA 1
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:b2:78:80:71:ca:78:d5:e3:71:af:47:80:50:74:
                    7d:6e:d8:d7:88:76:f4:99:68:f7:58:21:60:f9:74:
                    84:01:2f:ac:02:2d:86:d3:a0:43:7a:4e:b2:a4:d0:
                    36:ba:01:be:8d:db:48:c8:07:17:36:4c:f4:ee:88:
                    23:c7:3e:eb:37:f5:b5:19:f8:49:68:b0:de:d7:b9:
                    76:38:1d:61:9e:a4:fe:82:36:a5:e5:4a:56:e4:45:
                    e1:f9:fd:b4:16:fa:74:da:9c:9b:35:39:2f:fa:b0:
                    20:50:06:6c:7a:d0:80:b2:a6:f9:af:ec:47:19:8f:
                    50:38:07:dc:a2:87:39:58:f8:ba:d5:a9:f9:48:67:
                    30:96:ee:94:78:5e:6f:89:a3:51:c0:30:86:66:a1:
                    45:66:ba:54:eb:a3:c3:91:f9:48:dc:ff:d1:e8:30:
                    2d:7d:2d:74:70:35:d7:88:24:f7:9e:c4:59:6e:bb:
                    73:87:17:f2:32:46:28:b8:43:fa:b7:1d:aa:ca:b4:
                    f2:9f:24:0e:2d:4b:f7:71:5c:5e:69:ff:ea:95:02:
                    cb:38:8a:ae:50:38:6f:db:fb:2d:62:1b:c5:c7:1e:
                    54:e1:77:e0:67:c8:0f:9c:87:23:d6:3f:40:20:7f:
                    20:80:c4:80:4c:3e:3b:24:26:8e:04:ae:6c:9a:c8:
                    aa:0d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
            X509v3 Subject Key Identifier: 
                84:18:CC:85:34:EC:BC:0C:94:94:2E:08:59:9C:C7:B2:10:4E:0A:08
    Signature Algorithm: sha256WithRSAEncryption
         98:f2:37:5a:41:90:a1:1a:c5:76:51:28:20:36:23:0e:ae:e6:
         28:bb:aa:f8:94:ae:48:a4:30:7f:1b:fc:24:8d:4b:b4:c8:a1:
         97:f6:b6:f1:7a:70:c8:53:93:cc:08:28:e3:98:25:cf:23:a4:
         f9:de:21:d3:7c:85:09:ad:4e:9a:75:3a:c2:0b:6a:89:78:76:
         44:47:18:65:6c:8d:41:8e:3b:7f:9a:cb:f4:b5:a7:50:d7:05:
         2c:37:e8:03:4b:ad:e9:61:a0:02:6e:f5:f2:f0:c5:b2:ed:5b:
         b7:dc:fa:94:5c:77:9e:13:a5:7f:52:ad:95:f2:f8:93:3b:de:
         8b:5c:5b:ca:5a:52:5b:60:af:14:f7:4b:ef:a3:fb:9f:40:95:
         6d:31:54:fc:42:d3:c7:46:1f:23:ad:d9:0f:48:70:9a:d9:75:
         78:71:d1:72:43:34:75:6e:57:59:c2:02:5c:26:60:29:cf:23:
         19:16:8e:88:43:a5:d4:e4:cb:08:fb:23:11:43:e8:43:29:72:
         62:a1:a9:5d:5e:08:d4:90:ae:b8:d8:ce:14:c2:d0:55:f2:86:
         f6:c4:93:43:77:66:61:c0:b9:e8:41:d7:97:78:60:03:6e:4a:
         72:ae:a5:d1:7d:ba:10:9e:86:6c:1b:8a:b9:59:33:f8:eb:c4:
         90:be:f1:b9
$ openssl x509 -in certificates/amazon-root-ca1-via-openssl.crt -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            06:7f:94:4a:2a:27:cd:f3:fa:c2:ae:2b:01:f9:08:ee:b9:c4:c6
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = US, ST = Arizona, L = Scottsdale, O = "Starfield Technologies, Inc.", CN = Starfield Services Root Certificate Authority - G2
        Validity
            Not Before: May 25 12:00:00 2015 GMT
            Not After : Dec 31 01:00:00 2037 GMT
        Subject: C = US, O = Amazon, CN = Amazon Root CA 1
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:b2:78:80:71:ca:78:d5:e3:71:af:47:80:50:74:
                    7d:6e:d8:d7:88:76:f4:99:68:f7:58:21:60:f9:74:
                    84:01:2f:ac:02:2d:86:d3:a0:43:7a:4e:b2:a4:d0:
                    36:ba:01:be:8d:db:48:c8:07:17:36:4c:f4:ee:88:
                    23:c7:3e:eb:37:f5:b5:19:f8:49:68:b0:de:d7:b9:
                    76:38:1d:61:9e:a4:fe:82:36:a5:e5:4a:56:e4:45:
                    e1:f9:fd:b4:16:fa:74:da:9c:9b:35:39:2f:fa:b0:
                    20:50:06:6c:7a:d0:80:b2:a6:f9:af:ec:47:19:8f:
                    50:38:07:dc:a2:87:39:58:f8:ba:d5:a9:f9:48:67:
                    30:96:ee:94:78:5e:6f:89:a3:51:c0:30:86:66:a1:
                    45:66:ba:54:eb:a3:c3:91:f9:48:dc:ff:d1:e8:30:
                    2d:7d:2d:74:70:35:d7:88:24:f7:9e:c4:59:6e:bb:
                    73:87:17:f2:32:46:28:b8:43:fa:b7:1d:aa:ca:b4:
                    f2:9f:24:0e:2d:4b:f7:71:5c:5e:69:ff:ea:95:02:
                    cb:38:8a:ae:50:38:6f:db:fb:2d:62:1b:c5:c7:1e:
                    54:e1:77:e0:67:c8:0f:9c:87:23:d6:3f:40:20:7f:
                    20:80:c4:80:4c:3e:3b:24:26:8e:04:ae:6c:9a:c8:
                    aa:0d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
            X509v3 Subject Key Identifier: 
                84:18:CC:85:34:EC:BC:0C:94:94:2E:08:59:9C:C7:B2:10:4E:0A:08
            X509v3 Authority Key Identifier: 
                keyid:9C:5F:00:DF:AA:01:D7:30:2B:38:88:A2:B8:6D:4A:9C:F2:11:91:83

            Authority Information Access: 
                OCSP - URI:http://ocsp.rootg2.amazontrust.com
                CA Issuers - URI:http://crt.rootg2.amazontrust.com/rootg2.cer

            X509v3 CRL Distribution Points: 

                Full Name:
                  URI:http://crl.rootg2.amazontrust.com/rootg2.crl

            X509v3 Certificate Policies: 
                Policy: X509v3 Any Policy

    Signature Algorithm: sha256WithRSAEncryption
         62:37:42:5c:bc:10:b5:3e:8b:2c:e9:0c:9b:6c:45:e2:07:00:
         7a:f9:c5:58:0b:b9:08:8c:3e:ed:b3:25:3c:b5:6f:50:e4:cd:
         35:6a:a7:93:34:96:32:21:a9:48:44:ab:9c:ed:3d:b4:aa:73:
         6d:e4:7f:16:80:89:6c:cf:28:03:18:83:47:79:a3:10:7e:30:
         5b:ac:3b:b0:60:e0:77:d4:08:a6:e1:1d:7c:5e:c0:bb:f9:9a:
         7b:22:9d:a7:00:09:7e:ac:46:17:83:dc:9c:26:57:99:30:39:
         62:96:8f:ed:da:de:aa:c5:cc:1b:3e:ca:43:68:6c:57:16:bc:
         d5:0e:20:2e:fe:ff:c2:6a:5d:2e:a0:4a:6d:14:58:87:94:e6:
         39:31:5f:7c:73:cb:90:88:6a:84:11:96:27:a6:ed:d9:81:46:
         a6:7e:a3:72:00:0a:52:3e:83:88:07:63:77:89:69:17:0f:39:
         85:d2:ab:08:45:4d:d0:51:3a:fd:5d:5d:37:64:4c:7e:30:b2:
         55:24:42:9d:36:b0:5d:9c:17:81:61:f1:ca:f9:10:02:24:ab:
         eb:0d:74:91:8d:7b:45:29:50:39:88:b2:a6:89:35:25:1e:14:
         6a:47:23:31:2f:5c:9a:fa:ad:9a:0e:62:51:a4:2a:a9:c4:f9:
         34:9d:21:18
```
In the page [How to Prepare for AWS’s Move to Its Own Certificate Authority](https://aws.amazon.com/blogs/security/how-to-prepare-for-aws-move-to-its-own-certificate-authority/)
it is written that "To maintain the ubiquity of the Amazon Trust Services CA, AWS purchased the Starfield Services CA, a root found in most browsers and which has been valid since 2005. This means you shouldn’t have to take action to use the certificates issued by Amazon Trust Services"
so both should be valid and if I understand correctly, this is an example of cross-certification.

# static.crates.io
### 2025-11-01
The server still uses "GlobalSign Atlas R3 DV TLS CA 2025 Q3".
### Previously
This uses the "GlobalSign Atlas R3 DV TLS CA Q4 2024" root CA which can be found on [Atlas TLS ICA Rotations](https://support.globalsign.com/atlas/atlas-tls/atlas-tls-ica-rotations)
On 2025-09-20, the certificate has now root CA "GlobalSign Atlas R3 DV TLS CA 2025 Q3". I put that one in the [static-crates-io-chain2.crt](./static-crates-io-chain2.crt) file. I'm using both `static-crates-io-chain.crt` which has the previous root CA and `static-crates-io-chain2.crt` which has the new root CA. I may rotate the certificates once a new root CA appears.
