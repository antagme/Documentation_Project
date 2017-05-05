### StartTLS LDAP Producer Server Replicating without SASL GSSAPI Auth and with it

In this model, we will see how an _LDAP Server_ works as _Producer_ so that other _LDAP servers_ can replicate and act as Consumer.

We will have the _Consumer_ communicate with the _Producer_ through _simple authentication_.

On the other hand we will make another _Consumer_ do the same but through _SASL GSSAPI authentication_.

Finally we will verify that the **Client** can perform searches in both servers, and we will make modifications in the database of the _Producer_ and we will verify if it is really producing a correct replication.

_Docker Images_ used for this example:
- (Ldap StartTLS Producer + GSSAPI Keytab)[https://hub.docker.com/r/antagme/ldap_producer/]
- Kerberos
- Client for try some consults to Database
- Ldap StartTLS Consumer with Simple Authentication
- Ldap StartTLS Consumer with SASL GSSAPI Authentication
