
## **📘 Deploying PostgreSQL to a Dedicated Node Group in Kubernetes*

### **Overview**

We want a PostgreSQL pod to:

1. Run **only** on a specific set of nodes (a dedicated node group).
2. Prevent **any other pods** from being scheduled on those nodes.
3. Use **taints** and **tolerations** to enforce this.
4. Use a **nodeSelector** to choose the right nodes.

---

## **1️⃣ Taint the Dedicated Nodes**

A **taint** tells Kubernetes:

> “Don’t schedule anything here unless the pod explicitly tolerates this taint.”

### **Step 1: Find your node group**

```bash
kubectl get nodes --show-labels
```

Look for a label identifying your node group, e.g.:

```
eks.amazonaws.com/nodegroup=my-nodegroup
```

### **Step 2: Apply the taint**

This will stop all other pods from being scheduled on those nodes:

```bash
kubectl taint nodes <node-name> dedicated=singlepod:NoSchedule
```

For all nodes in the group:

```bash
kubectl get nodes -l eks.amazonaws.com/nodegroup=my-nodegroup -o name \
| xargs -I {} kubectl taint {} dedicated=singlepod:NoSchedule
```

---

## **2️⃣ Deploy PostgreSQL with Tolerations + NodeSelector**

A **toleration** tells Kubernetes:

> “This pod is okay with being scheduled on a tainted node.”

A **nodeSelector** tells Kubernetes:

> “I want to run only on nodes with this specific label.”

### **Example Deployment**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:16
          env:
            - name: POSTGRES_USER
              value: myuser
            - name: POSTGRES_PASSWORD
              value: mypassword
            - name: POSTGRES_DB
              value: mydb
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
      volumes:
        - name: postgres-data
          emptyDir: {} # Temporary storage — replace with PersistentVolume for production
      nodeSelector:
        eks.amazonaws.com/nodegroup: my-nodegroup
      tolerations:
        - key: "dedicated"
          operator: "Equal"
          value: "singlepod"
          effect: "NoSchedule"
```

---

## **3️⃣ Verify the Placement**

Check where the pod is running:

```bash
kubectl get pods -o wide
```

✅ The PostgreSQL pod should be on your dedicated node group.
✅ No other pods should run there unless they have the same toleration.

---
