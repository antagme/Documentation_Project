# Create own CA and certificates for LDAP

## Quick Explanation

I gonna explain how create own CA for sign certificates and how create a certificate for the LDAP server and sign it.

## How to 

### How to create the CA

  openssl genrsa -des3 -out CA.key 1024


For more information about supervisor check the [Official Documentation](http://supervisord.org/)

## Bibliography

- [Official Supervisor Documentation](http://supervisord.org/)
- [Docker Documentation abour run multiples services in a docker](https://docs.docker.com/engine/admin/multi-service_container/)
- [Sample file of Supervisor](https://github.com/Supervisor/supervisor/blob/master/supervisor/skel/sample.conf)


