# Run Drupal in Docker or Kubernetes

This is a Docker and Kubernetes environment to run, test and develop Drupal 8.

Images are based on PHP 7.0 and Apache2, and mariadb:
- [Debian 9 / Stretch](https://cloud.docker.com/swarm/wepoca/repository/docker/wepoca/stretch-php7).
- [Ubuntu 16.04 LTS](https://cloud.docker.com/swarm/wepoca/repository/docker/wepoca/lts-php7).

## Usage in Docker:
1. read and change docker-compose.yml:
  - set `DRUPAL_VERSION` as you wish
  - review other variables

2. choose images:
  - default is to download images from [wepoca/drupal](https://cloud.docker.com/swarm/wepoca/repository/docker/wepoca/drupal)
  - to use your local build, uncomment `line build: .` and
    remove the line `image: wepoca/drupal`

3. use docker-compose.yml to start up volumes, containers to fly :)
  - start up using wepoca/drupal:

    `docker-compose up`
  - or start up using your own local builds:

    `docker-compose up --build`

4. shut down:
  - stop containers, but maintain persistent data:

    `docker-compose down`
  - full shutdown, including remove of all data on persistent volumes:

    `docker-compose down --volume`

## Usage in Kubernetes:
Review the yaml files in K8S folder.
