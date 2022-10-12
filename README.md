# nginx-acme

Automatically create and renew website SSL certificates using the
[Let's Encrypt](https://letsencrypt.org/) free certificate authority.
Built on top of the [official Nginx Docker images](https://github.com/nginxinc/docker-nginx) (Debian, Alpine (coming soon)).

> :information_source: Please use a specific tag.
  when doing a Docker pull, since `:latest` might not always be 100% stable.

# Acknowledgments and Thanks

This container requests SSL certificates from [Let's Encrypt](https://letsencrypt.org/), which they provide for the absolutely bargain price of free! If you like what they do, please [donate](https://letsencrypt.org/donate/).

# Usage

## Before You Start
1. This guide expects you to already own a domain which points at the correct
   IP address, and that you have both port `80` and `443` correctly forwarded
   if you are behind NAT.
   ```bash
   $ docker run --rm -it nginx-acme:latest manage-vhosts --find-my-ip
   Your public IP seems to be: 1.2.3.4  
   You may point your (sub)domain to this IP.  
   Your IP might be different in case you are using NAT or different internet gateway!  
   It's just a best effort guess!
   ````
   
2. It is probably not necessary to mention if you managed to find this
   repository, but you will need to have [Docker](https://docs.docker.com/engine/install/) installed for this to
   function.

## Volumes
- `/acmecerts`: Stores the obtained certificates
- TODO: add other volumes.


## Run with `docker run`

```bash
docker run -it -p 80:80 -p 443:443 \
           -v $(pwd)/certs:/acmecerts \
           --name nginx-acme cancomtest/nginx-acme:latest
```

> :information_source: You should be able to detach from the container by holding `Ctrl` and pressing
  `p` + `q` after each other.

## Run with `docker-compose`

```bash
$ docker-compose up -d
```
