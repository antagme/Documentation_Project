# StartTLS LDAP Server With SASL GSSAPI Auth.

## Overview

In this model, we will perform a _GSSAPI Authentication_ using the Openldap client utilities. For this we will use a total of 3 _Docker Containers_.
All communication between the client and the _LDAP SERVER_ is encrypted using the _TLS_ protocol, using port 389, the default for unencrypted communications, but thanks to _StartTLS_, we can use it for secure communications

_Docker Images_ used for this example:
- [Ldap StartTLS + GSSAPI Keytab](https://hub.docker.com/r/antagme/client_gssapi/) 
- [Kerberos](https://hub.docker.com/r/antagme/kerberos/)
- [Client for try some consults to Database](https://hub.docker.com/r/antagme/client_gssapi/)
