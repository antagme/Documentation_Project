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


## Instalation
### Hostnames and our ips

- LDAP Producer Server: ldap.edt.org 172.18.0.2
- Kerberos Server: kserver.edt.org 172.18.0.3
- Client: client.edt.org  172.18.0.8
- LDAP GSSAPI Replica ldaprepl.edt.org 172.18.0.4
- LDAP SIMPLE Replica ldaprepl2.edt.org 172.18.0.5

### Starting
Starting from the base that we already have an openldap server running without these technologies.
To properly configure the servers and the client, we have to be careful in 3 essential things.

- Need to have working the GSSAPI Auth On Ldap Producer and GSSAPI Replica , if you dont have it please see [Example 1](https://github.com/antagme/Documentation_Project/blob/master/example1.md)
- Correct configuration of slapd.conf for authorize Replication
- Communication between the Ldap Producer and GSSAPI Replica is correct
- Change the ACL on Ldap Producer For Simple Replica and check if the Communication between Producer and Simple Replica is correct


In our case for this example we will use some docker containers that I created for the occasion.
In these containers are already made the modifications, are just an example, you can do it on your own server
If you dont want use my examples , go directly to [Configure](#configure).

Note: My Containers can communicate between them , because i configurated ldap for do ip resolution [Here](https://github.com/antagme/Documentation_Project/blob/master/HowToConfigureNslcdAndNssSwitch.md) , if u don't using my containers , you should put all container entries in **/etc/hosts** for each container , like this.

    172.18.0.2 ldap.edt.org
    172.18.0.3 kserver.edt.org
    172.18.0.8 client.edt.org
    ldaprepl.edt.org 172.18.0.4
    ldaprepl2.edt.org 172.18.0.5
    
#### Create Docker Network

_This is for a very important reason, we need to always have the same container IP for the proper Ip distribution through LDAP and NSLCD.
In the default Bridge Network , we can't assign ips for containers_


 ```bash
 # docker network create --subnet 172.18.0.0/16 -d bridge ldap
 ```
 
#### Run Docker LDAP
 ```bash
 # docker run --name ldap --hostname ldap.edt.org --net ldap --ip 172.18.0.2  --detach antagme/ldap_producer
 ```  

#### Run Docker Kerberos (TGT)  
 ```bash
 # docker run --name kerberos --hostname kserver.edt.org --net ldap --ip 172.18.0.3  --detach antagme/kerberos:supervisord
 ```
 
#### Run Docker Client   
 ```bash
 # docker run --name client --hostname client.edt.org --net ldap --ip 172.18.0.8 --detach antagme/client_gssapi
 ```

#### Run Docker Replica Gssapi   
 ```bash
 # docker run --name ldap_replica_gssapi --hostname ldaprepl.edt.org --net ldap --ip 172.18.0.4 --detach antagme/ldap_replica_gssapi
 ```
 
 #### Run Docker Replica Simple   
 ```bash
 # docker run --name ldap_replica_simple --hostname ldaprepl2.edt.org --net ldap --ip 172.18.0.5 --antagme/ldap_replica_client
 ```

These dockers containers are not interactive, to access you have to do the following order:

    docker exec --interactive --tty [Docker Name] bash
    
#### Automated Script
If you preffer to use an Automated Builds , can take the script i created for this.[HERE](https://github.com/antagme/Documentation_Project/blob/master/AutomatedScript/start_example2.sh)

## Configure
### Configure our Ldap Server as Producer

We have 3 importants parts in the configuration of our slapd.conf to realize Producer work.
- Enable Syncprov Module
- Configure the Backend for enable syncprov
- Modify ACL and create DN for Consumer Simple Replication

Lets see  my file [slapd.conf](https://raw.githubusercontent.com/antagme/ldap_producer/master/files/slapd.external.conf)

<pre><code>
#
# See slapd.conf(5) for details on configuration options.
# This file should NOT be world readable.
#

include         /etc/openldap/schema/corba.schema
include         /etc/openldap/schema/core.schema
include         /etc/openldap/schema/cosine.schema
include         /etc/openldap/schema/duaconf.schema
include         /etc/openldap/schema/dyngroup.schema
include         /etc/openldap/schema/inetorgperson.schema
include         /etc/openldap/schema/java.schema
include         /etc/openldap/schema/misc.schema
include         /etc/openldap/schema/nis.schema
include         /etc/openldap/schema/openldap.schema
include         /etc/openldap/schema/ppolicy.schema
include         /etc/openldap/schema/collective.schema

# Allow LDAPv2 client connections.  This is NOT the default.
allow bind_v2

pidfile         /var/run/openldap/slapd.pid
#argsfile       /var/run/openldap/slapd.args

# Limit SASL options to only GSSAPI and not other client-favorites. Apparently there is an issue where
# clients will default to non-working SASL mechanisms and will make you angry.
sasl-secprops noanonymous,noplain,noactive

# SASL connection information. The realm should be your Kerberos realm as configured for the system. The
# host should be the LEGITIMATE hostname of this server
sasl-realm EDT.ORG
sasl-host ldap.edt.org

# Rewrite certain SASL bind DNs to more readable ones. Otherwise you bind as some crazy default
# that ends up in a different base than your actual one. This uses regex to rewrite that weird
# DN and make it become one that you can put within your suffix.
authz-policy from
authz-regexp "^uid=[^,/]+/admin,cn=edt\.org,cn=gssapi,cn=auth" "cn=Manager,dc=edt,dc=org"
authz-regexp "^uid=([^,]+),cn=edt\.org,cn=gssapi,cn=auth" "cn=$1,ou=usuaris,dc=edt,dc=org"

# ------------------------------------------------------------------------------------------------------------
# SSL certificate file paths
TLSCACertificateFile /etc/ssl/certs/cacert.pem
TLSCertificateFile /etc/openldap/certs/ldapcert.pem
TLSCertificateKeyFile /etc/openldap/certs/ldapserver.pem
TLSCipherSuite HIGH:MEDIUM:+SSLv2
TLSVerifyClient allow
# -----------------------------------------------
<b>
modulepath  /usr/lib64/openldap
moduleload  syncprov.la
loglevel    sync stats
</b>

# -----------------------------------------------

database hdb
suffix "dc=edt,dc=org"
rootdn "cn=Manager,dc=edt,dc=org"
rootpw {SASL}admin/admin@EDT.ORG
directory /var/lib/ldap
index objectClass,cn,memberUid,gidNumber,uidNumber,uid eq,pres
<b>overlay syncprov
syncprov-checkpoint 1000 60
</b>
access to attrs=userPassword
  by self write
 <b> by dn.exact="cn=Replication,dc=edt,dc=org" read </b>
  by anonymous auth
  by * none

access to *
  by peername.ip=172.18.0.0%255.255.0.0 read
  by * read break
</code></pre>  

#### Enable Syncprov Module

In this line need to specify Module Directory Path , the name of the module and loglevel of this:

    modulepath  /usr/lib64/openldap
    moduleload  syncprov.la
    loglevel    sync stats

#### Configure the Backend for enable syncprov

In the Backend configuration , you should specify to enable Replication in available on this.

    overlay syncprov
    syncprov-checkpoint 1000 60

#### Create a User DN and Modify ACL for Consumer Simple Replication

We need to have an entry in our Ldap Tree for Secure retrieve of sensible data. We gonna create "cn=Replication,dc=edt,dc=org".
Note:_Never put here Manager Account of Ldap , its so dangerous , always create a new DN_

Create a file with this, my file name will be replicate.ldif

    dn: cn=replication,dc=edt,dc=org
    objectClass: top
    objectClass: person
    objectClass: organizationalPerson
    cn: replication
    sn: replication
    userPassword: {SSHA}5DfZc1WXeIwrP7C3fr23WLZiPZ5YHMgA

Our New DN Password is **jupiter** , if you have LDAP Gssapi like me , add this entry is so simple.

- Get _Admin Ticket_: `kinit admin/admin` (our password is admin)
- Insert the file: `ldapadd -f replicate.ldif`

With this we have 1 entry for replication simple.

Finally we gonna put the new slapd.conf file. First stop slapd service if its running , in my case `supervisorctl stop slapd`.

Now , in my case , gonna change our slapd.conf and i prepared an script for this. `bash /scripts/startup-slapd.sh` . When finish , you should put on the service `supervisorctl start slapd`. 

We have Working slapd producer server with posibilities of replication.

### Ldap Consumer server through GSSAPI Authentification.

With all configurated , we gonna try how works the replication of _Ldap_ server through _GSSAPI Authentification_ , its more secure because the password not needs to be write in configuration file.

Firstly we need The Producer server working , the next step is to set up the slapd.conf of our_ GSSAPI Consumer_.

Lets see my file:

<pre><code>
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
sasl-secprops noanonymous,noplain,noactive

# SASL connection information. The realm should be your Kerberos realm as configured for the system. The
# host should be the LEGITIMATE hostname of this server
<b>
sasl-realm EDT.ORG
sasl-host ldaprepl.edt.org
# Rewrite certain SASL bind DNs to more readable ones. Otherwise you bind as some crazy default
# that ends up in a different base than your actual one. This uses regex to rewrite that weird
# DN and make it become one that you can put within your suffix.
authz-policy from
authz-regexp "^uid=[^,/]+/admin,cn=edt\.org,cn=gssapi,cn=auth" "cn=Manager,dc=edt,dc=org"
authz-regexp "^uid=([^,]+),cn=edt\.org,cn=gssapi,cn=auth" "cn=$1,ou=usuaris,dc=edt,dc=org"
</b>
# SSL certificate file paths
TLSCACertificateFile /etc/ssl/certs/cacert.pem
TLSCertificateFile /etc/openldap/certs/ldapcert.pem
TLSCertificateKeyFile /etc/openldap/certs/ldapserver.pem
TLSCipherSuite HIGH:MEDIUM:+SSLv2
# -----------------------------
<b>
modulepath  /usr/lib64/openldap
moduleload  syncprov.la 
loglevel    sync stats
</b>

# -----------------------------------------------
<b>
database hdb
suffix "dc=edt,dc=org"
rootdn "cn=Manager,dc=edt,dc=org"
rootpw {SASL}admin/admin@EDT.ORG
directory /var/lib/ldap
index objectClass eq,pres
syncrepl rid=000 
  provider=ldap://ldap.edt.org
  type=refreshAndPersist
  retry="5 5 300 +" 
  searchbase="dc=edt,dc=org"
  attrs="*,+"
  starttls=yes
  bindmethod=sasl
  binddn="cn=Manager,dc=edt,dc=org"
  credentials={SASL}admin/admin@EDT.ORG
updateref ldap://ldap.edt.org
</b>
#---------------------------------ACL-----
access to attrs=userPassword
  by anonymous auth
  by self write
  
access to * 
  by peername.ip=172.18.0.0%255.255.0.0 read
  by dn.exact="cn=replication,dc=edt,dc=org" read
  by * read break

# ------------------------------------------------
</code></pre>

#### Enabling GSSAPI server and REALM

Like the _Producer_ we need to configure our server for enable GSSAPI Authentification , so if you dont know how it works , please see [Example 1](https://github.com/antagme/Documentation_Project/blob/master/example1.md)

_Note:the Host should be the FQDN of Consumer GSSAPI Server_

#### Enable Syncprov Module

In this line need to specify Module Directory Path , the name of the module and loglevel of this:

    modulepath  /usr/lib64/openldap
    moduleload  syncprov.la
    loglevel    sync stats

#### Configure the Backend with Producer information

We will focus on the key points to configure the consumer and enable communication between the producer and the GSSAPI, for more information on the configuration of the module Syncrepl look at the [official documentation](http://www.openldap.org/doc/admin24/slapdconfig.html#syncrepl)

_Note: If you have 2 or more servers , the `syncrepl rid=000` camp should be different number from the others_

- We enable StartTLS communication: `starttls=yes`
- The bindmethod is SASL for GSSAPI: `bindmethod=sasl`
- I configure the consumer to retrieve information of the Producer through GSSAPI , so we need to put entry like this. 

         binddn="cn=Manager,dc=edt,dc=org"
         credentials={SASL}admin/admin@EDT.ORG

With this configuracion , you need to put this slapd.conf in the server , like the previous configuration. In my case `bash /scripts/startup-slapd.sh`

#### Starting the Replication

In this moment , we have stopped _Slapd_ Service and if you perform this order `slapcat` will comprove that the database is empty.Also if you check the content of the _backend_ directory you will see this empty , in our case `ls -l /var/lib/ldap`.

Now need **admin** ticket for get all the entries of the Producer , we obtain with `kinit admin/admin` and the password admin.

Check if the ticket was obtained properly with `klist`.

Now only need to start the server , in my case with `supervisorctl start slapd`.

Wait few secs and try to perform `slapcat` and `ls -l /var/lib/ldap` and check if the information was changed.

Now we have an GSSAPI Consumer , with a client perform some searchs to the server to check it working properly

Note:_ You can delete the ticket and it gonna replicate anyway , but i recommend still with ticket for more security_

### Ldap Consumer server through Simple Authentification.

According our configuration , we create a new DN entry for perform this Replication.



_UNDER CONSTRUCTION_
