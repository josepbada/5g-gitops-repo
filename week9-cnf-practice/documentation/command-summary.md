# Week 9 CNF Practice - Complete Command Summary

## Commands Used During Session (December 17, 2025)

### Section 1: Environment Preparation and Repository Setup

#### PowerShell Commands:
```powershell
# Navigate to working directory
cd D:\

# Verify Docker Desktop
docker info

# Check Minikube version
minikube version

# Check Minikube status
minikube status

# Start Minikube with Calico CNI
minikube start --driver=docker --cpus=4 --memory=4096 --cni=calico

# Clone GitHub repository
git clone https://github.com/josepbada/5g-gitops-repo
cd 5g-gitops-repo

# Or update existing repository
cd D:\5g-gitops-repo
git pull origin main

# Create directory structure
mkdir week9-cnf-practice
cd week9-cnf-practice
mkdir manifests
mkdir diagrams
mkdir documentation
```

#### kubectl Commands:
```bash
# Verify Calico installation
kubectl get pods -n kube-system | Select-String "calico"

# Create namespace
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\namespace.yaml

# Verify namespace creation
kubectl get namespace telco-core
kubectl describe namespace telco-core

# Set default namespace
kubectl config set-context --current --namespace=telco-core

# Verify context change
kubectl config view --minify | Select-String "namespace"

# Check current namespace
kubectl get pods
```

### Section 2: Deploying MongoDB for Session State Management

#### kubectl Commands:
```bash
# Apply MongoDB ConfigMap
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\mongodb-configmap.yaml

# Verify ConfigMap
kubectl get configmap mongodb-config -o yaml

# Apply PersistentVolumeClaim
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\mongodb-pvc.yaml

# Check PVC status
kubectl get pvc mongodb-storage
kubectl describe pvc mongodb-storage

# Deploy MongoDB StatefulSet
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\mongodb-statefulset.yaml

# Watch pod creation
kubectl get pods -l app=mongodb -w

# View MongoDB logs
kubectl logs mongodb-0

# Connect to MongoDB
kubectl exec -it mongodb-0 -- mongosh open5gs

# Apply MongoDB Service
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\mongodb-service.yaml

# Verify service
kubectl get service mongodb-service

# Test MongoDB connectivity
kubectl run mongodb-test --image=mongo:6.0 --rm -it --restart=Never -- mongosh mongodb-service/open5gs --eval "db.subscribers.count()"
```

#### MongoDB Shell Commands (inside MongoDB pod):
```javascript
show collections
db.subscribers.getIndexes()
exit
```

### Section 3: Deploying the AMF (Access and Mobility Management Function)

#### kubectl Commands:
```bash
# Apply AMF ConfigMap
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\amf-configmap.yaml

# Verify ConfigMap
kubectl describe configmap amf-config

# Deploy AMF
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\amf-deployment.yaml

# Watch AMF pods
kubectl get pods -l app=amf -w

# View AMF logs
kubectl logs -l app=amf --tail=50

# Apply AMF Service
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\amf-service.yaml

# Verify service
kubectl get service amf-service
kubectl describe service amf-service

# Test AMF health
kubectl run amf-test --image=curlimages/curl:latest --rm -it --restart=Never -- curl -s http://amf-service/health

# Test high availability (delete a pod)
kubectl delete pod <amf-pod-name>
kubectl get pods -l app=amf -w

# Test metrics endpoint
kubectl run metrics-test --image=curlimages/curl:latest --rm -it --restart=Never -- curl -s http://amf-service:9090/metrics
```

### Section 4: Deploying the SMF (Session Management Function)

#### kubectl Commands:
```bash
# Apply SMF ConfigMap
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\smf-configmap.yaml

# Verify ConfigMap
kubectl get configmap smf-config -o yaml

# Deploy SMF
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\smf-deployment.yaml

# Watch SMF pods
kubectl get pods -l app=smf -w

# View SMF logs
kubectl logs -l app=smf --tail=50

# Apply SMF Service
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\smf-service.yaml

# Verify service
kubectl get service smf-service
kubectl describe service smf-service

# Test SMF health
kubectl run smf-test --image=curlimages/curl:latest --rm -it --restart=Never -- curl -s http://smf-service/health

# Verify MongoDB collections
kubectl exec -it mongodb-0 -- mongosh open5gs --eval "db.getCollectionNames()"

# Test SMF metrics
kubectl run smf-metrics-test --image=curlimages/curl:latest --rm -it --restart=Never -- curl -s http://smf-service:9091/metrics | Select-String "smf_session"

# Verify AMF-SMF integration
kubectl logs -l app=amf --tail=100 | Select-String "smf"
kubectl exec -it mongodb-0 -- mongosh open5gs --eval "db.getCollectionNames().forEach(function(col) { print(col + ': ' + db[col].countDocuments()); })"
kubectl exec -it deployment/amf -- curl -s http://smf-service/health
kubectl exec -it deployment/smf -- curl -s http://amf-service/health
```

### Section 5: Deploying the UPF (User Plane Function)

#### kubectl Commands:
```bash
# Apply UPF ConfigMap
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\upf-configmap.yaml

# Verify ConfigMap
kubectl describe configmap upf-config

# Deploy UPF DaemonSet
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\upf-daemonset.yaml

# Watch UPF pod
kubectl get pods -l app=upf -w

# View UPF logs
kubectl logs -l app=upf --tail=100

# Verify tunnel interfaces
kubectl exec -it daemonset/upf -- ip link show
kubectl exec -it daemonset/upf -- ip route show

# Apply UPF Service
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\upf-service.yaml

# Verify service
kubectl get service upf-service
kubectl describe service upf-service

# Verify PFCP association
kubectl logs -l app=smf --tail=100 | Select-String "pfcp\|upf\|association"
kubectl logs -l app=upf --tail=100 | Select-String "pfcp\|smf\|association"

# Test connectivity
kubectl exec -it deployment/smf -- sh -c "nc -zvu upf-service 8805 2>&1 || echo 'Testing UDP connectivity to UPF PFCP port'"

# Complete integration tests
kubectl exec -it deployment/amf -- curl -s -o /dev/null -w "AMF to SMF: HTTP %{http_code}\n" http://smf-service/health
kubectl exec -it deployment/amf -- curl -s -o /dev/null -w "AMF to UPF: HTTP %{http_code}\n" http://upf-service:9092/metrics
kubectl exec -it deployment/smf -- curl -s -o /dev/null -w "SMF to UPF: HTTP %{http_code}\n" http://upf-service:9092/metrics

# Check overall status
kubectl get pods -o wide
kubectl get services

# Apply NetworkPolicies
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\network-policies.yaml

# Verify NetworkPolicies
kubectl get networkpolicy
kubectl describe networkpolicy smf-allow-communication

# Test with NetworkPolicies
kubectl exec -it deployment/amf -- curl -s -o /dev/null -w "AMF to SMF with NetworkPolicy: HTTP %{http_code}\n" http://smf-service/health
kubectl exec -it deployment/smf -- sh -c "nc -zvu upf-service 8805 2>&1; echo 'SMF to UPF PFCP with NetworkPolicy'"
```

### Section 6: Documentation, Git Commit, and Architecture Visualization

#### PowerShell Commands:
```powershell
# Navigate to week9 directory
cd D:\5g-gitops-repo\week9-cnf-practice

# Check Git status
git status

# Stage all files
git add manifests\
git add documentation\
git add diagrams\

# Verify staging
git status

# Commit with detailed message
git commit -m "Week 9: Complete cloud-native 5G Core CNF deployment..."

# Push to GitHub
git push origin main

# Verify push
git log --oneline -5
```

## Useful Monitoring and Troubleshooting Commands

### View Logs
```bash
# View logs from all AMF pods
kubectl logs -l app=amf --tail=100

# View logs from all SMF pods
kubectl logs -l app=smf --tail=100

# View logs from UPF
kubectl logs -l app=upf --tail=100

# Follow logs in real-time
kubectl logs -l app=amf -f

# View logs from previous container instance
kubectl logs <pod-name> --previous
```

### Resource Monitoring
```bash
# Check pod resource usage
kubectl top pods

# Check node resource usage
kubectl top nodes

# Describe pod for detailed information
kubectl describe pod <pod-name>

# Get pod events
kubectl get events --sort-by='.lastTimestamp'
```

### Database Operations
```bash
# Access MongoDB shell
kubectl exec -it mongodb-0 -- mongosh open5gs

# Quick collection count
kubectl exec -it mongodb-0 -- mongosh open5gs --eval "printjson({amf_context: db.amf_context.countDocuments(), smf_context: db.smf_context.countDocuments(), sessions: db.sessions.countDocuments(), subscribers: db.subscribers.countDocuments()})"

# List all collections
kubectl exec -it mongodb-0 -- mongosh open5gs --eval "db.getCollectionNames()"
```

### Scaling Operations
```bash
# Scale AMF
kubectl scale deployment amf --replicas=3

# Scale SMF
kubectl scale deployment smf --replicas=3

# Check scaling status
kubectl rollout status deployment/amf
```

### Port Forwarding
```bash
# Forward AMF metrics
kubectl port-forward service/amf-service 9090:9090

# Forward SMF metrics
kubectl port-forward service/smf-service 9091:9091

# Forward MongoDB
kubectl port-forward service/mongodb-service 27017:27017
```

### Network Testing
```bash
# Test AMF to SMF connectivity
kubectl exec -it deployment/amf -- curl -s http://smf-service/health

# Test SMF to MongoDB
kubectl exec -it deployment/smf -- nc -zv mongodb-service 27017

# Test DNS resolution
kubectl exec -it deployment/amf -- nslookup smf-service
```

## Summary Statistics

Total Resources Created:
- Namespaces: 1
- ConfigMaps: 4 (MongoDB, AMF, SMF, UPF)
- PersistentVolumeClaims: 1
- StatefulSets: 1 (MongoDB)
- Deployments: 2 (AMF, SMF)
- DaemonSets: 1 (UPF)
- Services: 4 (MongoDB, AMF, SMF, UPF)
- NetworkPolicies: 6

Total Pods Created:
- MongoDB: 1
- AMF: 2
- SMF: 2
- UPF: 1 (one per node)
- Total: 6 pods