# Week 9 CNF Practice - 5G Core Cloud-Native Deployment Guide

## Overview

This deployment guide documents the complete cloud-native 5G Core network implementation deployed as part of Week 9 CNF (Cloud-Native Network Functions) practice exercises. The deployment includes the core network functions required for a functional 5G standalone core network.

## Deployment Date
December 17, 2025

## Architecture Components

### Control Plane Functions
1. **AMF (Access and Mobility Management Function)**
   - Deployment Type: Stateless Kubernetes Deployment
   - Replicas: 2 (High Availability)
   - Resource Allocation: 256Mi-512Mi memory, 200m-500m CPU
   - Responsibilities: Registration management, mobility management, access authentication
   - Database: MongoDB (external state storage)

2. **SMF (Session Management Function)**
   - Deployment Type: Stateless Kubernetes Deployment
   - Replicas: 2 (High Availability)
   - Resource Allocation: 384Mi-768Mi memory, 250m-750m CPU
   - Responsibilities: PDU session management, IP address allocation, UPF selection, policy enforcement
   - Database: MongoDB (external state storage)

### User Plane Functions
3. **UPF (User Plane Function)**
   - Deployment Type: DaemonSet with privileged security context
   - Replicas: 1 per node
   - Resource Allocation: 512Mi-2Gi memory, 500m-2000m CPU
   - Responsibilities: Packet forwarding, GTP-U tunneling, QoS enforcement, traffic metering
   - Special Requirements: Requires NET_ADMIN, SYS_ADMIN, NET_RAW capabilities

### Data Layer
4. **MongoDB**
   - Deployment Type: StatefulSet
   - Replicas: 1 (Development environment)
   - Resource Allocation: 512Mi-1Gi memory, 250m-500m CPU
   - Storage: 2Gi PersistentVolume
   - Purpose: Persistent storage for AMF and SMF session state

## Network Configuration

### Namespace
- Name: `telco-core`
- Purpose: Logical isolation for 5G Core network functions
- Labels: environment=development, purpose=5g-core-network, week=week9

### Service Configuration

#### AMF Service
- Service Name: `amf-service`
- Type: ClusterIP
- Ports:
  - SBI: 80/TCP (Service-Based Interface)
  - NGAP: 38412/SCTP (NG Application Protocol)
  - Metrics: 9090/TCP (Prometheus metrics)
- Session Affinity: ClientIP (3600 seconds)

#### SMF Service
- Service Name: `smf-service`
- Type: ClusterIP
- Ports:
  - SBI: 80/TCP (Service-Based Interface)
  - PFCP: 8805/UDP (Packet Forwarding Control Protocol)
  - GTP-C: 2123/UDP (GPRS Tunneling Protocol Control)
  - GTP-U: 2152/UDP (GPRS Tunneling Protocol User Plane)
  - Metrics: 9091/TCP (Prometheus metrics)
- Session Affinity: ClientIP (7200 seconds)

#### UPF Service
- Service Name: `upf-service`
- Type: ClusterIP (Headless)
- Ports:
  - PFCP: 8805/UDP
  - GTP-U: 2152/UDP
  - Metrics: 9092/TCP

#### MongoDB Service
- Service Name: `mongodb-service`
- Type: ClusterIP (Headless)
- Port: 27017/TCP

### IP Address Pools

The SMF manages two separate IP address pools for different Data Network Names (DNNs):

1. **Internet DNN**
   - CIDR: 10.45.0.0/16
   - Gateway: 10.45.0.1
   - DNS: 8.8.8.8, 8.8.4.4
   - Capacity: 65,534 addresses
   - Use Case: General mobile broadband internet access

2. **IMS DNN**
   - CIDR: 10.46.0.0/16
   - Gateway: 10.46.0.1
   - DNS: 8.8.8.8
   - Capacity: 65,534 addresses
   - Use Case: IP Multimedia Subsystem (voice and video services)

### Network Slices

The deployment supports two network slices as defined in the AMF and SMF configurations:

1. **Slice 1 (SST=1, SD=000001)**
   - Type: Enhanced Mobile Broadband (eMBB)
   - DNN: internet
   - IP Version: IPv4
   - Use Case: Consumer mobile broadband

2. **Slice 2 (SST=1, SD=000002)**
   - Type: Enhanced Mobile Broadband (eMBB)
   - DNN: ims
   - IP Version: IPv4v6 (dual stack)
   - Use Case: IMS voice and multimedia services

## Security Configuration

### NetworkPolicies

The deployment implements comprehensive NetworkPolicies using Calico CNI:

1. **Default Deny Policy**: Blocks all traffic by default
2. **MongoDB Access Policy**: Allows only control plane functions to access MongoDB
3. **AMF Communication Policy**: Allows AMF to communicate with SMF and MongoDB
4. **SMF Communication Policy**: Allows SMF to communicate with AMF, UPF, and MongoDB
5. **UPF Communication Policy**: Allows UPF to communicate with SMF and forward user plane traffic
6. **Metrics Scraping Policy**: Allows Prometheus to scrape metrics from all functions

### PLMN Configuration

All network functions are configured with test PLMN (Public Land Mobile Network) identifiers:
- MCC (Mobile Country Code): 001
- MNC (Mobile Network Code): 01
- These are test values defined by 3GPP for non-operational networks

### Security Algorithms

The AMF negotiates security algorithms with user equipment in the following priority order:

**Integrity Protection (NIA):**
1. NIA2 (128-bit SNOW 3G) - Preferred
2. NIA1 (128-bit KASUMI)
3. NIA0 (Null integrity) - Fallback only

**Encryption (NEA):**
1. NEA2 (128-bit SNOW 3G) - Preferred
2. NEA1 (128-bit KASUMI)
3. NEA0 (Null encryption) - Fallback only

## High Availability Strategy

### Control Plane HA (AMF and SMF)
- Strategy: Active-Active with stateless design
- Implementation: Multiple replicas (2) with shared MongoDB backend
- Benefits:
  - Load distribution across multiple instances
  - Automatic failover if one instance fails
  - Zero-downtime rolling updates
  - Horizontal scalability by adjusting replica count

### User Plane HA (UPF)
- Strategy: Distributed Active
- Implementation: DaemonSet ensures one UPF per node
- Benefits:
  - Geographic distribution of user plane capacity
  - Localized packet processing reduces latency
  - Node failure only affects traffic on that node

### Data Layer HA (MongoDB)
- Current: Single instance (development environment)
- Production Recommendation: MongoDB replica set with 3+ members
- Benefits (production):
  - Automatic failover to secondary members
  - Data redundancy across multiple nodes
  - Read scaling through secondary reads

## Operational Procedures

### Checking System Status

To verify all components are healthy:
```bash
kubectl get pods -n telco-core
kubectl get services -n telco-core
kubectl get networkpolicies -n telco-core
```

Expected output: All pods should show STATUS "Running" and READY "1/1"

### Viewing Logs

To examine logs from specific network functions:
```bash
# AMF logs
kubectl logs -n telco-core -l app=amf --tail=100

# SMF logs
kubectl logs -n telco-core -l app=smf --tail=100

# UPF logs
kubectl logs -n telco-core -l app=upf --tail=100

# MongoDB logs
kubectl logs -n telco-core mongodb-0 --tail=100
```

### Accessing Metrics

All network functions expose Prometheus-compatible metrics:
```bash
# AMF metrics
kubectl port-forward -n telco-core service/amf-service 9090:9090
# Access http://localhost:9090/metrics

# SMF metrics
kubectl port-forward -n telco-core service/smf-service 9091:9091
# Access http://localhost:9091/metrics

# UPF metrics
kubectl port-forward -n telco-core service/upf-service 9092:9092
# Access http://localhost:9092/metrics
```

### Database Access

To access MongoDB for inspection or troubleshooting:
```bash
kubectl exec -it -n telco-core mongodb-0 -- mongosh open5gs
```

Useful MongoDB queries:
- `db.getCollectionNames()` - List all collections
- `db.amf_context.find().pretty()` - View AMF registration contexts
- `db.smf_context.find().pretty()` - View SMF session contexts
- `db.sessions.find().pretty()` - View active PDU sessions
- `db.subscribers.find().pretty()` - View subscriber profiles

### Scaling Operations

To scale control plane functions:
```bash
# Scale AMF to 3 replicas
kubectl scale deployment amf -n telco-core --replicas=3

# Scale SMF to 3 replicas
kubectl scale deployment smf -n telco-core --replicas=3
```

Note: UPF scaling is automatic through DaemonSet - one pod per node

## Troubleshooting Guide

### Issue: Pods Not Starting

**Symptoms**: Pods stuck in "Pending" or "ContainerCreating" state

**Diagnosis**:
```bash
kubectl describe pod <pod-name> -n telco-core
```

**Common Causes**:
1. Insufficient resources - Check node capacity
2. Image pull failures - Verify image name and network connectivity
3. Volume mounting issues - Check PVC status

### Issue: Network Function Cannot Connect to MongoDB

**Symptoms**: Logs show database connection errors

**Diagnosis**:
```bash
# Check MongoDB pod status
kubectl get pod mongodb-0 -n telco-core

# Test connectivity from affected pod
kubectl exec -it <pod-name> -n telco-core -- nc -zv mongodb-service 27017
```

**Solutions**:
1. Verify MongoDB service is running
2. Check NetworkPolicy allows connection
3. Verify database URI in ConfigMap

### Issue: AMF and SMF Cannot Communicate

**Symptoms**: Session establishment failures in logs

**Diagnosis**:
```bash
# Test AMF to SMF connectivity
kubectl exec -it deployment/amf -n telco-core -- curl http://smf-service/health

# Check NetworkPolicies
kubectl get networkpolicy -n telco-core
```

**Solutions**:
1. Verify services are exposed correctly
2. Check NetworkPolicy rules allow AMF-SMF communication
3. Examine logs for specific error messages

### Issue: UPF Cannot Create Tunnel Interfaces

**Symptoms**: UPF pod fails readiness probe, logs show interface creation errors

**Diagnosis**:
```bash
# Check UPF security context
kubectl get pod <upf-pod> -n telco-core -o jsonpath='{.spec.containers[0].securityContext}'

# Check UPF logs
kubectl logs <upf-pod> -n telco-core
```

**Solutions**:
1. Verify UPF has privileged: true security context
2. Ensure required capabilities (NET_ADMIN, SYS_ADMIN, NET_RAW) are granted
3. Check if Minikube was started with appropriate settings

### Issue: PFCP Association Failure Between SMF and UPF

**Symptoms**: SMF logs show PFCP timeout errors

**Diagnosis**:
```bash
# Check SMF logs for PFCP messages
kubectl logs -l app=smf -n telco-core | grep -i pfcp

# Check UPF logs for PFCP messages
kubectl logs -l app=upf -n telco-core | grep -i pfcp

# Test UDP connectivity
kubectl exec -it deployment/smf -n telco-core -- nc -zvu upf-service 8805
```

**Solutions**:
1. Verify UPF service is reachable from SMF
2. Check NetworkPolicy allows UDP 8805 traffic
3. Verify PFCP configuration in both SMF and UPF ConfigMaps

## Performance Considerations

### Resource Limits

The current resource allocations are suitable for development and testing with light load. For production deployments, consider the following guidelines:

**AMF (per 10,000 users)**:
- Memory: 2-4 GB
- CPU: 1-2 cores
- Storage (in MongoDB): ~100 MB

**SMF (per 10,000 sessions)**:
- Memory: 4-8 GB
- CPU: 2-4 cores
- Storage (in MongoDB): ~500 MB

**UPF (per 10 Gbps throughput)**:
- Memory: 8-16 GB
- CPU: 4-8 cores (dedicated, with DPDK)
- Consider hardware acceleration for higher throughput

**MongoDB (for 100,000 users)**:
- Memory: 16-32 GB
- CPU: 4-8 cores
- Storage: 500 GB - 1 TB

### Network Performance

The UPF in this deployment uses standard Linux networking. For production deployments requiring high throughput (>10 Gbps), consider:

1. **DPDK (Data Plane Development Kit)**: Bypass kernel networking for higher packet rates
2. **SR-IOV (Single Root I/O Virtualization)**: Direct device access for lower latency
3. **Hardware Offload**: Use SmartNICs for packet processing acceleration
4. **CPU Pinning**: Dedicate specific CPU cores to UPF packet processing

## Compliance and Standards

This deployment follows these telecommunications standards and best practices:

- **3GPP Release 16**: 5G Core network architecture and protocols
- **ETSI NFV**: Network Functions Virtualization principles
- **Cloud Native Computing Foundation**: Kubernetes best practices
- **12-Factor App**: Stateless application design principles

## Known Limitations

This is a development and learning environment with the following limitations:

1. **Single Node Deployment**: Minikube provides only one node, limiting true HA testing
2. **No External gNodeB**: No actual radio access network connectivity
3. **No Subscriber Management**: No HSS/UDM for subscriber authentication
4. **No Policy Control**: No PCF for dynamic policy enforcement
5. **Limited Observability**: No complete monitoring stack (Prometheus, Grafana)
6. **Test PLMN**: Uses non-operational PLMN identifiers
7. **Standard Networking**: UPF uses standard Linux networking without DPDK

## Next Steps for Production

To evolve this deployment toward production readiness:

1. **Multi-Node Cluster**: Deploy on a cluster with 3+ nodes for true HA
2. **MongoDB Replica Set**: Configure MongoDB with 3+ replicas for data redundancy
3. **Complete 5G Core**: Add NRF, AUSF, UDM, PCF, NSSF, UDR
4. **Monitoring Stack**: Deploy Prometheus, Grafana, and alerting
5. **Service Mesh**: Consider Istio or Linkerd for advanced traffic management
6. **Security Hardening**: Implement mTLS, RBAC, pod security policies
7. **CI/CD Pipeline**: Automate testing and deployment
8. **Performance Optimization**: Implement DPDK, SR-IOV, CPU pinning for UPF
9. **Backup and DR**: Implement backup procedures and disaster recovery plans
10. **Capacity Planning**: Size resources based on expected traffic and growth

## References

- 3GPP TS 23.501: System architecture for 5G
- 3GPP TS 23.502: Procedures for 5G System
- 3GPP TS 29.244: PFCP protocol specification
- Open5GS Documentation: https://open5gs.org/
- Kubernetes Documentation: https://kubernetes.io/docs/
- Calico NetworkPolicy Documentation: https://docs.projectcalico.org/