# Create own CA and certificates for LDAP

## Quick Explanation

I gonna explain how create own CA for sign certificates and how create a certificate for the LDAP server and sign it.

## How to 

- Create the CA

      openssl genrsa -des3 -out cakey.pem 1024

- create the CA certificate :

      openssl req -new -key cakey.pem -x509 -days 1095 -out cacert.pem


- For each ldap server (if you have more than one)
   create a key :
      
      openssl genrsa -out ldapkey.pem

- create a servercert.pem certificate request (Note: _Is so important put in Common Name the FQDN of the LDAP Server_:

      openssl req -new -key ldapkey.pem -out server.pem

- create the ldapcert.pem certificate signed by your own CA :

      openssl x509 -req -days 2000 -in server.pem -CA cacert.pem -CAkey cakey.pem -CAcreateserial -out ldapcert.pem


Now we have created our own CA and certificates signed.
