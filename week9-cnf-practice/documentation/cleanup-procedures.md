# Cleanup Procedures - Week 9 Project

## Overview

This document provides step-by-step instructions to remove all resources created during the Week 9 Cloud-Native 5G Core project. The cleanup is organized by resource type to ensure complete removal.

## Important Notes

**Before Cleanup:**
- Ensure you have backed up any data you want to keep from MongoDB
- Save any logs or metrics you want to preserve
- Confirm you want to delete all resources (this action cannot be undone)
- PersistentVolumes will be deleted, removing all stored data

**Cleanup Order:**
The recommended cleanup order prevents dependency issues:
1. Delete Deployments and StatefulSets (stops pods)
2. Delete Services (removes network endpoints)
3. Delete ConfigMaps and Secrets (removes configuration)
4. Delete PersistentVolumeClaims (removes storage)
5. Delete namespace (final cleanup)

---

## Method 1: Quick Cleanup (Delete Entire Namespace)

This is the fastest method and removes everything at once.

### Step 1: Delete the namespace

This single command removes all resources in the namespace including pods, services, configmaps, PVCs, and more.
```powershell
# Delete the entire namespace (removes all resources)
kubectl delete namespace open5gs-core

# This command may take 1-2 minutes to complete
# Kubernetes terminates all pods gracefully before deleting the namespace
```

**Expected Result:** After 1-2 minutes, the namespace and all resources within it are completely removed.

### Step 2: Verify cleanup
```powershell
# Verify namespace is deleted
kubectl get namespace open5gs-core

# Expected output: Error from server (NotFound): namespaces "open5gs-core" not found
```

### Step 3: Reset kubectl context (optional)

If you had set open5gs-core as your default namespace, reset to default:
```powershell
# Reset to default namespace
kubectl config set-context --current --namespace=default
```

**Time Required:** 2-3 minutes total

**Pros:**
- Very fast and simple
- Guaranteed to remove everything
- No risk of missing resources

**Cons:**
- Cannot selectively preserve any resources
- Less educational (doesn't show individual resource cleanup)

---

## Method 2: Selective Cleanup (Step-by-Step)

This method removes resources individually, which is more educational and allows selective preservation of resources if needed.

### Step 1: Delete Deployments

Deployments manage the ReplicaSets and pods for stateless services.
```powershell
# Delete all Deployments
kubectl delete deployment nrf -n open5gs-core
kubectl delete deployment amf -n open5gs-core
kubectl delete deployment smf -n open5gs-core

# Verify Deployments are deleted
kubectl get deployments -n open5gs-core

# Expected output: No resources found in open5gs-core namespace.
```

**What Happens:** Kubernetes immediately starts terminating the pods managed by these deployments. This takes 10-30 seconds per pod as they shut down gracefully.

### Step 2: Delete StatefulSets

StatefulSets manage pods with stable identities (MongoDB and UPF).
```powershell
# Delete all StatefulSets
kubectl delete statefulset mongodb -n open5gs-core
kubectl delete statefulset upf -n open5gs-core

# Verify StatefulSets are deleted
kubectl get statefulsets -n open5gs-core

# Expected output: No resources found in open5gs-core namespace.
```

**What Happens:** StatefulSet pods are terminated in reverse order (upf-0, mongodb-0). The pods are deleted but PersistentVolumeClaims remain.

### Step 3: Verify all pods are terminated
```powershell
# Check that no pods remain
kubectl get pods -n open5gs-core

# Expected output: No resources found in open5gs-core namespace.
```

If any pods are stuck in "Terminating" state for more than 2 minutes:
```powershell
# Force delete stuck pods (only if necessary)
kubectl delete pod <pod-name> -n open5gs-core --force --grace-period=0
```

### Step 4: Delete Services

Services provide network endpoints for pods.
```powershell
# Delete all Services
kubectl delete service mongodb -n open5gs-core
kubectl delete service nrf -n open5gs-core
kubectl delete service amf -n open5gs-core
kubectl delete service smf -n open5gs-core
kubectl delete service upf -n open5gs-core
kubectl delete service upf-headless -n open5gs-core

# Verify Services are deleted
kubectl get services -n open5gs-core

# Expected output: No resources found in open5gs-core namespace.
```

**What Happens:** Service endpoints are immediately removed. Any external references to these services will no longer resolve.

### Step 5: Delete ConfigMaps

ConfigMaps store configuration files for network functions.
```powershell
# Delete all ConfigMaps
kubectl delete configmap nrf-config -n open5gs-core
kubectl delete configmap amf-config -n open5gs-core
kubectl delete configmap smf-config -n open5gs-core
kubectl delete configmap upf-config -n open5gs-core

# Verify ConfigMaps are deleted
kubectl get configmaps -n open5gs-core

# Expected output: No resources found in open5gs-core namespace.
```

**What Happens:** Configuration data is removed. This doesn't affect already-deleted pods but prevents any new pods from accessing the configuration.

### Step 6: Delete PersistentVolumeClaims

PVCs claim storage for StatefulSet pods. Deleting PVCs also deletes the underlying PersistentVolumes and **all data**.
```powershell
# List PVCs to confirm what will be deleted
kubectl get pvc -n open5gs-core

# Delete all PVCs
kubectl delete pvc mongodb-data-mongodb-0 -n open5gs-core
kubectl delete pvc upf-data-upf-0 -n open5gs-core

# Verify PVCs are deleted
kubectl get pvc -n open5gs-core

# Expected output: No resources found in open5gs-core namespace.
```

**IMPORTANT:** This permanently deletes all MongoDB data (subscriber information, network function profiles, session state) and UPF session state. This action cannot be undone.

### Step 7: Verify PersistentVolumes are released
```powershell
# Check that PersistentVolumes are released or deleted
kubectl get pv

# Look for PVs that were bound to our PVCs
# They should show status "Released" or no longer exist
```

If PVs show status "Released" and you want to reclaim the storage:
```powershell
# Delete Released PVs manually (if needed)
kubectl delete pv <pv-name>
```

### Step 8: Delete the namespace

Now that all resources are explicitly deleted, remove the namespace:
```powershell
# Delete the namespace
kubectl delete namespace open5gs-core

# Verify namespace is deleted
kubectl get namespace open5gs-core

# Expected output: Error from server (NotFound): namespaces "open5gs-core" not found
```

### Step 9: Reset kubectl context
```powershell
# Reset to default namespace
kubectl config set-context --current --namespace=default

# Verify current namespace
kubectl config view --minify | Select-String "namespace"
```

**Time Required:** 5-10 minutes total

**Pros:**
- Educational - see how each resource type is removed
- Can preserve specific resources if needed
- Clear visibility into cleanup progress

**Cons:**
- More steps and commands
- Takes longer than Method 1

---

## Method 3: Using Manifest Files (GitOps Cleanup)

If you used `kubectl apply -f` to create resources, you can delete them using the same files.

### Step 1: Delete using manifest files
```powershell
# Navigate to the manifests directory
cd D:\week9-cnf-architecture\kubernetes-manifests

# Delete all resources from manifest files
kubectl delete -f statefulsets\mongodb-statefulset.yaml
kubectl delete -f statefulsets\upf-statefulset.yaml
kubectl delete -f deployments\nrf-deployment.yaml
kubectl delete -f deployments\amf-deployment.yaml
kubectl delete -f deployments\smf-deployment.yaml
kubectl delete -f configmaps\nrf-config.yaml
kubectl delete -f configmaps\amf-config.yaml
kubectl delete -f configmaps\smf-config.yaml
kubectl delete -f configmaps\upf-config.yaml
```

### Step 2: Delete PVCs manually

PVCs created by volumeClaimTemplates in StatefulSets are not deleted by `kubectl delete -f`. You must delete them manually:
```powershell
kubectl delete pvc mongodb-data-mongodb-0 -n open5gs-core
kubectl delete pvc upf-data-upf-0 -n open5gs-core
```

### Step 3: Delete the namespace
```powershell
kubectl delete namespace open5gs-core
```

**Time Required:** 3-5 minutes

**Pros:**
- Mirrors the deployment process
- Good GitOps practice
- Can be scripted

**Cons:**
- Must remember order of manifest files
- Still requires manual PVC deletion

---

## Verification Checklist

After cleanup, verify all resources are removed:
```powershell
# Check namespace (should not exist)
kubectl get namespace open5gs-core

# Check for any remaining resources (if namespace still exists)
kubectl get all -n open5gs-core
kubectl get pvc -n open5gs-core
kubectl get configmap -n open5gs-core

# Check PersistentVolumes (should show none for our project)
kubectl get pv | Select-String "open5gs"

# Verify current namespace is reset
kubectl config view --minify | Select-String "namespace"
```

**Expected Results:**
- Namespace open5gs-core not found (error message is expected and correct)
- No resources in namespace (or namespace doesn't exist)
- No PersistentVolumes related to open5gs
- Current namespace is "default" or not "open5gs-core"

---

## Troubleshooting Cleanup Issues

### Issue 1: Namespace Stuck in "Terminating" State

**Symptom:** `kubectl delete namespace` never completes, namespace shows status "Terminating" for several minutes.

**Cause:** Some resources have finalizers that prevent deletion, or API server cannot verify all resources are deleted.

**Solution:**
```powershell
# Check namespace status
kubectl get namespace open5gs-core -o json | ConvertFrom-Json | Select-Object -ExpandProperty status

# If stuck, force remove finalizers (advanced)
kubectl get namespace open5gs-core -o json | ConvertFrom-Json | ForEach-Object {
    $_.spec.finalizers = @()
    $_ | ConvertTo-Json -Depth 100 | kubectl replace --raw /api/v1/namespaces/open5gs-core/finalize -f -
}
```

### Issue 2: PVCs Won't Delete

**Symptom:** `kubectl delete pvc` hangs or PVC stuck in "Terminating" state.

**Cause:** PVC is still mounted by a pod, or has finalizers.

**Solution:**
```powershell
# Check if any pods are still using the PVC
kubectl get pods -n open5gs-core -o json | ConvertFrom-Json | Select-Object -ExpandProperty items | Where-Object {
    $_.spec.volumes.persistentVolumeClaim -ne $null
}

# If pods exist, delete them first
kubectl delete pods --all -n open5gs-core --force --grace-period=0

# Then retry PVC deletion
kubectl delete pvc <pvc-name> -n open5gs-core

# If still stuck, remove finalizers
kubectl patch pvc <pvc-name> -n open5gs-core -p '{\"metadata\":{\"finalizers\":null}}'
```

### Issue 3: Pods Stuck in "Terminating" State

**Symptom:** Pods show "Terminating" status for more than 2 minutes.

**Cause:** Pod is not responding to termination signal, or node is unhealthy.

**Solution:**
```powershell
# Force delete the pod
kubectl delete pod <pod-name> -n open5gs-core --force --grace-period=0

# This immediately removes the pod from the API server
# Note: Force deletion should be a last resort
```

### Issue 4: "Forbidden" or Permission Errors

**Symptom:** Delete commands return "forbidden" errors.

**Cause:** Insufficient RBAC permissions or Docker Desktop Kubernetes not running properly.

**Solution:**
```powershell
# Verify kubectl context is correct
kubectl config current-context

# Should show: docker-desktop

# Restart Docker Desktop if necessary
# Or check Docker Desktop settings to ensure Kubernetes is enabled
```

---

## Post-Cleanup Tasks

### 1. Clean up local files (optional)

If you want to remove the project files from your computer:
```powershell
# Navigate to parent directory
cd D:\

# Remove the project directory
Remove-Item -Path "week9-cnf-architecture" -Recurse -Force

# Verify removal
Test-Path "D:\week9-cnf-architecture"
# Should return: False
```

**WARNING:** This deletes all your documentation, manifests, and scripts. Make sure everything is committed to GitHub first!

### 2. Verify GitHub repository

Your GitHub repository at https://github.com/josepbada/5g-gitops-repo still contains all project files, providing a permanent record of your work.

### 3. Reset Docker Desktop resources (optional)

If you want to reclaim all Docker resources:
```powershell
# This removes ALL Docker containers, images, volumes, and networks
# Not just from this project but everything in Docker Desktop
docker system prune -a --volumes

# WARNING: This is destructive - only run if you want to clean everything
```

### 4. Document lessons learned

Before forgetting the details, consider documenting:
- What worked well
- What was challenging
- What you would do differently next time
- Key insights gained

---

## Cleanup Summary

After completing cleanup, you will have:
- ✓ Removed all Kubernetes resources (pods, services, deployments, statefulsets)
- ✓ Deleted all configuration (ConfigMaps)
- ✓ Removed all persistent storage (PVCs and PVs)
- ✓ Deleted the namespace (open5gs-core)
- ✓ Reset kubectl context to default namespace
- ✓ Verified no resources remain

Your GitHub repository preserves a complete record of the project for future reference.

---

## Quick Reference

**Fastest cleanup:**
```powershell
kubectl delete namespace open5gs-core
kubectl config set-context --current --namespace=default
```

**Verify cleanup:**
```powershell
kubectl get namespace open5gs-core  # Should error (not found)
kubectl get pv | Select-String "open5gs"  # Should return nothing
```

**If stuck:**
```powershell
# Force delete namespace
kubectl delete namespace open5gs-core --force --grace-period=0

# Force delete PVCs
kubectl delete pvc --all -n open5gs-core --force --grace-period=0
```

---

## Conclusion

This cleanup guide ensures complete removal of all resources created during the Week 9 project. The recommended approach is Method 1 (Quick Cleanup) for its simplicity and reliability, but Method 2 (Selective Cleanup) is valuable for understanding Kubernetes resource lifecycle.

All project work remains preserved in your GitHub repository for future reference and can be redeployed at any time by applying the manifest files.