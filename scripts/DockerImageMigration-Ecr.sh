#!/bin/bash

## aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 798262717396.dkr.ecr.us-east-1.amazonaws.com
set -e

DOCKERHUB_IMAGE="$1"
ECR_REPO_NAME="$2"
ECR_ACCOUNT_ID="798262717396"
ECR_REGION="us-east-1"


if [ -z "$DOCKERHUB_IMAGE" ] || [ -z "$ECR_REPO_NAME" ]; then
    echo "Usage: $0 <dockerhub-image> <ecr-repo>"
    exit 1
fi

IMAGE_TAG="$(echo $DOCKERHUB_IMAGE | cut -d':' -f2)"
if [ -z "$IMAGE_TAG" ]; then
  IMAGE_TAG="latest"
fi

ECR_URI="$ECR_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com"
ECR_IMAGE="${ECR_URI}/${ECR_REPO_NAME}:$(echo $DOCKERHUB_IMAGE | cut -d':' -f2)"

echo "Pulling Docker image from Docker Hub: $DOCKERHUB_IMAGE"
docker pull "$DOCKERHUB_IMAGE"


echo "Logging in to AWS ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URI"

echo "Tagging image for ECR..."
docker tag "$DOCKERHUB_IMAGE" "$ECR_IMAGE"

echo "Creating ECR repo if it doesn't exist..."
aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1 || \
aws ecr create-repository --repository-name "$ECR_REPO_NAME" --region "$AWS_REGION"

echo "Pushing image to ECR: $ECR_IMAGE"
docker push "$ECR_IMAGE"

# ==============================
# Verify Push
# ==============================
echo "Verifying image in ECR..."
if aws ecr describe-images --repository-name "$ECR_REPO_NAME" --image-ids imageTag="$IMAGE_TAG" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "Image successfully pushed to ECR!"
    echo "ECR Image URI: $ECR_IMAGE"
else
    echo "Failed to verify image in ECR."
    exit 1
fi
