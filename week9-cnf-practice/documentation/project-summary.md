# Week 9 Weekend Project: Cloud-Native 5G Core Architecture
## Complete Project Summary

---

## Project Overview

This weekend project demonstrated the transformation from traditional Virtual Network Functions (VNFs) to Cloud-Native Network Functions (CNFs) in 5G Core networks. We deployed a complete, simplified 5G Core using Open5GS on Kubernetes (Docker Desktop), implementing high availability patterns, resource optimization strategies, and GitOps workflows.

**Duration:** Weekend project (approximately 12-16 hours)  
**Environment:** Docker Desktop with Kubernetes (4 CPU, 5GB RAM)  
**Namespace:** open5gs-core  
**Repository:** https://github.com/josepbada/5g-gitops-repo

---

## Learning Objectives Achieved

### 1. Understanding VNF vs CNF Architecture ✓

**What we learned:**
- VNFs run as monolithic applications in virtual machines with full guest operating systems
- CNFs embrace microservices architecture in lightweight containers
- Resource efficiency: CNFs use 5-6x less resources than equivalent VNF deployments
- Deployment velocity: CNFs deploy in 2-5 minutes vs 30-60 minutes for VNFs
- CNFs enable true cloud-native benefits: horizontal scaling, self-healing, and automated operations

**Deliverable:** Comprehensive VNF vs CNF analysis document with detailed trade-off comparisons

### 2. Implementing Cloud-Native Design Principles ✓

**Principles Applied:**
- **Stateless service design:** Control plane functions (AMF, SMF, NRF) store state externally in MongoDB
- **Externalized configuration:** All configuration managed through ConfigMaps, not baked into images
- **Health probes:** Liveness and readiness probes enable automatic failure detection and recovery
- **Resource management:** Explicit requests and limits prevent resource starvation
- **Immutable infrastructure:** Containers never modified in place, only replaced
- **Service mesh ready:** Architecture compatible with Istio/Linkerd for advanced traffic management

**Deliverable:** Working 5G Core deployment demonstrating all cloud-native principles

### 3. Designing High Availability for Telecommunications ✓

**HA Mechanisms Implemented:**
- **Multiple replicas:** AMF deployed with 2 replicas for redundancy
- **Load balancing:** Kubernetes Services distribute traffic across healthy pods
- **Automatic recovery:** Liveness probes trigger pod restarts within 30-40 seconds
- **Traffic management:** Readiness probes ensure only healthy pods receive traffic
- **Pod anti-affinity:** Rules prevent replicas from running on same node (configured for multi-node)
- **Persistent data:** StatefulSets with PersistentVolumes ensure data survives pod failures

**Target:** 99.999% availability (5.26 minutes downtime per year)  
**Deliverable:** HA strategy document and successful chaos engineering tests

### 4. Optimizing Resource Allocation ✓

**Optimization Strategies:**
- **Right-sizing:** Requests set at normal usage, limits at 1.5-2x for burst capacity
- **Minimal replicas:** 2 replicas only for critical services (AMF), 1 for others in test environment
- **Efficient images:** Single openverso/open5gs image for all network functions
- **Resource limits:** Prevent any single pod from consuming all node resources
- **Storage optimization:** Persistent volumes sized appropriately (MongoDB 2Gi, UPF 1Gi)

**Results:**
- Total allocation: 2.8GB RAM (56%), 1.7 CPU (42.5%), 3Gi storage
- Safety margin: 2.2GB RAM (44%), 2.3 CPU (57.5%) available for system overhead
- Efficient pod packing: 6 pods total fit comfortably in Docker Desktop constraints

**Deliverable:** Resource allocation plan with scaling recommendations for production

### 5. Applying GitOps and Infrastructure as Code ✓

**GitOps Practices:**
- All Kubernetes manifests version-controlled in GitHub
- Declarative configuration using YAML (no imperative kubectl commands in production)
- ConfigMaps enable configuration changes without image rebuilds
- Git history provides complete audit trail of all infrastructure changes
- Rolling updates enable zero-downtime configuration changes

**Repository Structure:**
```
week9-cnf-architecture/
├── documentation/
│   ├── vnf-cnf-analysis.md
│   ├── ha-strategy.md
│   ├── ha-testing-log.md
│   ├── resource-allocation-plan.md
│   └── project-summary.md
├── kubernetes-manifests/
│   ├── configmaps/
│   ├── deployments/
│   ├── statefulsets/
│   ├── services/
│   └── storage/
└── analyze-resources.ps1
```

**Deliverable:** Complete Git repository with all manifests and documentation

---

## Deployed Architecture

### Control Plane Components

| Component | Type | Replicas | Memory | CPU | Purpose |
|-----------|------|----------|--------|-----|---------|
| NRF | Deployment | 1 | 256MB | 0.2 | Service discovery and NF registration |
| AMF | Deployment | 2 | 400MB each | 0.3 each | Access and mobility management |
| SMF | Deployment | 1 | 300MB | 0.2 | Session management and UPF control |

### User Plane Components

| Component | Type | Replicas | Memory | CPU | Purpose |
|-----------|------|----------|--------|-----|---------|
| UPF | StatefulSet | 1 | 400MB | 0.3 | User plane data forwarding |

### Data Layer Components

| Component | Type | Replicas | Memory | CPU | Storage | Purpose |
|-----------|------|----------|--------|-----|---------|---------|
| MongoDB | StatefulSet | 1 | 800MB | 0.4 | 2Gi | Subscriber data, NF profiles, session state |

### Configuration Management

- **ConfigMaps:** nrf-config, amf-config, smf-config, upf-config
- **Purpose:** Externalized configuration for all network functions
- **Benefit:** Configuration changes without image rebuilds

---

## Key Technical Achievements

### 1. StatefulSet vs Deployment Understanding

**Deployments (Used for stateless services):**
- Pods have random names (e.g., amf-7d4f5c8b9-abc12)
- No stable network identity
- Pods are interchangeable
- Suitable for: NRF, AMF, SMF (stateless control plane)

**StatefulSets (Used for stateful services):**
- Pods have predictable names (e.g., upf-0, mongodb-0)
- Stable network identities (upf-0.upf-headless.open5gs-core.svc.cluster.local)
- Ordered deployment and scaling
- Persistent volumes automatically managed
- Suitable for: UPF, MongoDB (stateful services)

### 2. Service Types and Networking

**ClusterIP Services (Standard):**
- amf, smf, nrf: Standard load-balanced ClusterIP
- Traffic distributed across all healthy pod replicas
- DNS name resolves to service VIP

**Headless Services (ClusterIP: None):**
- upf-headless, mongodb: No service VIP
- DNS returns individual pod IPs
- Required for StatefulSet stable network identities
- SMF can connect to specific UPF instance (upf-0)

### 3. Health Probe Configuration

**Liveness Probes:**
- **Purpose:** Detect if container is alive
- **Action on failure:** Restart container
- **Configuration:** TCP check on port 7777 every 10 seconds
- **Threshold:** 3 consecutive failures (30 seconds) triggers restart
- **Recovery time:** 30-50 seconds total

**Readiness Probes:**
- **Purpose:** Determine if pod is ready for traffic
- **Action on failure:** Remove from service endpoints
- **Configuration:** TCP check on port 7777 every 5 seconds
- **Threshold:** 3 consecutive failures removes from service
- **Recovery time:** 5-10 seconds to detect and remove

### 4. Resource Management Strategy

**Requests (Guaranteed minimum):**
- Kubernetes only schedules pod if node has available requests
- Ensures predictable performance
- Used for capacity planning

**Limits (Maximum allowed):**
- Memory limit exceeded → Pod OOMKilled and restarted
- CPU limit exceeded → Process throttled (not killed)
- Prevents resource starvation of other pods

**Our Strategy:**
- Requests = normal expected usage
- Limits = 1.5-2x requests for burst capacity
- Total limits stay under 70% of node capacity for safety

---

## Testing Results

### Test 1: Pod Failure Recovery ✓
- **Method:** Deleted one AMF pod
- **Result:** Second AMF replica continued service, deleted pod recreated in 30-40 seconds
- **Downtime:** 0 seconds (due to multiple replicas)
- **Conclusion:** Multiple replicas provide zero-downtime failover

### Test 2: Service Load Balancing ✓
- **Method:** Connected from test client, verified endpoints
- **Result:** Both AMF pods registered as endpoints, traffic distributed
- **Conclusion:** Kubernetes Service load balancing works correctly

### Test 3: Liveness Probe Simulation ✓
- **Method:** Killed process inside container (pkill open5gs-nrfd)
- **Result:** Liveness probe detected failure after 30 seconds, container restarted
- **Recovery time:** 30-40 seconds
- **Conclusion:** Automatic recovery without manual intervention

### Test 4: Resource Limit Verification ✓
- **Method:** Analyzed configured limits vs Docker Desktop capacity
- **Result:** Total limits at 56% memory, 42.5% CPU (safe utilization)
- **Conclusion:** Resource management prevents node overcommitment

### Test 5: StatefulSet Identity ✓
- **Method:** Deleted upf-0 pod, verified recreation
- **Result:** Pod recreated with same name (upf-0) and same PVC (upf-data-upf-0)
- **Conclusion:** StatefulSet maintains stable identity across restarts

### Test 6: Configuration Update ✓
- **Method:** Changed log level in ConfigMap, performed rolling restart
- **Result:** New configuration applied without service interruption
- **Rollout time:** 30-60 seconds
- **Conclusion:** Zero-downtime configuration updates with GitOps

---

## Performance Metrics

### Resource Utilization
- **Memory:** 2756 MB used / 5000 MB available = 55.1% utilization
- **CPU:** 1.7 cores used / 4.0 cores available = 42.5% utilization
- **Storage:** 3 Gi allocated (MongoDB 2Gi + UPF 1Gi)
- **Pod Count:** 6 pods total (mongodb-0, nrf, amf x2, smf, upf-0)

### Availability Metrics
- **AMF availability:** 100% (due to 2 replicas)
- **Single-replica services:** ~99.9% (30-40 second recovery from failures)
- **Data persistence:** 100% (PersistentVolumes survive pod restarts)

### Deployment Metrics
- **Initial deployment time:** 2-5 minutes for all components
- **Pod startup time:** 10-30 seconds per pod
- **Configuration update time:** 30-60 seconds with rolling restart
- **Failure recovery time:** 30-50 seconds (liveness probe + pod restart)

---

## Production Recommendations

### 1. Scaling for Production

**Small Deployment (1,000-10,000 UEs):**
- Increase all replicas to minimum 2 for HA
- AMF: 2-3 replicas, 1GB each
- SMF: 2-3 replicas, 1GB each
- UPF: 2-3 replicas, 2GB, 2 CPU each
- MongoDB: 3-member replica set, 2GB each
- **Estimated resources:** 15GB RAM, 10 CPU

**Medium Deployment (10,000-100,000 UEs):**
- Scale replicas based on load (5-10 per service)
- Deploy across multiple availability zones
- Use horizontal pod autoscaling (HPA)
- Implement service mesh (Istio) for advanced traffic management
- **Estimated resources:** 60GB RAM, 40 CPU

**Large Deployment (100,000+ UEs):**
- Multi-region deployment for disaster recovery
- Separate clusters per geographic region
- Advanced monitoring (Prometheus + Grafana)
- Dedicated database clusters (separate from control plane)
- **Estimated resources:** 500GB+ RAM, 300+ CPU (distributed)

### 2. Security Enhancements

**For Production Deployment:**
- Enable mutual TLS between all NF communications (via service mesh)
- Implement network policies to restrict pod-to-pod traffic
- Use Secrets for database credentials (not in ConfigMaps)
- Enable RBAC with principle of least privilege
- Scan container images for vulnerabilities
- Implement pod security policies/standards

### 3. Monitoring and Observability

**Required for Production:**
- **Metrics:** Deploy Prometheus for metrics collection
- **Visualization:** Deploy Grafana for dashboards
- **Logging:** Deploy Fluentd/Fluent Bit for log aggregation
- **Tracing:** Implement OpenTelemetry for distributed tracing
- **Alerting:** Configure alerts for resource exhaustion, pod failures, SLA violations

**Key Metrics to Monitor:**
- Pod CPU and memory utilization
- Pod restart counts
- Request latency and error rates
- Active subscriber count
- Active session count
- Database query performance

### 4. Backup and Disaster Recovery

**Backup Strategy:**
- Regular backups of MongoDB data (hourly snapshots)
- ConfigMap and Secret backups in Git
- PersistentVolume snapshots (cloud provider tools)
- Regular disaster recovery drills

**Recovery Time Objectives:**
- RTO (Recovery Time Objective): < 5 minutes for control plane
- RPO (Recovery Point Objective): < 5 minutes for subscriber data
- Database restore: < 15 minutes from snapshot

---

## Lessons Learned

### 1. CNFs vs VNFs Trade-offs

**CNF Advantages:**
- 5-6x better resource efficiency
- 10-15x faster deployment and scaling
- Native high availability through Kubernetes
- Easier operations through automation
- Lower infrastructure costs

**CNF Challenges:**
- Requires Kubernetes expertise
- Stateful services more complex (StatefulSets, persistent volumes)
- Network performance considerations (especially for UPF)
- Initial migration effort from VNF to CNF

### 2. Kubernetes Best Practices for Telecom

**Critical Practices:**
- Always set resource requests and limits
- Use multiple replicas for critical services
- Implement comprehensive health probes
- Externalize all configuration
- Use StatefulSets for services requiring stable identities
- Plan for at least 30-40% resource headroom

**Common Pitfalls to Avoid:**
- Overcommitting node resources (leads to OOM kills)
- Single replica for critical services (no HA)
- Missing health probes (prevents automatic recovery)
- Baking configuration into images (prevents flexibility)
- Ignoring pod anti-affinity (reduces availability)

### 3. Docker Desktop Limitations

**Understanding Constraints:**
- Single-node cluster limits HA testing (pod anti-affinity can't be fully demonstrated)
- Resource constraints require careful allocation
- Metrics-server not included by default (limits monitoring)
- Storage performance lower than production storage classes

**Workarounds:**
- Demonstrate HA concepts even in single-node (multiple replicas work)
- Optimize resource allocation to fit within limits
- Use manual resource analysis scripts
- Document production differences clearly

---

## Files and Deliverables

### Documentation
1. **vnf-cnf-analysis.md:** Comprehensive comparison of VNF and CNF architectures
2. **ha-strategy.md:** High availability strategy and implementation details
3. **ha-testing-log.md:** Detailed test results from chaos engineering experiments
4. **resource-allocation-plan.md:** Resource planning and optimization strategies
5. **project-summary.md:** This complete project summary document

### Kubernetes Manifests
1. **configmaps/:** nrf-config.yaml, amf-config.yaml, smf-config.yaml, upf-config.yaml
2. **deployments/:** nrf-deployment.yaml, amf-deployment.yaml, smf-deployment.yaml
3. **statefulsets/:** mongodb-statefulset.yaml, upf-statefulset.yaml
4. **services/:** Created inline with deployments and statefulsets

### Scripts
1. **analyze-resources.ps1:** PowerShell script for comprehensive resource analysis

### Diagrams
1. VNF vs CNF architecture comparison
2. Cloud-native 5G Core architecture
3. High availability strategy
4. Resource allocation visualization
5. Complete project architecture

---

## Next Steps

### For Continued Learning
1. Deploy Prometheus and Grafana for monitoring
2. Implement Horizontal Pod Autoscaler (HPA)
3. Add Istio service mesh for advanced traffic management
4. Implement network policies for pod-to-pod security
5. Deploy in multi-node cluster (cloud provider or local multi-node setup)
6. Add AUSF, UDM, UDR for complete 5G Core
7. Integrate with actual gNodeB simulator

### For Production Deployment
1. Migrate to multi-node Kubernetes cluster (AWS EKS, Azure AKS, or GKE)
2. Implement MongoDB replica set with 3+ members
3. Deploy minimum 2 replicas of all control plane functions
4. Set up comprehensive monitoring and alerting
5. Implement backup and disaster recovery procedures
6. Perform load testing with realistic traffic patterns
7. Obtain 5G Core conformance testing and certification

---

## Conclusion

This weekend project successfully demonstrated the transformation from traditional VNF architecture to cloud-native CNF architecture for 5G Core networks. We deployed a complete, simplified 5G Core using Open5GS on Kubernetes, implementing industry best practices for high availability, resource optimization, and operational automation.

**Key Takeaways:**
1. CNFs provide dramatic improvements in resource efficiency (5-6x) and deployment velocity (10-15x) compared to VNFs
2. Kubernetes native features (ReplicaSets, Services, health probes) enable telecommunications-grade high availability
3. Proper resource management is critical for stable operations in constrained environments
4. GitOps and Infrastructure as Code practices make 5G Core deployments reproducible and auditable
5. Cloud-native principles (stateless services, externalized config, health probes) are essential for CNF success

**Skills Developed:**
- Deep understanding of VNF vs CNF architectural differences
- Kubernetes Deployment and StatefulSet design patterns
- High availability implementation for telecommunications workloads
- Resource allocation and optimization strategies
- GitOps workflows for infrastructure management
- Chaos engineering and resilience testing

This project provides a solid foundation for deploying production 5G Core networks using cloud-native technologies and establishes patterns that scale from development environments to carrier-grade deployments.

---

**Project Completion Date:** [Current Date]  
**Author:** Josep Bada  
**Repository:** https://github.com/josepbada/5g-gitops-repo  
**Week:** 9 - Cloud-Native 5G Core Architecture