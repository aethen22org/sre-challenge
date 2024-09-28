### Original README
# SRE DevOps Challenge
The goal of this technical exercise is to transform the attached docker compose file into a
K8S infrastructure. The project is a simple NextJS app that tracks user visits in a RedisDB. 
Our developers have created the following docker-compose.yml file:

```yaml
version: '2'
services: 
  app:
    build:
      context: .
      target: dev
    ports:
      - '3000:3000'
    volumes:
      - './app:/app/app'
      - './public:/app/public'
    links:
      - db
    environment:
      - REDIS_HOST=db
      - REDIS_PORT=6379
  db:
    image: 'redis'
```

The have been very keen to provide a multistage dockerfile with `runner` target that generates our prod build.

This app uses needs the following env vars to configure redis connection:

- REDIS_HOST: Host of the redis instance
- REDIS_PORT: Port of the redis instance
- REDIS_USERNAME: Redis instance username
- REDIS_PASSWORD: Redis instance password

## Exercise 1 - Pipelines

We need to generate the pipelines that build and publish the project image. Please provide scripts, github action or gitlab pipelines that build the image and publish it to the registry (feel free to use any public docker image registry of your choice).

## Exercise 2 - Kubernetes

We want to deploy this project to our K8S cluster. Please provide scripts, kubernetes manifest or helm charts that create the needed infrastructure. We use GKE but in this case feel free to use any locally hosted cluster (minikube, kind, etc..).
Write it as this was a real world production project, so keep into account things like High Avaliability, Autoscalling, Security, etc...

## Exercise 3 - Docs

Last but not least, please write a meaninful documentation of your design choices and how a developer can deploy the project.


# README

## Pipelines

Pipelines are controlled by Github Actions workflows and a makefile.

We have 2 pipelines, one that builds and pushes our docker image and one that builds and pushes our helm chart, it also deploys the application, but it should not, as this should be controlled by a GitOps tool.

Build pipeline runs on push, creating an image with the component name and the COMMIT_SHA as tag, and pushes it to the registry, it does that using the Makefile targets build and push, it also runs the unit-tests target, but it is empty as there are no unit tests.

The helm chart pipeline runs on tag creation, if that tag starts with v, this is intented to be used so we create versions with vX.X.X form, this pipeline sets up variables and runs the Makefile target build-chart, which in turn runs build and push to create a version-tagged docker image, after it is finished doing that, it goes to the environment ops folder and applies the helmfile configuration into the cluster. As said before, this step should be controlled by GitOps tools.

## Helm chart

We build a Helm chart from this repository using another one as a requirement, this one is called base, and it is a highly configurable, fully parameterized chart, the configuration about this creation on this repository is [here](ops\charts\sre-challenge), the files there are as follows:

Chart.yaml describes the chart that is going to be created, version is stated just to satisfy helm, but it is not used, as GIT_TAG is used to tag the version.

requirements.yaml describe the requirement for the base chart, it needs to point to the used version of the base chart, to check on this chart, see [here](https://github.com/aethen22org/Infra/tree/main/charts/base)

values.yaml describes the values passed to the base chart, so we can use them to create our own sub-chart's default values, these default values should be valid for local, and then be parsed for environments on each environment.

We also deploy the redis Bitnami helm chart, with some values to use a static password that is retrieved from a secret.

You can create said secret via `kubectl create secret generic sre-challenge-redis --from-literal=redis-password='YOUR_PASSWORD' -n sre-challenge`, if you cannot create the secret due to the namespace not existing, deploy the helmfile first and then create the secret, i would reapply the helmfile just in case.

### Important values in values.yaml

nameOverride is very important, as it will configure most of the names inside the chart.

registry, tag and pullPolicy are important, as they will dictate the image we use on our deployments.

The rest of the values are documented on the same file, if something is not clear, check the [base chart](https://github.com/aethen22org/Infra/tree/main/charts/base)

## Locally deploy

To locally deploy the application, apply the helmfile in ops/local, it should not work right now, as it is pointing to a local helm repository, but if our helm chart was deployed at a chart museum in the cloud or somewhere we could access(via RBAC or whichever), and we configured it in the helmfile repository url, it would deploy our helm chart in our cluster.

If the secret sre-challenge-redis is not created on the same namespace as the application, you will need to create it and reapply the helmfile.