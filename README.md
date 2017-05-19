# Final Project EDT | LDAP TLS SASL
_Advanced Use of Dockerized Openldap Server and alternatives to secure and improve your Openldap Server_

## Overview

With different _Dockers Containers_ we gonna construct some examples around _LDAP SERVER container_.

## Description of the Project

Let's assume you all have some idea about [LDAP](https://es.wikipedia.org/wiki/OpenLDAP), theorical or practical.

In this project we are going to study different examples based on the _Openldap_ service through docker container.
In particular, I have chosen 4 examples in which we can see technologies that although very different, can be used to improve our ldap server.

## The Examples

### Example 1 - StartTLS LDAP Server With SASL GSSAPI Auth

In this model, we will perform a _GSSAPI Authentication_ using the Openldap client utilities. For this we will use a total of 3 _Docker Containers_.
All communication between the client and the _LDAP SERVER_ is encrypted using the _TLS_ protocol, using port 389, the default for unencrypted communications, but thanks to _StartTLS_, we can use it for secure communications

_Docker Images_ used for this example:
- [Ldap StartTLS + GSSAPI Keytab](https://hub.docker.com/r/antagme/ldap_gssapi/) 
- [Kerberos](https://hub.docker.com/r/antagme/kerberos/)
- [Client for try some consults to Database](https://hub.docker.com/r/antagme/client_gssapi/)

[For more information about this model...](https://github.com/antagme/Documentation_Project/blob/master/example1.md)

### Example 2 -StartTLS LDAP Producer Server Replicating without SASL GSSAPI Auth and with it

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

[For more information about this model...](https://github.com/antagme/Documentation_Project/blob/master/example2.md)

### Example 3 - Client with PAM + SSSD for Kerberos Auth , LDAP user information and Kerberos Password

In this model, starting from example one, we will see how to make a more secure authentication in the system using the best of Kerberos and Ldap technologies.

For this example, in the Client we will see how the System-Auth works with these two technologies, and we will perform a series of checks to make sure it works correctly.

_Docker Images_ used for this example:
- [Ldap StartTLS + GSSAPI Keytab](https://hub.docker.com/r/antagme/ldap_sssd)
- [Kerberos](https://hub.docker.com/r/antagme/kerberos/)
- [Client PAM + ldapwhoami](https://hub.docker.com/r/antagme/client/)

[For more information about this model...](https://github.com/antagme/Documentation_Project/blob/master/example3.md)

### Example 4 - Zabbix Monitoring to Monitor Database from Openldap Server

Finally, in this model, we will see in a Zabbix server how to have monitored by graphs, all the operations that are done in our LDAP Server and all connections to it.

_Docker Images_ used for this example:
- [Ldap StartTLS with Crond Python Script](https://hub.docker.com/r/antagme/ldap_zabbix)
- [Kerberos](https://hub.docker.com/r/antagme/kerberos)
- [Client for do some searchs and see the graphs](https://hub.docker.com/r/antagme/client_gssapi)
- [Zabbix with Openldap Custom Template](https://hub.docker.com/r/antagme/httpd/)

[For more information about this model...](https://github.com/antagme/Documentation_Project/blob/master/example4.md)

## Summary

### Summary of the examples

So we have the next _Dockers Images_ , each with differents configurations:

- Docker LDAP
- Docker Kerberos
- Docker Client (Simulating a School Client)
- Docker LDAP Replica 
- Docker Apache + Mysql + Zabbix

**Note** _: Each Docker Container have their own work. Also , when i was preparating my project , i decided to use a most secure auth than the simple one of LDAP , so i decided  to implement GSSAPI , the best one for this environment , but u have another options. See ([Auth Types](http://www.openldap.org/doc/admin24/security.html#Authentication%20Methods)) for more information_

### Summary of Used Technologies

* [Openldap](https://www.openldap.org/)
  * Object Class used:
      * To Retrieve Users.
      * To Retrieve Grups.
      * To Retrieve Hosts.
  * [AuthTypes Working:](https://www.openldap.org/doc/admin24/sasl.html)
     * [SASL GSSAPI(Kerberos Ticket Auth)](https://github.com/antagme/Documentation_Project/blob/master/example1.md#configure)
  * [StartTLS Security Transport Layer](https://www.openldap.org/doc/admin24/tls.html)
  * [Replication Consumer LDAP with StartTLS Communication And SASL GSSAPI](https://github.com/antagme/Documentation_Project/blob/master/example2.md).
* [Docker](https://docs.docker.com/)
* [Openssl](https://www.openssl.org/) [To create Own Certificates for each service that need it](https://github.com/antagme/Documentation_Project/blob/master/CertificatesLDAP.md)
* [Supervisord](http://supervisord.org/)
    * [To Manage the Processes inside the _Dockers Containers_ ](https://github.com/antagme/Documentation_Project/blob/master/HowToSupervisor.md)
* [Nslcd](https://arthurdejong.org/nss-pam-ldapd/)
    * [For retrieve Hosts Info](https://github.com/antagme/Documentation_Project/blob/master/HowToConfigureNslcdAndNssSwitch.md)
* [Kerberos](https://web.mit.edu/kerberos/)
  * [Do _Kerberos Auth_ with _SSSD_](https://github.com/antagme/Documentation_Project/blob/master/example3.md)
  * [_GSSAPI Auth_ with ldap clients](https://github.com/antagme/Documentation_Project/blob/master/example1.md#configure)
* [PAM](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Managing_Smart_Cards/Pluggable_Authentication_Modules.html)
  * [For the propertly _System-Auth_ With _Kerberos_ + _LDAP_](https://github.com/antagme/Documentation_Project/blob/master/example3.md)
* [Zabbix Agentd y Zabbix Server](http://www.zabbix.com/)
  * [For Monitoring  _LDAP Monitor Database_ with a _Python Script_](https://github.com/antagme/Documentation_Project/blob/master/example4.md)
* Crond
  * [For Automated execution of the _Python Script_ for _LDAP Monitor Database_ each minute](https://github.com/antagme/Documentation_Project/blob/master/example4.md)

![Alt text](http://octodex.github.com/images/stormtroopocat.jpg "The Stormtroopocat")

## Appendix

- All the entries used in Ldap Database has been created on the M06 Subject in [Escola del Treball](https://www.escoladeltreball.org) School
