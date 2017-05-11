# Example 3 - Client with PAM + SSSD for Kerberos Auth , LDAP user information and Kerberos Password

## Overview

In this model, starting from example one, we will see how to make a more secure authentication in the system using the best of Kerberos and Ldap technologies.

For this example, in the Client we will see how the System-Auth works with these two technologies, and we will perform a series of checks to make sure it works correctly.

_Docker Images_ used for this example:
- [Ldap StartTLS + GSSAPI Keytab](https://hub.docker.com/r/antagme/ldap_sssd)
- [Kerberos](https://hub.docker.com/r/antagme/kerberos/)
- [Client PAM + ldapwhoami](https://hub.docker.com/r/antagme/client/)


### Fast Deployment

I Made this example for show how to configure your _Ldap Server_ , anyway if you only want check how to it works , maybe be interesed in this another explanation.[Automated Build and How it Works](https://github.com/antagme/Documentation_Project/blob/master/example1fast.md)

## Features

- Openldap Server for use to backup user information
- Secure GSSAPI Authentification for LDAP client utilities
- Secure connection between client and server using StartTLS
- Fastest operations with LDAP Client Utilities

## Requisites

- [Nslcd and nsswitch file configurated for host retrieving](https://github.com/antagme/Documentation_Project/blob/master/HowToConfigureNslcdAndNssSwitch.md)
- Own Certificates for CA and Server with properly FQDN in Server Certificate.

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
In these containers are already made the modifications, are just an example, you can do it on your own server
If you dont want use my examples , go directly to [Configure](#configure).

Note: My Containers can communicate between them , because i configurated ldap for do ip resolution [Here](https://github.com/antagme/Documentation_Project/blob/master/HowToConfigureNslcdAndNssSwitch.md) , if u don't using my containers , you should put all container entries in **/etc/hosts** for each container , like this.

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
    
#### Automated Script
If you preffer to use an Automated Builds , can take the script i created for this.[HERE](https://github.com/antagme/Documentation_Project/blob/master/AutomatedScript/start_example1.sh)

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

In our case , we should create a Principal entry with name user01 , also , if u doesn't had admin principal , this is the moment.

Note:_If you were thinking that the entry was incorrect because it did not have a `userPassword` entry, you are wrong. It is to avoid accessing that user with password_

In Kerberos Machine:

    kadmin.local -q "addprinc -pw admin admin/admin"
    kadmin.local -q "addprinc -pw kuser01 user01"

Check if this admin/admin@EDT.ORG have a entry inside `/var/kerberos/krb5kdc/kadm5.acl` like this.

    */admin@EDT.ORG *

Note: _This Means All principal entries like **blablabla**/admin have Admin permission._

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
Note:_for understand why and how i configure my supervisord_ , [click here](https://github.com/antagme/Documentation_Project/blob/master/HowToSupervisor.md)

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

I have marked in two colors the things that we have to configure, the red line (-) is where you have to be especially careful, because it can cause confusion.

Let's analyze them one by one.

     sasl-secprops noanonymous,noplain,noactive
     
sasl-secprops , According Openldap Documentation:
> Used to specify Cyrus SASL security properties.     

And according [LDAP System Administration: Putting Directories to Work](https://books.google.es/books?id=utsMgEfnPSEC&pg=PT56&lpg=PT56&dq=%2B+sasl-secprops+noanonymous,noplain,noactive&source=bl&ots=LonrHJNZVc&sig=kL1iSuR3_4SyJYePIiiJHJ3S4Y8&hl=es&sa=X&ved=0ahUKEwiUoNPW787TAhXInRoKHTCmA7sQ6AEIMDAB#v=onepage&q=%2B+sasl-secprops+noanonymous%2Cnoplain%2Cnoactive&f=false) 
GSSAPI Need this 3 options.


The next one.

    sasl-realm EDT.ORG

This should be the realm defined on the krb5.conf file , in my case , EDT.ORG.

The most important, in my opinion , because can make you some confusion.

     sasl-host ldap.edt.org

Here, you have to put the FQDN of your ldap server, not the kerberos server (as I did when I set it) it is very important that we import the keytab so that this option has some meaning.

Let's import the keytab. In Ldap Container:

    kadmin -p admin/admin
    Authenticating as principal admin/admin with password.
    Password for admin/admin@EDT.ORG:
    kadmin: ktadd -k /etc/krb5.keytab ldap/ldap.edt.org


If you have followed all my explanations, we only have to configure the ldap server to recognize the principals like ldap users, this is done using a REGEX filters, let's see it

    authz-policy from
    authz-regexp "^uid=[^,/]+/admin,cn=edt\.org,cn=gssapi,cn=auth" "cn=Manager,dc=edt,dc=org"
    authz-regexp "^uid=([^,]+),cn=edt\.org,cn=gssapi,cn=auth" "cn=$1,ou=usuaris,dc=edt,dc=org"

The first line , enable authz-regex , according Openldap Documentation:
> By default, processing of proxy authorization rules is disabled. The authz-policy directive must be set in the slapd.conf(5) file to enable authorization

When you try some operation with ticket to Ldap server through ldap clients utilities , the identity of the client , is not like usually we are using (cn=user01,ou=usuaris,dc=edt,dc=org) , so we should transform it.

This Expression transform all `*/admin@EDT.ORG` Principal Tickets to `cn=Manager,dc=edt,dc=org` , our Manager of the Ldap DDBB
    
    authz-regexp "^uid=[^,/]+/admin,cn=edt\.org,cn=gssapi,cn=auth" "cn=Manager,dc=edt,dc=org"

This expression transform all entries like `*@EDT.ORG` to Ldap User Entry like `cn=*,ou=usuaris,dc=edt,dc=org`

    authz-regexp "^uid=([^,]+),cn=edt\.org,cn=gssapi,cn=auth" "cn=$1,ou=usuaris,dc=edt,dc=org"

Apply the _slapd.conf_ file and perform `supervisorctl restart all` on 3 Containers.

According our _Client Configuration_ , we should try if our configuration is working well with this 3 commands.
Note:_ Important , in the client , you need too the packets installed in _Ldap_ Server for GSSAPI._

1. Obtain Ticket
      * `kinit user01`
      
2. Try If ldap perform properly REGEX filtering.
      * `ldapwhoami -h ldap.edt.org  -b 'dc=edt,dc=org' -Y GSSAPI -ZZ`

If the output is like this , you are success!!!

    SASL/GSSAPI authentication started
    SASL username: user01@EDT.ORG
    SASL SSF: 56
    SASL data security layer installed.
    dn:cn=user01,ou=usuaris,dc=edt,dc=org


3. Perform a ldapsearch command for being secure about our success.
      * `ldapsearch -h ldap.edt.org -Y GSSAPI  -b 'dc=edt,dc=org' -ZZ cn=user01`

Output:

    SASL/GSSAPI authentication started
    SASL username: user01@EDT.ORG
    SASL SSF: 56
    SASL data security layer installed.
    # extended LDIF
    #
    # LDAPv3
    # base <dc=edt,dc=org> (default) with scope subtree
    # filter: cn=user01
    # requesting: ALL
    #

    # user01, usuaris, edt.org
    dn: cn=user01,ou=usuaris,dc=edt,dc=org
    objectClass: posixAccount
    objectClass: inetOrgPerson
    cn: user01
    cn: alumne01 de 1asix de todos los santos
    sn: alumne01
    homePhone: 555-222-0001
    mail: user01@edt.org
    description: alumne de 1asix
    ou: 1asix
    uid: user01
    uidNumber: 7001
    gidNumber: 610
    homeDirectory: /var/tmp/home/1asix/user01
    userPassword:: e1NBU0x9dXNlcjAxQEVEVC5PUkc=

    # search result
    search: 5
    result: 0 Success

    # numResponses: 2
    # numEntries: 1

Now we have _GSSAPI_ AUTHENTIFICATION in our ldap server , but we need to complete the last step.

#### Ldap.conf file in Client Container.

The last step is configure our ldap.conf file for easiest operations with LDAP Client utilities.

Our [ldap.conf](https://raw.githubusercontent.com/antagme/client_gssapi/master/files/ldap.conf) 

    # OpenLDAP client configuration file. Used for host default settings
    BASE            dc=edt,dc=org
    URI             ldap://ldap.edt.org/
    SASL_MECH GSSAPI
    SASL_REALM EDT.ORG
    TLS_CACERT      /etc/ssl/certs/cacert.pem
    #TLS_CACERTDIR    /etc/openldap/certs/


- BASE: The Base branch of our _Ldap_ _DDBB_ (for not need  -b 'dc=edt,dc=org' on ldap client utility command )
- URI: the uri to ldap server (FQDN) (for not need -H ldap://ldap.edt.org or -h ldap.edt.org on ldap client utility command)
- SASL_MECH: The SASL mech we will use , in our case GSSAPI ( for not need -Y GSSAPI on ldap client utility command)
- SASL_REALM: The SASL Realm we defined on slapd.conf file
- TLS_CACERT: The Absolute route to the CA Cert who signed Ldap Certificates

Note: The file can be found in _/etc/openldap/ldap.conf_

Configuring this file facilitates the administration of the ldap server through the client utilities of this.
Now our commands will be shorter.


| Command| Before | After  |
| ------------- |:-------------:| -----:|
| StartTLS Ldapsearch | `ldapsearch -h ldap.edt.org -Y GSSAPI  -b 'dc=edt,dc=org' -ZZ ` | `ldapsearch -ZZ `| 
| StartTLS ldapwhoami | `ldapwhoami -h ldap.edt.org  -b 'dc=edt,dc=org' -Y GSSAPI -ZZ`  | `ldapwhoami -ZZ` |


## Bibliography

- [LDAP System Administration: Putting Directories to Work](https://books.google.es/books?id=utsMgEfnPSEC&pg=PT56&lpg=PT56&dq=%2B+sasl-secprops+noanonymous,noplain,noactive&source=bl&ots=LonrHJNZVc&sig=kL1iSuR3_4SyJYePIiiJHJ3S4Y8&hl=es&sa=X&ved=0ahUKEwiUoNPW787TAhXInRoKHTCmA7sQ6AEIMDAB#v=onepage&q=%2B%20sasl-secprops%20noanonymous%2Cnoplain%2Cnoactive&f=false)
- [Official OpenLDAP Documentation of SASL Auth](http://www.openldap.org/doc/admin24/sasl.html)
- [Mastering Ldap - Matt Butcher](https://www.packtpub.com/networking-and-servers/mastering-openldap-configuring-securing-and-integrating-directory-services)
