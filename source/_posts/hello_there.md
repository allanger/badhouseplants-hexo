---
title: Hexo with Kubernetes
tags:
- Kubernetes
- CI/CD
categories: 
- Devops
---

# An easy way to run hexo blog in Kubernetes


## Intro

This is the first article in my blog, and since I didn't know where to begin, I decided to describe how this blog is working. 
I wanted to write my own blog using [Rust](https://www.rust-lang.org/) and [Yew](https://yew.rs/), but it's a pretty complicated task. And as I wanted to start writing fast, I went with a [Hexo](https://hexo.io/) solution. It doesn't mean that I've given up on rust blog. I'll do it, just later. 

Here I'm not trying to describe how to create a blog using Hexo, this is more about how to deploy and update the blog.

I assume you're already familiar with k8s somehow. At least, you need to know what are **services**, **deployments**, and **ingress**. 
## Kubernetes

I've created a simple [Helm chart](https://github.com/allanger/allanger-charts/tree/main/web-static) to deploy sites. To use it with your site, you will need to create a `values.yaml` (this is values for deploying this blog):
```YAML
replicaCount: 1
image:
  repository: ghcr.io/allanger/badhouseplants-hexo
  pullPolicy: Always
  tag: latest
deployAnnotations: 
    keel.sh/policy: force
    keel.sh/trigger: poll
ingress:
  enabled: true
  proto: https
  annotations: 
    ingress.kubernetes.io/force-ssl-redirect: 'true'
    kubernetes.io/ingress.class: istio
  hosts:
    - host: badhouseplants.net
      paths:
        - path: /
          pathType: Prefix
  tls: 
    - secretName: blog-check-tls-ne
      hosts:
        - badhouseplants.net

resources: 
 limits:
   cpu: 100m
   memory: 128Mi
 requests:
   cpu: 100m
   memory: 128Mi

autoscaling:
  enabled: true
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 80

certificate:
  enabled: true
  namespace: istio-system
  issuerRef: 
    name: cluster-issuer-acme-cluster-issuer
    kind: ClusterIssuer 

```


The chart is very simple. You can spend 10 minutes and completely understand what's going on there. But in this `values.yaml` there is a thing that may not be obvious. 

## What is Keel?

[Source code](https://github.com/keel-hq/keel)

Keel is a CD tool that is running inside a cluster and pulling images from registry. I am using it in all my projects. 

With these annotations:
```
keel.sh/policy: force
keel.sh/trigger: poll
```
It will update the deployment every time an image is being updated in the registry. And it seems like a perfect match for blogging thing where you don't really care about versioning and something like that. Every time I'm pushing a new image to registry, my blog is automatically updated.

## How to configure Keel?

I'm using [helm](https://helm.sh/) for it. And I'm using [helmfile](https://github.com/roboll/helmfile) for installing and maintaining helm releases in clusters. So my configuration looks like that:
```yaml
repositories:
  - name: keel
    url: https://charts.keel.sh
  - name: web-static
    url: git+https://github.com/allanger/allanger-charts@web-static/?ref=main


commonLabels:
  helmfile: "true"
  deploy_date: DEPLOY_DATE
  deployed_by: DEPLOYED_BY

releases:
  # -----------------------------
  # -- Keel
  # -----------------------------
  - name: keel
    namespace: keel-system
    createNamespace: true
    chart: keel/keel
    installed: true
  # -----------------------------
  # -- Web Hosting
  # -----------------------------
  - name: badhouseplants-hexo
    namespace: web-static
    createNamespace: true
    installed: true
    chart: web-static/web-static
    values: 
      - values/badhouseplants-hexo.yaml
```

And that's it. With this helmfile you can simply do `$ helmfile -f helmfile.yaml apply` and you blog is deployed and "self-maintained".

## CI 

But there is one more thing that's not automated. You still need to build docker images and push them to the registry yourself. 
If you don't wanna do that, you need to configure **CI**. As I'm using GitHub for storing my blog project, I'm using GitHub Actions for building and pushing.

I'm using action like that:
```YAML
---
name: Latest docker image

on:
  push:
    branches: [main]

jobs:
  build-and-push-latest:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
        with:
          submodules: recursive
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1

      - name: Set action link variable
        run: echo "LINK=$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID" >> $GITHUB_ENV

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v1
        with:
          registry: ghcr.io
          username: ${{ github.repository_owner }}
          password: ${{ secrets.CR_PAT }}

      - name: Build and push
        uses: docker/build-push-action@v2
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: |
            ghcr.io/allanger/badhouseplants-hexo:latest
          labels: |
            action_id=${{ github.action }}
            action_link=${{ env.LINK }}
            actor=${{ github.actor }}
            sha=${{ github.sha }}
            ref=${{ github.ref }}
```

To use it for your site, you need to replace "ghcr.io/allanger/badhouseplants-hexo" with you registry name. And do the same in the `values.yaml` file of course. 

Also, you need to add a `CR_PAT` secret too your repo. It should be a GitHub access token that can be used for pushing images to registry. 

And the latest step is the `Dockerfile`.

My looks like that:
```Docker
FROM node AS builder
WORKDIR /app
COPY package.json ./
COPY ./ ./
RUN npm i
RUN npm install -g hexo-cli
RUN hexo generate --deploy

FROM nginx:alpine
COPY --from=builder /app/public /usr/share/nginx/html
```

## That's it. 
Now all you have to do is push to the main branch. And your blog is deployed. 