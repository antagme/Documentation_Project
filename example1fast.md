# Example 1 - StartTLS LDAP Server With SASL GSSAPI Auth

## Overview

In this model, we will perform a _GSSAPI Authentication_ using the Openldap client utilities. For this we will use a total of 3 _Docker Containers_.
All communication between the client and the _LDAP SERVER_ is encrypted using the _TLS_ protocol, using port 389, the default for unencrypted communications, but thanks to _StartTLS_, we can use it for secure communications

## Requisites

- Docker Engine working on the system
- run this with user with permisions

Note:_This Script only tested in fedora 24_

## How To Deploy

If you want to see how it works in your computer , follow this steps.

- Download the start script `wget https://raw.githubusercontent.com/antagme/Documentation_Project/master/AutomatedScript/start_example1.sh`
- Run it `/bin/bash start_example1.sh`
- Wait to finish the installation

## Try it

We gonna try some search querys with Client , you need enter into the _Client Container_.

    docker exec --interactive --tty client bash
    
Time to try how works.
First need get a _Kerberos User Ticket_.

    kinit user01
    
The password is `kuser01`

Check if the ticket is getting properly.

    klist

Check if ldap transform properly the ticket.

    ldapwhoami -ZZ
    
Now try some Ldapsearch querys.

    ldapsearch -ZZ cn=user01
    
## More information

If you preffer long explanation , you have [How to configure for perform SASL GSSAPI](https://github.com/antagme/Documentation_Project/blob/master/example1.md)
