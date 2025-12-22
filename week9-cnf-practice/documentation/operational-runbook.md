# Week 9 CNF Practice - Operational Runbook

## Quick Reference Commands

### Daily Health Checks
```bash
# Check all pods status
kubectl get pods -n telco-core

# Check all services
kubectl get services -n telco-core

# Check persistent volumes
kubectl get pvc -n telco-core

# Quick health check for all NFs
kubectl exec -it deployment/amf -n telco-core -- curl -s http://amf-service/health
kubectl exec -it deployment/smf -n telco-core -- curl -s http://smf-service/health
```

### Viewing Logs
```bash
# View recent logs from all AMF pods
kubectl logs -n telco-core -l app=amf --tail=50

# View recent logs from all SMF pods
kubectl logs -n telco-core -l app=smf --tail=50

# View recent logs from UPF
kubectl logs -n telco-core -l app=upf --tail=50

# Follow logs in real-time
kubectl logs -n telco-core -l app=amf -f

# View logs from a specific time range (last 1 hour)
kubectl logs -n telco-core -l app=smf --since=1h
```

### Resource Monitoring
```bash
# Check resource usage for all pods
kubectl top pods -n telco-core

# Check node resource usage
kubectl top nodes

# Describe pod to see events and status
kubectl describe pod <pod-name> -n telco-core
```

### Network Connectivity Tests
```bash
# Test AMF to SMF connectivity
kubectl exec -it deployment/amf -n telco-core -- curl -s http://smf-service/health

# Test SMF to MongoDB connectivity
kubectl exec -it deployment/smf -n telco-core -- nc -zv mongodb-service 27017

# Test DNS resolution
kubectl exec -it deployment/amf -n telco-core -- nslookup smf-service
```

### Database Operations
```bash
# Access MongoDB shell
kubectl exec -it mongodb-0 -n telco-core -- mongosh open5gs

# Quick database statistics
kubectl exec -it mongodb-0 -n telco-core -- mongosh open5gs --eval "db.stats()"

# Count documents in each collection
kubectl exec -it mongodb-0 -n telco-core -- mongosh open5gs --eval "printjson({amf_context: db.amf_context.countDocuments(), smf_context: db.smf_context.countDocuments(), sessions: db.sessions.countDocuments(), subscribers: db.subscribers.countDocuments()})"
```

### Scaling Operations
```bash
# Scale AMF replicas
kubectl scale deployment amf -n telco-core --replicas=3

# Scale SMF replicas
kubectl scale deployment smf -n telco-core --replicas=3

# Check deployment scaling status
kubectl rollout status deployment/amf -n telco-core
```

### Update Operations
```bash
# Update AMF image
kubectl set image deployment/amf amf=openverso/open5gs-amf:v2.0 -n telco-core

# Check rollout status
kubectl rollout status deployment/amf -n telco-core

# Rollback if needed
kubectl rollout undo deployment/amf -n telco-core

# View rollout history
kubectl rollout history deployment/amf -n telco-core
```

### Restart Operations
```bash
# Restart all AMF pods (rolling restart)
kubectl rollout restart deployment/amf -n telco-core

# Restart all SMF pods
kubectl rollout restart deployment/smf -n telco-core

# Restart UPF (careful - causes data plane disruption)
kubectl rollout restart daemonset/upf -n telco-core

# Delete specific pod (will be recreated automatically)
kubectl delete pod <pod-name> -n telco-core
```

### Configuration Updates
```bash
# Edit AMF ConfigMap
kubectl edit configmap amf-config -n telco-core

# After editing ConfigMap, restart deployment to pick up changes
kubectl rollout restart deployment/amf -n telco-core

# View current ConfigMap
kubectl get configmap amf-config -n telco-core -o yaml
```

### Port Forwarding for Local Access
```bash
# Forward AMF metrics port to localhost
kubectl port-forward -n telco-core service/amf-service 9090:9090

# Forward SMF metrics port to localhost
kubectl port-forward -n telco-core service/smf-service 9091:9091

# Forward MongoDB port to localhost
kubectl port-forward -n telco-core service/mongodb-service 27017:27017

# Access from browser: http://localhost:9090/metrics
```

### NetworkPolicy Management
```bash
# List all NetworkPolicies
kubectl get networkpolicy -n telco-core

# Describe specific policy
kubectl describe networkpolicy amf-allow-communication -n telco-core

# Temporarily disable NetworkPolicies (for troubleshooting)
kubectl delete networkpolicy --all -n telco-core

# Reapply NetworkPolicies
kubectl apply -f D:\5g-gitops-repo\week9-cnf-practice\manifests\network-policies.yaml
```

### Emergency Procedures

#### Complete System Restart
```bash
# 1. Scale down all deployments
kubectl scale deployment amf -n telco-core --replicas=0
kubectl scale deployment smf -n telco-core --replicas=0

# 2. Wait for pods to terminate
kubectl get pods -n telco-core -w

# 3. Restart MongoDB
kubectl delete pod mongodb-0 -n telco-core

# 4. Wait for MongoDB to be ready
kubectl wait --for=condition=ready pod/mongodb-0 -n telco-core --timeout=300s

# 5. Scale up deployments
kubectl scale deployment amf -n telco-core --replicas=2
kubectl scale deployment smf -n telco-core --replicas=2

# 6. Restart UPF
kubectl rollout restart daemonset/upf -n telco-core
```

#### Database Backup
```bash
# Create MongoDB backup
kubectl exec -it mongodb-0 -n telco-core -- mongodump --db open5gs --out /tmp/backup

# Copy backup from pod to local system
kubectl cp telco-core/mongodb-0:/tmp/backup D:\5g-gitops-repo\week9-cnf-practice\backups\mongodb-backup-$(date +%Y%m%d)
```

#### Database Restore
```bash
# Copy backup to pod
kubectl cp D:\5g-gitops-repo\week9-cnf-practice\backups\mongodb-backup-20251217 telco-core/mongodb-0:/tmp/restore

# Restore database
kubectl exec -it mongodb-0 -n telco-core -- mongorestore --db open5gs /tmp/restore/open5gs
```

### Troubleshooting Commands
```bash
# Check pod events
kubectl get events -n telco-core --sort-by='.lastTimestamp'

# Get pod YAML for analysis
kubectl get pod <pod-name> -n telco-core -o yaml

# Execute shell in pod for debugging
kubectl exec -it <pod-name> -n telco-core -- /bin/bash

# Check service endpoints
kubectl get endpoints -n telco-core

# Verify DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -n telco-core -- nslookup amf-service
```

### Performance Analysis
```bash
# Get detailed resource metrics
kubectl top pods -n telco-core --containers

# Check pod resource requests and limits
kubectl describe pod <pod-name> -n telco-core | grep -A 10 "Requests\|Limits"

# View UPF network interfaces
kubectl exec -it daemonset/upf -n telco-core -- ip addr show

# Check UPF routing table
kubectl exec -it daemonset/upf -n telco-core -- ip route show
```

## Common Issues and Solutions

### Issue: Pod CrashLoopBackOff

**Quick Check:**
```bash
kubectl logs <pod-name> -n telco-core --previous
kubectl describe pod <pod-name> -n telco-core
```

**Common Solutions:**
- Check resource limits - pod may be OOM killed
- Verify ConfigMap is correctly mounted
- Check database connectivity

### Issue: Service Unreachable

**Quick Check:**
```bash
kubectl get endpoints <service-name> -n telco-core
kubectl describe service <service-name> -n telco-core
```

**Common Solutions:**
- Verify pods are running and ready
- Check NetworkPolicy allows traffic
- Verify service selector matches pod labels

### Issue: High Memory Usage

**Quick Check:**
```bash
kubectl top pods -n telco-core
```

**Common Solutions:**
- Scale up replicas to distribute load
- Increase memory limits if pods are OOM killed
- Check for memory leaks in logs

## Maintenance Windows

### Weekly Maintenance Tasks

1. Review pod and node resource usage
2. Check log files for errors or warnings
3. Verify all health checks are passing
4. Review MongoDB collection sizes
5. Test backup and restore procedures

### Monthly Maintenance Tasks

1. Update container images to latest stable versions
2. Review and update resource allocations
3. Test failover scenarios
4. Audit NetworkPolicies
5. Review and archive old logs
6. Capacity planning review

## Contact Information

**Primary On-Call**: [Your Name/Team]
**Escalation**: [Team Lead/Manager]
**Documentation Repository**: https://github.com/josepbada/5g-gitops-repo

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-12-17 | Initial deployment | Week 9 Practice |