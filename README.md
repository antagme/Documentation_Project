# StartTLS LDAP Server With SASL GSSAPI Auth.

## Overview

In this model, we will perform a _GSSAPI Authentication_ using the Openldap client utilities. For this we will use a total of 3 _Docker Containers_.
All communication between the client and the _LDAP SERVER_ is encrypted using the _TLS_ protocol, using port 389, the default for unencrypted communications, but thanks to _StartTLS_, we can use it for secure communications

_Docker Images_ used for this example:
- [Ldap StartTLS + GSSAPI Keytab](https://hub.docker.com/r/antagme/ldap_gssapi/) 
- [Kerberos](https://hub.docker.com/r/antagme/kerberos/)
- [Client for try some consults to Database](https://hub.docker.com/r/antagme/client_gssapi/)

## Features

- Openldap Server for use to backup user information
- Secure GSSAPI Authentification for LDAP client utilities
- Secure connection between client and server using StarTLS
- Fastest operations with LDAP Client Utilities

## Instalation

### Starting
Starting from the base that we already have an openldap server running without these technologies.

To properly configure the servers and the client, we have to be careful in 3 essential things.

- Communication through the 3 Containers is correct , including the ticket obtaining.
- Configure properly the slapd.conf file with SASL options.
- Configure the client ldap.conf file for automatized SASL GSSAPI use

### Configure

Having the Kerberos and the LDAP containers working properly , the first pass is create the principal for LDAP service on **Openldap Server Host** , its so important!!!! 
In our case the _LDAP server host_ is `ldap.edt.org` so we should create the principal in kerberos machine using:

    kadmin.local -q "addprinc -pw randkey ldap/ldap.edt.org"

Since we are in the kerberos machine, we will take advantage of and create a principal to make tests later with the client, in our case, as we have in our users of ldap the following entry:

    dn: **cn=user01**,ou=usuaris,dc=edt,dc=org
    objectclass: posixAccount
    objectclass: inetOrgPerson
    cn: user01
    cn: alumne01 de 1asix de todos los santos
    sn: alumne01
    homephone: 555-222-0001
    mail: user01@edt.org
    description: alumne de 1asix
    ou: 1asix
    uid: user01
    uidNumber: 7001
    gidNumber: 610
    homeDirectory: /var/tmp/home/1asix/user01
    
If you were thinking that the entry was incorrect because it did not have a `userPassword` entry, you are wrong. It is to avoid accessing that user with password.

In Kerberos Machine , 
