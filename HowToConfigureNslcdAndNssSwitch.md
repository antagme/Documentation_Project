# How To configure nslcd daemon for retrieve information from Ldap Database.

## First steps

You should install [nss-pam-ldapd](https://arthurdejong.org/nss-pam-ldapd/) packet  which provides a Name Service Switch (NSS) module that allows your LDAP server for provide information.

In `Fedora` the order is the next.

    dnf install -y nss-pam-ldapd

This will provide you some new files [/etc/nslcd.conf](https://raw.githubusercontent.com/antagme/ldap_supervisor/master/files/nslcd.conf) and [/etc/nsswitch.conf](https://raw.githubusercontent.com/antagme/ldap_supervisor/master/files/nsswitch.conf).

And you should have correct entries for Groups , Users and Hosts.

### Openldap Example Entry for User

    dn: cn=user01,ou=usuaris,dc=edt,dc=org
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

### Openldap Example Entry for Group

    dn: cn=1asix,ou=grups,dc=edt,dc=org
    cn: 1asix
    gidNumber: 610
    description: Grup 1 asix
    objectclass: top
    objectclass: posixGroup
    memberUid: user01
    memberUid: user02
    memberUid: user03
    memberUid: user04
    memberUid: user05

### Openldap Example Entry for Host

    # pc1, hosts, edt.org
    dn: cn=pc1,ou=hosts,dc=edt,dc=org
    objectClass: top
    objectClass: device
    objectClass: ipHost
    objectClass: ieee802Device
    cn: pc1
    ipHostNumber: 172.18.0.1
    macAddress: 02:42:3a:be:ac:52
    description: Ordinador aula

## Configuring nslcd daemon for retrieve information

Finished the packet installing , you have to configure the 2 new files.

### nslcd.conf

<pre><code>

# This is the configuration file for the LDAP nameservice
# switch library's nslcd daemon. It configures the mapping
# between NSS names (see /etc/nsswitch.conf) and LDAP
# information in the directory.
# See the manual page nslcd.conf(5) for more information.

# The user and group nslcd should run as.
uid nslcd
gid ldap

# The uri pointing to the LDAP server to use for name lookups.
# Multiple entries may be specified. The address that is used
# here should be resolvable without using LDAP (obviously).
<b>uri ldap://172.18.0.2/</b>

# The LDAP version to use (defaults to 3
# if supported by client library)
#ldap_version 3

# The distinguished name of the search base.
<b>base dc=edt,dc=org</b>

# The default search scope.
scope sub
#scope one
#scope base

# Customize certain database lookups.
<b>base   group  ou=grups,dc=edt,dc=org</b>
<b>base   passwd ou=usuaris,dc=edt,dc=org</b>
#base   shadow ou=People,dc=example,dc=com
#scope  group  onelevel
#scope  hosts  sub

# Use StartTLS without verifying the server certificate.
<b>ssl start_tls
tls_reqcert never</b>

</code></pre>

* uri: the uri of the Ldap server from which we want to obtain information.(If you want obtain host information from Ldap, you should put IP instead FQDN).
* base: The distinguished name of the search base from our Ldap Server.
* base xxx: this about if want customize the search in another branch of the tree (xxx will be the information name).
* ssl startl_tls: Encrypted communication between server and daemon.
* tls_reqcert never: Don't ask for the client Certificate.

### nsswitch.conf

This file determines the order for retrieve information.

1. Without SSS

<pre><code>

# /etc/nsswitch.conf
#
# An example Name Service Switch config file. This file should be
# sorted with the most-used services at the beginning.
# To use db, put the "db" in front of "files" for entries you want to be
# looked up first in the databases


passwd:     files <b> ldap  </b>
shadow:     files <b> ldap  </b>
group:      files <b> ldap  </b>

hosts:  files <b> ldap </b> dns myhostname
bootparams: nisplus [NOTFOUND=return] files

ethers:     files
netmasks:   files
networks:   files
protocols:  files
rpc:        files
services:   files sss

netgroup:   files sss

publickey:  nisplus

automount:  files sss
aliases: files nisplus

</code></pre>

Always first files , or your system gonna be @#!·. the next entry will be read after read system files , in our case , ldap.
So this will read **Passwd , shadow , group and hosts** entries from _system + ldap_ information.
- `objectclass: posixAccount` is the entry for passwd retrieving.
- `objectclass: posixGroup` is the entry for groups retrieving.
- `objectclass: ipHost` is the entry for hosts retrieving.

2. with SSS for Pam Auth 

<pre><code>

# /etc/nsswitch.conf
#
# An example Name Service Switch config file. This file should be
# sorted with the most-used services at the beginning.
# To use db, put the "db" in front of "files" for entries you want to be
# looked up first in the databases


passwd:     files <b> ldap sss </b>
shadow:     files <b> ldap sss </b>
group:      files <b> ldap sss </b>

hosts:  files <b> ldap </b> dns myhostname
bootparams: nisplus [NOTFOUND=return] files

ethers:     files
netmasks:   files
networks:   files
protocols:  files
rpc:        files
services:   files sss

netgroup:   files sss

publickey:  nisplus

automount:  files sss
aliases: files nisplus

</code></pre>

In this configuration , i add too sss entry for correct retrieve information from sssd.
Note: _This only for my example 3 (sss kerberos pam auth)_


## Starting nslcd service and check if this work properly

You just have to `/usr/sbin/nslcd` and check if the information is getting well.

With the following commands:
- `getent passwd` For user information check
- `getent groups` For groups information check
- `getent hosts` For hosts information check

Note: _In my containers you only need to do_ `supervisocrtl restart nslcd` _for restart the service and get correct information_

## Bibliography

- [Official Documentation of the nss-pam-ldapd creator](https://arthurdejong.org/nss-pam-ldapd/setup)
- [Serverfault entry](https://serverfault.com/questions/166981/how-to-configure-ldap-to-resolve-host-names)
