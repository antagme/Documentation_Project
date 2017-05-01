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
### Hostnames and our ips

- LDAP Server: ldap.edt.org 172.18.0.2
- Kerberos Server: kserver.edt.org 172.18.0.3
- Client: client.edt.org  172.18.0.8

### Starting
Starting from the base that we already have an openldap server running without these technologies.

To properly configure the servers and the client, we have to be careful in 3 essential things.

- Communication through the 3 Containers is correct , including the ticket obtaining.
- Configure properly the slapd.conf file with SASL options.
- Configure the client ldap.conf file for automatized SASL GSSAPI use

In our case for this example we will use some docker containers that I created for the occasion.

#### Create Docker Network

_This is for a very important reason, we need to always have the same container IP for the proper Ip distribution through LDAP and NSLCD.
In the default Bridge Network , we can't assign ips for containers_

 ```bash
 # docker network create --subnet 172.18.0.0/16 -d bridge ldap
 ```
 
#### Run Docker LDAP
 ```bash
 # docker run --name ldap --hostname ldap.edt.org --net ldap --ip 172.18.0.2  --detach antagme/ldap_gssapi
 ```  

#### Run Docker Kerberos (TGT)  
 ```bash
 # docker run --name kerberos --hostname kserver.edt.org --net ldap --ip 172.18.0.3  --detach antagme/kerberos:supervisord
 ```
 
#### Run Docker Client   
 ```bash
 # docker run --name client --hostname client.edt.org --net ldap --ip 172.18.0.8 --detach antagme/client_gssapi
 ```

These dockers containers are not interactive, to access you have to do the following order:

    docker exec --interactive --tty [Docker Name] bash
    

### Configure

Having the Kerberos and the LDAP containers working properly , the first pass is create the principal for LDAP service on **Openldap Server Host** , its so important!!!! 
In our case the _LDAP server host_ is `ldap.edt.org` so we should create the principal in kerberos machine using:

    kadmin.local -q "addprinc -pw randkey ldap/ldap.edt.org"

Since we are in the kerberos machine, we will take advantage of and create a principal to make tests later with the client, in our case, as we have in our users of ldap the following entry:
<pre><code>
dn: <b>cn=user01</b>,ou=usuaris,dc=edt,dc=org
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
</code></pre>

In our case , we should create a Principal entry with name user01.

Note:_If you were thinking that the entry was incorrect because it did not have a `userPassword` entry, you are wrong. It is to avoid accessing that user with password_

In Kerberos Machine:

    kadmin.local -q "addprinc -pw kuser01 user01"

For the ticket Obtaining (`kinit`) for user01 , we should user the _password_ kuser01.

On the 3 Containers , we should have the same krb5.conf file, in our case , this one.

    [logging]
      default = FILE:/var/log/krb5libs.log
      kdc = FILE:/var/log/krb5kdc.log
      admin_server = FILE:/var/log/kadmind.log
    [libdefaults]
      dns_lookup_realm = false
      ticket_lifetime = 24h
      renew_lifetime = 7d
      forwardable = true
      rdns = false
      default_realm = EDT.ORG
    [realms]
      EDT.ORG = {
      kdc = kserver.edt.org
      admin_server = kserver.edt.org
      }
    [domain_realm]
     .edt.org = EDT.ORG
    edt.org = EDT.ORG
    
Make the following order in the 3 containers to make sure everything will work.

    supervisorctl restart all

This gonna restart all services on the container.

Now in the client container , we gonna try if we can obtain ticket of **user01**.

    [root@client /]# kinit user01
    
