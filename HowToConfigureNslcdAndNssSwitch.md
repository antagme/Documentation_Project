# How To configure nslcd daemon for retrieve information from Ldap Database.

## First steps

You should install [nss-pam-ldapd](https://arthurdejong.org/nss-pam-ldapd/) packet  which provides a Name Service Switch (NSS) module that allows your LDAP server to provide information.

In `Fedora` the order is the next.

 dnf install -y nss-pam-ldapd
