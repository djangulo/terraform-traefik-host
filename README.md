# Træfik host

Træfik routed host.

`docker-compose.yml` defines a `træfik` service as follows:

```yml
version: "3"

services:
  traefik:
    image: traefik:v2.1
    container_name: "traefik"
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.leresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.leresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.leresolver.acme.email=postmaster@mydomain.com"
      - "--certificatesresolvers.leresolver.acme.email=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./letsencrypt:/letsencrypt:rw
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

The idea is that you setup your services in a `traefik/services/service-a` subdirectory, each with a `docker-compose.yml`, as such:

```yml
# services/service-a/docker-compose.yml
version: "3"

services:
  service_a:
    build:
      context: .
      dockerfile: ./services/service-a/Dockerfile
    volumes:
      - ./services/service-a/config:/config
      - ./services/service-a/db:/db
    command: start-my-webapp -p 8080
    environment:
      DB_URI: postgres://user:pass@host:port/db
      MY_SECRET: abcd1234
    ports:
      - "8080:8080"
    labels:
      - "traefik.enable=true"
      - "traefik.http.middlewares.service_a.redirectscheme.scheme=https"
      - "traefik.http.middlewares.service_a.redirectscheme.port=443"
      - "traefik.http.middlewares.service_a.redirectscheme.permanent=true"
      - "traefik.http.routers.service_a.middlewares=service_a"
      - "traefik.http.routers.service_a.rule=Host(`mywebapp.mydomain.com`)"
      - "traefik.http.routers.service_a.entrypoints=web"
      - "traefik.http.routers.service_a_tls.rule=Host(`mywebapp.mydomain.com`)"
      - "traefik.http.routers.service_a_tls.entrypoints=websecure"
      - "traefik.http.routers.service_a_tls.tls=true"
      - "traefik.http.routers.service_a_tls.tls.certresolver=leresolver"
```

You can concatenate files with the `compose.sh` script. Assuming you have `services/{service-a,service-b,service-c}`, it will produce and run an output equivalent to this. All arguments to `docker-compose` are appended to the chained files.

```bash
$ ./compose.sh up --detach
docker-compose -f docker-compose.yml \
  -f ./services/service-a/docker-compose.yml \
  -f ./services/service-b/docker-compose.yml \
  -f ./services/service-c/docker-compose.yml \
  up --detach
```
