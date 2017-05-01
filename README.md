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

Note: My Containers can communicate between them , because i configurated ldap for do _ip resolution_ , if u don't using my containers , you should put all container entries in **/etc/hosts** for each container , like this.

    172.18.0.2 ldap.edt.org
    172.18.0.3 kserver.edt.org
    172.18.0.8 client.edt.org

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
#### Kerberos Principals Creation
Having the Kerberos and the LDAP containers working properly , the first pass is create the principal for LDAP service on **Openldap Server Host** , its so important!!!! 
In our case the _LDAP server host_ is `ldap.edt.org` so we should create the principal in **Kerberos** machine using:

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
Note:_for understand why and how i configure my supervisord , [click here](fake)

Now in the client container , we gonna try if we can obtain ticket of **user01**.

    [root@client /]# kinit user01
    
Here you should introduce the principal password , in our case , kuser01.

If the ticket gathering is correct , if u write the `klist` command , the output should be like this:

    [root@client /]# klist
    Ticket cache: FILE:/tmp/krb5cc_0
    Default principal: user01@EDT.ORG

    Valid starting     Expires            Service principal
    05/01/17 13:13:42  05/02/17 13:13:42  krbtgt/EDT.ORG@EDT.ORG

Success? if the answer is yes , continue.

#### Openldap Configuration for GSSAPI Authentification

At this moment, we have created the principal entries (For client testing and ldap service) and the communication between the server kerberos and the other containers is correct.

Now we need to configure the slapd.conf file to allow authentication through GSSAPI.

Inside the _LDAP Container_ , we need to install first , 2 packets for support GSSAPI Authentification.

    dnf install -y cyrus-sasl-gssapi cyrus-sasl-ldap
    
Now , lets see our [slapd.conf](https://raw.githubusercontent.com/antagme/ldap_gssapi/master/files/slapd-gssapi.conf) file:
```diff
#
# See slapd.conf(5) for details on configuration options.
# This file should NOT be world readable.
#

include		/etc/openldap/schema/corba.schema
include		/etc/openldap/schema/core.schema
include		/etc/openldap/schema/cosine.schema
include		/etc/openldap/schema/duaconf.schema
include		/etc/openldap/schema/dyngroup.schema
include		/etc/openldap/schema/inetorgperson.schema
include		/etc/openldap/schema/java.schema
include		/etc/openldap/schema/misc.schema
include		/etc/openldap/schema/nis.schema
include		/etc/openldap/schema/openldap.schema
include		/etc/openldap/schema/ppolicy.schema
include		/etc/openldap/schema/collective.schema

# Allow LDAPv2 client connections.  This is NOT the default.
allow bind_v2

pidfile		/var/run/openldap/slapd.pid
#argsfile	/var/run/openldap/slapd.args

# Limit SASL options to only GSSAPI and not other client-favorites. Apparently there is an issue where
# clients will default to non-working SASL mechanisms and will make you angry.
+ sasl-secprops noanonymous,noplain,noactive

# SASL connection information. The realm should be your Kerberos realm as configured for the system. The
# host should be the LEGITIMATE hostname of this server
+ sasl-realm EDT.ORG
- sasl-host ldap.edt.org

# Rewrite certain SASL bind DNs to more readable ones. Otherwise you bind as some crazy default
# that ends up in a different base than your actual one. This uses regex to rewrite that weird
# DN and make it become one that you can put within your suffix.
+ authz-policy from
+ authz-regexp "^uid=[^,/]+/admin,cn=edt\.org,cn=gssapi,cn=auth" "cn=Manager,dc=edt,dc=org"
+ authz-regexp "^uid=host/([^,]+)\.edt\.org,cn=edt\.org,cn=gssapi,cn=auth" "cn=$1,ou=hosts,dc=edt,dc=org"
+ authz-regexp "^uid=([^,]+),cn=edt\.org,cn=gssapi,cn=auth" "cn=$1,ou=usuaris,dc=edt,dc=org"
# ------------------------------------------------------------------------------------------------------------
# SSL certificate file paths
TLSCACertificateFile /etc/ssl/certs/cacert.pem
TLSCertificateFile /etc/openldap/certs/ldapcert.pem
TLSCertificateKeyFile /etc/openldap/certs/ldapserver.pem
TLSCipherSuite HIGH:MEDIUM:+SSLv2
TLSVerifyClient allow

# -----------------------------------------------

database hdb
suffix "dc=edt,dc=org"
rootdn "cn=Manager,dc=edt,dc=org"
rootpw {SASL}admin/admin@EDT.ORG
directory /var/lib/ldap
index objectClass eq,pres

access to attrs=userPassword
  by anonymous auth
  by self write
  
access to * 
  by peername.ip=172.18.0.0%255.255.0.0 read
  by * read break
```


    
