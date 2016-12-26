[![build status](https://gitlab.com/tvaughan/docker-flask-starterkit/badges/master/build.svg)](https://gitlab.com/tvaughan/docker-flask-starterkit/commits/master)

Welcome to Starterkit
===

Starterkit is a sample application server that uses Docker to provide
consistent and repeatable build environments - production and development are
(almost) identical. This means that problems discovered in production should
be easy to reproduce, and there should be a high degree of confidence that new
features will behave as expected in production. Deployment is reduced to
pulling the latest Docker image.

This is meant as a starting template. This isn't a framework that one plugs
into. Think of this as starting from a few rungs up the ladder. Fork it and
then start mashing on that keyboard!

[Terraform AWS Starterkit](https://gitlab.com/tvaughan/terraform-aws-starterkit)
has been used to setup a demo instance in AWS which is available at
[www.starterkit.xyz](www.starterkit.xyz). Pull-requests merged into master are
[auto-deployed](https://gitlab.com/tvaughan/docker-flask-starterkit/pipelines)
to this demo instance. Feature branches are not deployed but are
[pushed to the container registry](https://gitlab.com/tvaughan/docker-flask-starterkit/container_registry)
on GitLab.

Caveat Emptor
---

* Deployments are not
  zero-downtime. [#4](https://gitlab.com/tvaughan/docker-flask-starterkit/issues/4)

Quick Start
===

* Install [Docker](https://www.docker.com/).

* Set some environment variables:
  * `GITLAB_PASSWORD=<personal access token[1]>`
  * `POSTGRES_HOSTNAME=postgres`
  * `POSTGRES_PASSWORD=password`
  * `SECRET_KEY=<random character string>`

[1] https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html

* Each in their own terminal window, run (order matters):
  * `make -f postgres.mk`
  * `make serve`
  * `make -f nginx-proxy-unit.mk`

* Open http://localhost.localdomain:8080

* Profit!

Develop
===

* Fork this repository.

* Change `tvaughan/docker-flask-starterkit` in the top-level Makefile to match
  the name of fork created in the previous step.

* `make shell`

  This will start the container, run a shell inside it, and mount the
  `flask-app/` directory inside the running container under `/opt/flask-app`.

* `make lint` and `make test`

  Run these commands to lint and test the built Docker image. The Docker image
  will be re-built if changes have been made under `flask-app/` since the last
  build. To prevent this re-building during development, run `make shell` then
  run these commands inside the running container.

* `make watch`

  This will run `make serve` whenever a change is detected under
  `flask-app/`. This will detect additions and deletions too.

Deploy
===

* Use
  [Terraform AWS Starterkit](https://gitlab.com/tvaughan/terraform-aws-starterkit)
  to provision the necessary resources in AWS.

* Set some environment variables in GitLab. Go to `Settings -> Variables` and:

  * Set `GITLAB_USERNAME` and `GITLAB_PASSWORD` where `GITLAB_PASSWORD` is a
    [personal access token](https://docs.gitlab.com/ee/api/README.html#personal-access-tokens).
    These are used to push the built Docker image to the container registry on
    GitLab.

  * Set `STARTERKIT_BASTION_IP_ADDR` and `STARTERKIT_INSTANCE_IP_ADDR` to the
    values reported by Terraform AWS Starterkit.

  * Set `STARTERKIT_BASTION_SSH_KEY` and `STARTERKIT_INSTANCE_SSH_KEY` to the
    contents of the key pairs created in the AWS console.

* Push a change to GitLab.

* Open `http://$STARTERKIT_DOMAIN`

* Profit!

* `make ssh-instance` (optional)

  Run this to start a remote shell on the application server instance in AWS.
