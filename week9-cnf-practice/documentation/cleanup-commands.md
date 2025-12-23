# Week 9 CNF Practice - Cleanup Commands

## Complete Removal of All Resources

These commands will remove all Kubernetes resources created during the Week 9 CNF practice session. Execute them in order for complete cleanup.

### Option 1: Delete Entire Namespace (Fastest)

This removes everything in the telco-core namespace:

#### kubectl Commands:
```bash
# Delete the entire namespace (removes all resources within it)
kubectl delete namespace telco-core

# Verify deletion
kubectl get namespace telco-core
```

Note: This is the fastest and cleanest method. It removes all pods, services, deployments, statefulsets, daemonsets, configmaps, pvcs, and networkpolicies in one command.

### Option 2: Delete Resources Individually (More Control)

If you want to remove resources in a specific order or keep some for inspection:

#### kubectl Commands:
```bash
# Set context to telco-core namespace
kubectl config set-context --current --namespace=telco-core

# Delete NetworkPolicies first
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\network-policies.yaml

# Delete Services
kubectl delete service upf-service
kubectl delete service smf-service
kubectl delete service amf-service
kubectl delete service mongodb-service

# Delete Workloads (Pods will be terminated automatically)
kubectl delete daemonset upf
kubectl delete deployment smf
kubectl delete deployment amf
kubectl delete statefulset mongodb

# Delete ConfigMaps
kubectl delete configmap upf-config
kubectl delete configmap smf-config
kubectl delete configmap amf-config
kubectl delete configmap mongodb-config

# Delete PersistentVolumeClaim (this deletes the persistent data)
kubectl delete pvc mongodb-storage

# Finally, delete the namespace
kubectl delete namespace telco-core

# Reset default namespace to default
kubectl config set-context --current --namespace=default
```

### Option 3: Delete Using Manifest Files

#### kubectl Commands:
```bash
# Delete in reverse order of creation
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\network-policies.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\upf-service.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\upf-daemonset.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\upf-configmap.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\smf-service.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\smf-deployment.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\smf-configmap.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\amf-service.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\amf-deployment.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\amf-configmap.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\mongodb-service.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\mongodb-statefulset.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\mongodb-pvc.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\mongodb-configmap.yaml
kubectl delete -f D:\5g-gitops-repo\week9-cnf-practice\manifests\namespace.yaml

Reset default namespace
kubectl config set-context --current --namespace=default
### Verification Commands

After cleanup, verify all resources have been removed:

#### kubectl Commands:
```bash
# Check if namespace still exists
kubectl get namespace telco-core

# Check for any remaining pods
kubectl get pods -n telco-core

# Check for any remaining services
kubectl get services -n telco-core

# Check for any remaining PVCs
kubectl get pvc -n telco-core

# Check for any remaining PVs that might be orphaned
kubectl get pv
```

### Optional: Stop Minikube

If you want to completely stop the Minikube cluster:

#### PowerShell Commands:
```powershell
# Stop Minikube
minikube stop

# Or delete the entire Minikube cluster
minikube delete

# Verify Minikube is stopped
minikube status
```

### Optional: Clean Docker Resources

If Minikube was using Docker driver and you want to clean up Docker resources:

#### PowerShell Commands:
```powershell
# List Docker containers
docker ps -a

# Remove stopped containers
docker container prune -f

# List Docker images
docker images

# Remove unused images
docker image prune -a -f

# List Docker volumes
docker volume ls

# Remove unused volumes
docker volume prune -f
```

## Important Notes

### Before Deleting:

1. **Backup Data**: If you need to preserve any data from MongoDB:
```bash
   kubectl exec -it mongodb-0 -n telco-core -- mongodump --db open5gs --out /tmp/backup
   kubectl cp telco-core/mongodb-0:/tmp/backup D:\5g-gitops-repo\week9-cnf-practice\backups\final-backup
```

2. **Export Resources**: If you want to save the current state:
```bash
   kubectl get all -n telco-core -o yaml > D:\5g-gitops-repo\week9-cnf-practice\backups\all-resources.yaml
```

3. **Check Dependencies**: Ensure no other namespaces or resources depend on the telco-core resources.

### After Deleting:

1. **Verify Cleanup**: Run verification commands to ensure complete removal
2. **Check Persistent Volumes**: Some PVs might remain in "Released" state
3. **Reset Context**: Ensure kubectl context is reset to default namespace

### Troubleshooting Cleanup Issues:

If resources are stuck in "Terminating" state:
```bash
# Force delete a pod
kubectl delete pod <pod-name> -n telco-core --grace-period=0 --force

# Force delete a namespace
kubectl delete namespace telco-core --grace-period=0 --force

# If namespace is still stuck, remove finalizers
kubectl get namespace telco-core -o json > telco-core.json
# Edit telco-core.json and remove all finalizers
kubectl replace --raw "/api/v1/namespaces/telco-core/finalize" -f telco-core.json
```

## Recommended Cleanup Order

For the cleanest removal with minimal issues:

1. Delete NetworkPolicies (removes security restrictions)
2. Delete DaemonSets and Deployments (stops workloads)
3. Delete Services (removes network endpoints)
4. Delete StatefulSets (stops MongoDB)
5. Delete ConfigMaps (removes configuration)
6. Delete PVCs (removes persistent storage)
7. Delete Namespace (final cleanup)
8. Verify all resources removed
9. Optional: Stop/Delete Minikube
10. Optional: Clean Docker resources

## Preservation Options

If you want to keep the setup for later use but free resources:

### Pause Instead of Delete:
```bash
# Scale down all deployments to 0 replicas
kubectl scale deployment amf --replicas=0 -n telco-core
kubectl scale deployment smf --replicas=0 -n telco-core
kubectl scale statefulset mongodb --replicas=0 -n telco-core

# The DaemonSet will keep running (can't scale to 0)
# To stop it, you would need to delete it

# Later, scale back up:
kubectl scale deployment amf --replicas=2 -n telco-core
kubectl scale deployment smf --replicas=2 -n telco-core
kubectl scale statefulset mongodb --replicas=1 -n telco-core
```

### Export Configuration for Redeployment:
All configuration is already in Git at:
https://github.com/josepbada/5g-gitops-repo/tree/main/week9-cnf-practice

To redeploy, simply run:
```bash
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\
```

This will recreate all resources from the manifest files.