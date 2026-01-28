![banner](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/banner/README.png)

# RCLONE
![size](https://img.shields.io/badge/image_size-31MB-green?color=%2338ad2d)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![pulls](https://img.shields.io/docker/pulls/11notes/rclone?color=2b75d6)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)[<img src="https://img.shields.io/github/issues/11notes/docker-rclone?color=7842f5">](https://github.com/11notes/docker-rclone/issues)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

run rclone rootless.

# INTRODUCTION 📢

[Rclone](https://github.com/rclone/rclone) (created by [rclone](https://github.com/rclone)) (rsync for cloud storage) is a command-line program to sync files and directories to and from different cloud storage providers.

# SYNOPSIS 📖
**What can I do with this?** This image will run rclone [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md), for maximum security and performance. It will always add ```--rc``` to your command and expose the metrics as well as reading the config from ```/rclone/etc/default.conf```, the rest is up to you.

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image is auto updated to the latest version via CI/CD
>* ... this image has a health check
>* ... this image is automatically scanned for CVEs before and after publishing
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | **size on disk** | **init default as** | **[distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)** | supported architectures
| ---: | ---: | :---: | :---: | :---: |
| 11notes/rclone | 31MB | 1000:1000 | ❌ | amd64, arm64, armv7 |
| rclone/rclone | 83MB | 0:0 | ❌ | 386, amd64, arm64, armv6, armv7 |

# VOLUMES 📁
* **/rclone/etc** - Directory of the configuration file

# COMPOSE ✂️
```yaml
name: "rclone"

x-lockdown: &lockdown
  # prevents write access to the image itself
  read_only: true
  # prevents any process within the container to gain more privileges
  security_opt:
    - "no-new-privileges=true"

x-readonly: &readonly
  # prevents write access to the image itself
  read_only: true

services:
  minio:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-minio
    image: "11notes/minio:2025.10.15"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      MINIO_ROOT_PASSWORD: "${MINIO_ROOT_PASSWORD}"
    command: "/mnt"
    volumes:
      - "minio.var:/mnt"
    networks:
      backend:
    restart: "always"

  mc:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-mc
    depends_on:
      minio:
        condition: "service_healthy"
        restart: true
    image: "11notes/mc:2025.08.13"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      MC_MINIO_URL: "https://minio:9000"
      MC_MINIO_ROOT_PASSWORD: "${MINIO_ROOT_PASSWORD}"
      MC_INSECURE: true
    command:
      - mb --ignore-existing minio/rclone
    volumes:
      - "mc.etc:/mc/etc"
    networks:
      backend:
    restart: "no"

  rclone:
    depends_on:
      mc:
        condition: service_completed_successfully
    image: "11notes/rclone:1.72.1"
    <<: *readonly
    cap_add:
      - SYS_ADMIN
    devices:
      - /dev/fuse:/dev/fuse
    command: "mount 11notes:rclone/ /rclone/mnt --allow-other --vfs-cache-mode writes --cache-dir /rclone/cache --no-modtime --allow-non-empty --vfs-read-chunk-streams 16 --vfs-read-chunk-size 4M --no-check-certificate"
    environment:
      TZ: "Europe/Zurich"
      RCLONE_CONFIG: |-
        [11notes]
        type = s3
        provider = Minio
        env_auth = false
        access_key_id = admin
        secret_access_key = ${MINIO_ROOT_PASSWORD}
        region =
        endpoint = https://minio:9000
        location_constraint =
        server_side_encryption =
    volumes:
      - "rclone.etc:/rclone/etc"
      - "${PWD}/mnt:/rclone/mnt:rshared"
      - "rclone.cache:/rclone/cache"
    networks:
      backend:
    restart: "always"

  prometheus:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-prometheus
    depends_on:
      rclone:
        condition: "service_healthy"
        restart: true
    image: "11notes/prometheus:3.8.1"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      PROMETHEUS_CONFIG: |-
        global:
          scrape_interval: 5s

        scrape_configs:
          - job_name: "rclone"
            static_configs:
              - targets: ["rclone:5572"]
    volumes:
      - "prometheus.etc:/prometheus/etc"
      - "prometheus.var:/prometheus/var"
    ports:
      - "3000:3000/tcp"
    networks:
      frontend:
      backend:
    restart: "always"

volumes:
  mc.etc:
  minio.var:
  rclone.etc:
  rclone.cache:
  prometheus.etc:
  prometheus.var:

networks:
  frontend:
  backend:
    internal: true
```
To find out how you can change the default UID/GID of this container image, consult the [RTFM](https://github.com/11notes/RTFM/blob/main/linux/container/image/11notes/how-to.changeUIDGID.md#change-uidgid-the-correct-way).

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /rclone | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [1.72.1](https://hub.docker.com/r/11notes/rclone/tags?name=1.72.1)
* [1.72.1-unraid](https://hub.docker.com/r/11notes/rclone/tags?name=1.72.1-unraid)
* [1.72.1-nobody](https://hub.docker.com/r/11notes/rclone/tags?name=1.72.1-nobody)

### There is no latest tag, what am I supposed to do about updates?
It is my opinion that the ```:latest``` tag is a bad habbit and should not be used at all. Many developers introduce **breaking changes** in new releases. This would messed up everything for people who use ```:latest```. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:1.72.1``` you can use ```:1``` or ```:1.72```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version. Which in theory should not introduce breaking changes.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/rclone:1.72.1
docker pull ghcr.io/11notes/rclone:1.72.1
docker pull quay.io/11notes/rclone:1.72.1
```

# UNRAID VERSION 🟠
This image supports unraid by default. Simply add **-unraid** to any tag and the image will run as 99:100 instead of 1000:1000.

# NOBODY VERSION 👻
This image supports nobody by default. Simply add **-nobody** to any tag and the image will run as 65534:65534 instead of 1000:1000.

# SOURCE 💾
* [11notes/rclone](https://github.com/11notes/docker-rclone)

# PARENT IMAGE 🏛️
* [${{ json_readme_parent_image }}](${{ json_readme_parent_url }})

# BUILT WITH 🧰
* [rclone](https://github.com/rclone/rclone)
* [11notes/util](https://github.com/11notes/docker-util)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# CAUTION ⚠️
> [!CAUTION]
>* The compose example spins up minio (for S3) and connects rclone via an unverified SSL connection. In production, only connect to a verified destination with a valid SSL certificate!

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-rclone/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-rclone/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-rclone/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 28.01.2026, 09:28:19 (CET)*