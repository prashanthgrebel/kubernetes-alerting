Here’s a structured **Images Migration Document** template you can use to migrate Docker images from public registries to **AWS ECR** and deploy them in **Kubernetes**. I’ve broken it into clear steps with examples.

---

# **Docker Image Migration Document**

## **1. Identify Images from Existing Workloads**

**Objective:** List all images currently used by your applications/workloads.

### Steps:

1. **For Kubernetes workloads:**

   ```bash
   kubectl get deployments --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{range .spec.template.spec.containers[*]}{.image}{"\n"}{end}{end}'
   ```

   Output example:

   ```
   default frontend-app nginx:1.23
   default backend-app mysql:8.0
   ```

2. **For Docker workloads on hosts:**

   ```bash
   docker ps --format '{{.Names}}: {{.Image}}'
   ```

   Example:

   ```
   frontend-app: nginx:1.23
   backend-app: mysql:8.0
   ```

3. Create a **mapping table** of current images:
   | Application | Current Image | Tag | Notes |
   |-------------|---------------|-----|-------|
   | frontend-app | nginx | 1.23 | public repo |
   | backend-app  | mysql | 8.0  | public repo |

---

## **2. Create ECR Repositories**

**Objective:** Create private ECR repositories for your applications.

### Steps:

1. **Login to AWS CLI:**

   ```bash
   aws configure
   ```

2. **Create repository for each application:**

   ```bash
   aws ecr create-repository --repository-name frontend-app
   aws ecr create-repository --repository-name backend-app
   ```

3. **List ECR repositories:**

   ```bash
   aws ecr describe-repositories
   ```

---

## **3. Pull Images from Public Repo and Push to ECR**

**Objective:** Migrate images to ECR.

### Steps:

1. **Authenticate Docker with ECR:**

   ```bash
   aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
   ```

2. **Pull the public image:**

   ```bash
   docker pull nginx:1.23
   docker pull mysql:8.0
   ```

3. **Tag image for ECR:**

   ```bash
   docker tag nginx:1.23 <aws_account_id>.dkr.ecr.<region>.amazonaws.com/frontend-app:1.23
   docker tag mysql:8.0 <aws_account_id>.dkr.ecr.<region>.amazonaws.com/backend-app:8.0
   ```

4. **Push to ECR:**

   ```bash
   docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/frontend-app:1.23
   docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/backend-app:8.0
   ```

---

## **4. Create Docker Credentials at Namespace Level in Kubernetes**

**Objective:** Allow pods in a namespace to pull from ECR.

### Steps:

1. **Create Kubernetes secret with ECR credentials:**

   ```bash
   kubectl create secret docker-registry ecr-registry \
     --docker-server=<aws_account_id>.dkr.ecr.<region>.amazonaws.com \
     --docker-username=AWS \
     --docker-password=$(aws ecr get-login-password --region <region>) \
     --namespace <namespace>
   ```

2. **Attach secret to service accounts or pods:**

   ```yaml
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: default
     namespace: <namespace>
   imagePullSecrets:
     - name: ecr-registry
   ```

---

## **5. Replace Image Repo Path to ECR**

**Objective:** Update deployment manifests to use ECR images.

### Example:

**Before:**

```yaml
containers:
  - name: frontend
    image: nginx:1.23
```

**After:**

```yaml
containers:
  - name: frontend
    image: <aws_account_id>.dkr.ecr.<region>.amazonaws.com/frontend-app:1.23
```

---

## **6. Apply Updated Manifests**

```bash
kubectl apply -f frontend-deployment.yaml
kubectl apply -f backend-deployment.yaml
```

Verify pods are running and pulling from ECR:

```bash
kubectl get pods -n <namespace> -o wide
kubectl describe pod <pod_name> -n <namespace>
```

---

## ✅ Notes & Best Practices

* Always tag ECR images explicitly (avoid `latest`).
* Enable **ECR lifecycle policies** to manage old images.
* Use **namespace-specific image pull secrets** for multi-tenant clusters.
* Consider **automation with scripts or CI/CD** for future migrations.

---

I can also create a **diagram/flow chart** showing **public repo → pull → ECR → Kubernetes** for your documentation.

Do you want me to do that?
