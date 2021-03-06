# ETHICLAB STEPS

```
root@ethicserver3:~/docker-pdns# apt update
root@ethicserver3:~/docker-pdns# apt install software-properties-common
root@ethicserver3:~/docker-pdns# apt-add-repository --yes --update ppa:ansible/ansible
root@ethicserver3:~/docker-pdns# apt install ansible
root@ethicserver3:~/docker-pdns# apt install python-docker
export LC_ALL=C
pip install --upgrade docker-py
root@ethicserver3:~/docker-pdns# ansible-playbook ansible-playbook.yml
```
# TSIG-ALLOW-DNSUPDATE

This setting allows you to set the TSIG key required to do an DNS update. If you have GSS-TSIG enabled, you can use Kerberos principals here. An example, using pdnsutil to create the key:

$ pdnsutil generate-tsig-key test hmac-md5
Create new TSIG key test hmac-md5 xxxxxxxxxxxxxxxxxxxxxxxxxxx

To enable TSIG Update funcion run this insert:

```
INSERT INTO `domainmetadata` (`id`, `domain_id`, `kind`, `content`) VALUES
(2, 1, 'SOA-EDIT-API', 'DEFAULT'),
(3, 1, 'TSIG-ALLOW-DNSUPDATE', 'test'),
(4, 1, 'ALLOW-DNS-UPDATE-FROM', 'xx.xx.xx.xx/32'),
(5, 1, 'SOA-EDIT-DNSUPDATE', 'INCREASE');
```
all updates received from xx.xx.xx.xx will be enabled

Now you can use TSIG key and hmac-md5 password to test with nsupdate.sh script


# PowerDNS Docker Images

This repository contains four Docker images - pdns-mysql, pdns-recursor, pdns-admin-static and pdns-admin-uwsgi. Image **pdns-mysql** contains completely configurable [PowerDNS 4.x server](https://www.powerdns.com/) with mysql backend (without mysql server). Image **pdns-recursor** contains completely configurable [PowerDNS 4.x recursor](https://www.powerdns.com/). Images **pdns-admin-static** and **pdns-admin-uwsgi** contains fronted (nginx) and backend (uWSGI) for [PowerDNS Admin](https://github.com/ngoduykhanh/PowerDNS-Admin) web app, written in Flask, for managing PowerDNS servers.

There are two versions of PowerDNS Admin - the old and deprecated `pschiffe/pdns-admin-uwsgi:latest` and `pschiffe/pdns-admin-static:latest` based on https://git.0x97.io/0x97/powerdns-admin . The new and updated version with more features is available as `pschiffe/pdns-admin-uwsgi:ngoduykhanh` and `pschiffe/pdns-admin-static:ngoduykhanh` and is based on https://github.com/ngoduykhanh/PowerDNS-Admin . The `latest` tag points to the older version of PowerDNS Admin for backwards compatibility.

The pdns-mysql and pdns-recursor images have also the `alpine` tag thanks to the @PoppyPop .

All images are available on Docker Hub:

https://hub.docker.com/r/pschiffe/pdns-mysql/

https://hub.docker.com/r/pschiffe/pdns-recursor/

https://hub.docker.com/r/pschiffe/pdns-admin-uwsgi/

https://hub.docker.com/r/pschiffe/pdns-admin-static/

## pdns-mysql

[![](https://images.microbadger.com/badges/version/pschiffe/pdns-mysql.svg)](https://microbadger.com/images/pschiffe/pdns-mysql "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/pschiffe/pdns-mysql.svg)](http://microbadger.com/images/pschiffe/pdns-mysql "Get your own image badge on microbadger.com")

[![](https://images.microbadger.com/badges/version/pschiffe/pdns-mysql:alpine.svg)](https://microbadger.com/images/pschiffe/pdns-mysql:alpine "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/pschiffe/pdns-mysql:alpine.svg)](https://microbadger.com/images/pschiffe/pdns-mysql:alpine "Get your own image badge on microbadger.com")

https://hub.docker.com/r/pschiffe/pdns-mysql/

Docker image with [PowerDNS 4.x server](https://www.powerdns.com/) and mysql backend (without mysql server). For running, it needs external mysql server. Env vars for mysql configuration:
```
(name=default value)

PDNS_gmysql_host=mysql
PDNS_gmysql_port=3306
PDNS_gmysql_user=root
PDNS_gmysql_password=powerdns
PDNS_gmysql_dbname=powerdns
```
If linked with official [mariadb](https://hub.docker.com/_/mariadb/) image with alias `mysql`, the connection can be automatically configured, so you don't need to specify any of the above. Also, DB is automatically initialized if tables are missing.

PowerDNS server is configurable via env vars. Every variable starting with `PDNS_` will be inserted into `/etc/pdns/pdns.conf` conf file in the following way: prefix `PDNS_` will be stripped and every `_` will be replaced with `-`. For example, from above mysql config, `PDNS_gmysql_host=mysql` will became `gmysql-host=mysql` in `/etc/pdns/pdns.conf` file. This way, you can configure PowerDNS server any way you need within a `docker run` command.

There is also a `SUPERMASTER_IPS` env var supported, which can be used to configure supermasters for slave dns server. [Docs](https://doc.powerdns.com/md/authoritative/modes-of-operation/#supermaster-automatic-provisioning-of-slaves). Multiple ip addresses separated by space should work.

You can find [here](https://doc.powerdns.com/md/authoritative/) all available settings.

### Examples

Master server with API enabled and with one slave server configured:
```
docker run -d -p 53:53 -p 53:53/udp --name pdns-master \
  --hostname ns1.example.com --link mariadb:mysql \
  -e PDNS_master=yes \
  -e PDNS_api=yes \
  -e PDNS_api_key=secret \
  -e PDNS_webserver=yes \
  -e PDNS_webserver_address=0.0.0.0 \
  -e PDNS_webserver_password=secret2 \
  -e PDNS_version_string=anonymous \
  -e PDNS_default_ttl=1500 \
  -e PDNS_soa_minimum_ttl=1200 \
  -e PDNS_default_soa_name=ns1.example.com \
  -e PDNS_default_soa_mail=hostmaster.example.com \
  -e PDNS_allow_axfr_ips=172.5.0.21 \
  -e PDNS_only_notify=172.5.0.21 \
  pschiffe/pdns-mysql
```

Slave server with supermaster:
```
docker run -d -p 53:53 -p 53:53/udp --name pdns-slave \
  --hostname ns2.example.com --link mariadb:mysql \
  -e PDNS_gmysql_dbname=powerdnsslave \
  -e PDNS_slave=yes \
  -e PDNS_version_string=anonymous \
  -e PDNS_disable_axfr=yes \
  -e PDNS_allow_notify_from=172.5.0.20 \
  -e SUPERMASTER_IPS=172.5.0.20 \
  pschiffe/pdns-mysql
```

## pdns-recursor

[![](https://images.microbadger.com/badges/version/pschiffe/pdns-recursor.svg)](https://microbadger.com/images/pschiffe/pdns-recursor "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/pschiffe/pdns-recursor.svg)](https://microbadger.com/images/pschiffe/pdns-recursor "Get your own image badge on microbadger.com")

[![](https://images.microbadger.com/badges/version/pschiffe/pdns-recursor:alpine.svg)](https://microbadger.com/images/pschiffe/pdns-recursor:alpine "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/pschiffe/pdns-recursor:alpine.svg)](https://microbadger.com/images/pschiffe/pdns-recursor:alpine "Get your own image badge on microbadger.com")

https://hub.docker.com/r/pschiffe/pdns-recursor/

Docker image with [PowerDNS 4.x recursor](https://www.powerdns.com/).

PowerDNS recursor is configurable via env vars. Every variable starting with `PDNS_` will be inserted into `/etc/pdns/recursor.conf` conf file in the following way: prefix `PDNS_` will be stripped and every `_` will be replaced with `-`. For example, from above mysql config, `PDNS_gmysql_host=mysql` will became `gmysql-host=mysql` in `/etc/pdns/recursor.conf` file. This way, you can configure PowerDNS recursor any way you need within a `docker run` command.

You can find [here](https://doc.powerdns.com/md/recursor/settings/) all available settings.

### Examples

Recursor server with API enabled:
```
docker run -d -p 53:53 -p 53:53/udp --name pdns-recursor \
  -e PDNS_api=yes \
  -e PDNS_api_key=secret \
  -e PDNS_webserver=yes \
  -e PDNS_webserver_address=0.0.0.0 \
  -e PDNS_webserver_password=secret2 \
  pschiffe/pdns-recursor
```

## pdns-admin-uwsgi

[![](https://images.microbadger.com/badges/version/pschiffe/pdns-admin-uwsgi:ngoduykhanh.svg)](https://microbadger.com/images/pschiffe/pdns-admin-uwsgi:ngoduykhanh "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/pschiffe/pdns-admin-uwsgi:ngoduykhanh.svg)](https://microbadger.com/images/pschiffe/pdns-admin-ngoduykhanh:alpine "Get your own image badge on microbadger.com")

https://hub.docker.com/r/pschiffe/pdns-admin-uwsgi/

Docker image with backend of [PowerDNS Admin](https://github.com/ngoduykhanh/PowerDNS-Admin) web app, written in Flask, for managing PowerDNS servers. This image contains the python part of the app running under uWSGI. It needs external mysql server. Env vars for mysql configuration:
```
(name=default value)

PDNS_ADMIN_SQLA_DB_HOST="'mysql'"
PDNS_ADMIN_SQLA_DB_PORT="'3306'"
PDNS_ADMIN_SQLA_DB_USER="'root'"
PDNS_ADMIN_SQLA_DB_PASSWORD="'powerdnsadmin'"
PDNS_ADMIN_SQLA_DB_NAME="'powerdnsadmin'"
```
If linked with official [mariadb](https://hub.docker.com/_/mariadb/) image with alias `mysql`, the connection can be automatically configured, so you don't need to specify any of the above. Also, DB is automatically initialized if tables are missing.

Similar to the pdns-mysql, pdns-admin is also completely configurable via env vars. Prefix in this case is `PDNS_ADMIN_`, but there is one caveat: as the config file is a python source file, every string value must be quoted, as shown above. Double quotes are consumed by Bash, so the single quotes stay for Python. (Port number in this case is treated as string, because later on it's concatenated with hostname, user, etc in the db uri). Configuration from these env vars will be written to the `/opt/powerdns-admin/config.py` file.

### Connecting to the PowerDNS server

For the pdns-admin to make sense, it needs a PowerDNS server to manage. The PowerDNS server needs to have exposed API (example configuration for PowerDNS 4.x):
```
api=yes
api-key=secret
webserver=yes
webserver-address=0.0.0.0
webserver-allow-from=172.5.0.0/16
```

And again, PowerDNS connection is configured via env vars (it needs url of the PowerDNS server, api key and a version of PowerDNS server, for example 4.0.1):
```
(name=default value)

PDNS_API_URL="http://pdns:8081/"
PDNS_API_KEY=""
PDNS_VERSION=""
```
*These values are stored in the DB and thus cannot contain double-quoting as configuration described above.*

If this container is linked with pdns-mysql from this repo with alias `pdns`, it will be configured automatically and none of the env vars from above are needed to be specified.

### Persistent data

There is a directory with user uploads which should be persistent: `/opt/powerdns-admin/upload`

### Example

When linked with pdns-mysql from this repo and with LDAP auth:
```
docker run -d --name pdns-admin-uwsgi \
  --link mariadb:mysql --link pdns-master:pdns \
  -v pdns-admin-upload:/opt/powerdns-admin/upload \
  pschiffe/pdns-admin-uwsgi:ngoduykhanh
```

## pdns-admin-static

[![](https://images.microbadger.com/badges/version/pschiffe/pdns-admin-static:ngoduykhanh.svg)](https://microbadger.com/images/pschiffe/pdns-admin-static:ngoduykhanh "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/pschiffe/pdns-admin-static:ngoduykhanh.svg)](https://microbadger.com/images/pschiffe/pdns-admin-static:ngoduykhanh "Get your own image badge on microbadger.com")

https://hub.docker.com/r/pschiffe/pdns-admin-static/

Fronted image with nginx and static files for [PowerDNS Admin](https://github.com/ngoduykhanh/PowerDNS-Admin). Exposes port 80 for connections, expects uWSGI backend image under `pdns-admin-uwsgi` alias.

### Example

```
docker run -d -p 8080:80 --name pdns-admin-static \
  --link pdns-admin-uwsgi:pdns-admin-uwsgi \
  pschiffe/pdns-admin-static:ngoduykhanh
```

## ansible-playbook.yml

Included ansible playbook can be used to build and run the containers from this repo. Run it with:
```
ansible-playbook ansible-playbook.yml
```
