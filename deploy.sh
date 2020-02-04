#!/bin/bash
set -e

SERVICE_REPO_DIR=git_repos

DOCKER_REGISTRY_HOST=$1

KUBERTES_NAMESPACES=$(kubectl get ns)

if [[ "$KUBERTES_NAMESPACES" == *"panosc-kubernetes-instances"* ]] && [[ "$KUBERTES_NAMESPACES" == *"panosc-portal"* ]]; then
  echo "The namespaces panosc-portal and panosc-kubernetes-instances should not exist on your cluster."
  echo "Please delete them with the command 'kubectl delete ns panosc-kubernetes-instances panosc-portal' before you restart this script"
  exit
elif [[ "$KUBERTES_NAMESPACES" == *"panosc-portal"* ]]; then
  echo "The namespace panosc-portal should not exist on your cluster"
  echo "Please delete it with the command 'kubectl delete ns panosc-portal' before you restart this script"
  exit
elif [[ "$KUBERTES_NAMESPACES" == *"panosc-kubernetes-instances"* ]]; then
  echo "The namespace panosc-kubernetes-instances should not exist on your cluster"
  echo "Please delete it with the command 'kubectl delete ns panosc-kubernetes-instances' before you restart this script"
  exit
fi


# Create and clean git repos dir
mkdir -p $SERVICE_REPO_DIR
rm -rf "${SERVICE_REPO_DIR:?}/"*
rm -rf "${SERVICE_REPO_DIR:?}/".* || :

git clone https://github.com/panosc-portal/cloud-provider-kubernetes.git $SERVICE_REPO_DIR/cloud-provider-kubernetes


if [ "$http_proxy" ] || [ "$https_proxy" ] ; then
  useProxy=true
  httpProxy="$http_proxy"
  httpsProxy="$https_proxy"
elif [ "$HTTP_PROXY" ] || [ "$HTTPS_PROXY" ] ; then
  useProxy=true
  httpProxy="$http_proxy"
  httpsProxy="$https_proxy"
else
  useProxy=false
fi

if [ "$useProxy" ] ; then
  docker build -t cloud-provider-kubernetes --build-arg HTTP_PROXY="$httpProxy" --build-arg HTTPS_PROXY="$httpsProxy" $SERVICE_REPO_DIR/cloud-provider-kubernetes
else
  docker build -t cloud-provider-kubernetes $SERVICE_REPO_DIR/cloud-provider-kubernetes
fi

# push cloud-provider-kubernetes to docker registry
docker tag cloud-provider-kubernetes "$DOCKER_REGISTRY_HOST"/panosc-portal/cloud-provider-kubernetes
docker push "$DOCKER_REGISTRY_HOST"/panosc-portal/cloud-provider-kubernetes

## Remove git repos dir
rm -rf $SERVICE_REPO_DIR

helm install panosc-portal-demo --set dockerRegistry.host="${DOCKER_REGISTRY_HOST}" ./panosc-portal-demo-chart
