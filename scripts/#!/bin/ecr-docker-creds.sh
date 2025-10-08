#!/bin/bash

NAMESPACE=$1
kubectl create secret docker-registry ecr-creds \
  --docker-server=798262717396.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace="$NAMESPACE"
kubectl get sa default -n $NAMESPACE

# Patch the default service account to use the secret
kubectl patch serviceaccount default \
  -n "$NAMESPACE" \
  -p '{"imagePullSecrets": [{"name": "ecr-creds"}]}'

echo "ECR secret created and default service account patched in namespace '$NAMESPACE'."
