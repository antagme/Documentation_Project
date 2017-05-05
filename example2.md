# Example 2 - StartTLS LDAP Producer Server Replicating without SASL GSSAPI Auth and with it

## Overview
In this model, we will see how an _LDAP Server_ works as _Producer_ so that other _LDAP servers_ can replicate and act as Consumer.

We will have the _Consumer_ communicate with the _Producer_ through _simple authentication_.

On the other hand we will make another _Consumer_ do the same but through _SASL GSSAPI authentication_.

Finally we will verify that the **Client** can perform searches in both servers, and we will make modifications in the database of the _Producer_ and we will verify if it is really producing a correct replication.

_Docker Images_ used for this example:
- [Ldap StartTLS Producer + GSSAPI Keytab](https://hub.docker.com/r/antagme/ldap_producer/)
- [Kerberos](https://hub.docker.com/r/antagme/kerberos/)
- [Client for try some consults to Database](https://hub.docker.com/r/antagme/client_gssapi/)
- [Ldap StartTLS Consumer with Simple Authentication](https://hub.docker.com/r/antagme/ldap_replica_simple/)
- [Ldap StartTLS Consumer with SASL GSSAPI Authentication](https://hub.docker.com/r/antagme/ldap_replica_gssapi/)


### Fast Deployment

I Made this example for show how to configure yours _Ldap Servers_ , anyway if you only want check how to it works , maybe be interesed in this another explanation.[Automated Build and How it Works](https://github.com/antagme/Documentation_Project/blob/master/example2fast.md)

## Features

- Openldap Server for use to backup user information
- Secure GSSAPI Authentification for LDAP client utilities
- Secure connection between client and server using StartTLS
- Fastest operations with LDAP Client Utilities
- Ldap Producer Server 
- Ldap Consumer Server with simple authentification
- Ldap Consumer Server with GSSAPI authentification

## Requisites

- [Nslcd and nsswitch file configurated for host retrieving](https://github.com/antagme/Documentation_Project/blob/master/HowToConfigureNslcdAndNssSwitch.md)
- Own Certificates for CA and Server with properly FQDN in Server Certificate.
