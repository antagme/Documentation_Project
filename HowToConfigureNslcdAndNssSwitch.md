# How To configure nslcd daemon for retrieve information from Ldap Database.

## First steps

You should install [nss-pam-ldapd](https://arthurdejong.org/nss-pam-ldapd/) packet  which provides a Name Service Switch (NSS) module that allows your LDAP server to provide information.

In `Fedora` the order is the next.

    dnf install -y nss-pam-ldapd

This will provide you some new files [/etc/nslcd.conf](https://raw.githubusercontent.com/antagme/ldap_supervisor/master/files/nslcd.conf) and [/etc/nsswitch.conf](https://raw.githubusercontent.com/antagme/ldap_supervisor/master/files/nsswitch.conf).

## Configuring nslcd daemon for retrieve information.

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


