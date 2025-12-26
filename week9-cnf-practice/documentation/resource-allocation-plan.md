# Resource Allocation Plan for Cloud-Native 5G Core

## Document Purpose

This document provides detailed resource allocation planning for deploying Open5GS 5G Core network functions as cloud-native containerized workloads. The plan is optimized for Docker Desktop environments (4 CPU, 5GB RAM) but includes scaling recommendations for production deployments.

## Current Deployment Summary

### Environment Specifications
- **Platform:** Docker Desktop on Windows
- **Kubernetes Version:** v1.29+ (bundled with Docker Desktop)
- **Total CPU:** 4 cores
- **Total Memory:** 5000 MB
- **Storage:** Docker Desktop hostpath provisioner (dynamic)
- **Network:** CNI with ClusterIP services

### Deployed Components

| Component | Type | Replicas | Memory Request | Memory Limit | CPU Request | CPU Limit |
|-----------|------|----------|----------------|--------------|-------------|-----------|
| MongoDB   | StatefulSet | 1 | 600 MB | 800 MB | 0.3 | 0.4 |
| NRF       | Deployment | 1 | 128 MB | 256 MB | 0.1 | 0.2 |
| AMF       | Deployment | 2 | 256 MB | 400 MB | 0.2 | 0.3 |
| SMF       | Deployment | 1 | 200 MB | 300 MB | 0.15 | 0.2 |
| UPF       | StatefulSet | 1 | 256 MB | 400 MB | 0.2 | 0.3 |

### Total Resource Allocation

**Memory:**
- Total Requests: 1928 MB (38.6% of available)
- Total Limits: 2756 MB (55.1% of available)
- Available Headroom: 2244 MB (44.9%)

**CPU:**
- Total Requests: 1.35 cores (33.75% of available)
- Total Limits: 1.7 cores (42.5% of available)
- Available Headroom: 2.3 cores (57.5%)

**Storage:**
- MongoDB PVC: 2 Gi (subscriber data, NF profiles)
- UPF PVC: 1 Gi (session state, buffering)
- Total: 3 Gi

## Resource Allocation Principles

### 1. Requests vs Limits Strategy

**Requests** represent the guaranteed minimum resources. Kubernetes will only schedule a pod on a node if the node has at least this much resource available. Requests ensure predictable performance.

**Limits** represent the maximum resources a container can consume. When a container attempts to exceed its memory limit, it's terminated (OOMKilled). When it attempts to exceed its CPU limit, it's throttled.

**Our Strategy:**
- Set requests at expected normal load (50-70% of typical usage)
- Set limits at 1.5-2x requests to allow burst capacity
- Maintain at least 30-40% cluster headroom for system overhead

**Example - AMF Configuration:**
```yaml
resources:
  requests:
    memory: "256Mi"  # Normal operation requires ~200MB
    cpu: "200m"      # Normal operation uses ~150m CPU
  limits:
    memory: "400Mi"  # Peak burst up to 400MB
    cpu: "300m"      # Peak burst up to 300m CPU
```

This configuration means:
- Kubernetes guarantees 256MB RAM and 0.2 CPU to each AMF pod
- The pod can burst up to 400MB and 0.3 CPU during high load
- The 56% headroom (256MB → 400MB) handles traffic spikes

### 2. Component-Specific Considerations

#### MongoDB (Data Layer)
**Resource Profile:** Memory-intensive, moderate CPU

MongoDB stores all subscriber data, network function profiles, and session state. It requires sufficient memory for database caching to maintain performance.

**Allocation Rationale:**
- 800MB limit provides adequate cache for 1000-5000 subscribers
- 0.4 CPU sufficient for moderate query load
- 2Gi persistent storage for database files

**Production Recommendations:**
- Scale memory to 2-4GB for production subscriber counts (100K+)
- Deploy as replica set (3 members minimum) for high availability
- Use dedicated storage class with high IOPS

#### NRF (Service Discovery)
**Resource Profile:** Lightweight, low CPU and memory

NRF maintains a registry of network function instances and handles service discovery queries. It's a lightweight component with predictable resource needs.

**Allocation Rationale:**
- 256MB limit handles registry for 50-100 NF instances
- 0.2 CPU sufficient for discovery query load
- Minimal state (stored in MongoDB)

**Production Recommendations:**
- 2+ replicas for high availability
- Consider increasing to 512MB for large deployments (1000+ NF instances)

#### AMF (Access Management)
**Resource Profile:** Moderate memory, moderate CPU, stateless

AMF handles UE registration and mobility management. It's a control plane function with moderate resource needs. We deploy 2 replicas to demonstrate high availability.

**Allocation Rationale:**
- 400MB limit per pod handles 500-1000 concurrent UE registrations
- 0.3 CPU per pod sufficient for signaling load
- 2 replicas provide redundancy and load distribution
- Stateless design (state in MongoDB) enables horizontal scaling

**Production Recommendations:**
- Scale replicas based on connected UE count (1 replica per 5000 UEs)
- Increase memory to 1GB per replica for 10K+ UEs
- Use pod anti-affinity across availability zones

#### SMF (Session Management)
**Resource Profile:** Moderate memory, moderate CPU, stateless

SMF manages PDU sessions and controls UPF for user plane setup. It's a critical control plane function.

**Allocation Rationale:**
- 300MB limit handles 1000-2000 active sessions
- 0.2 CPU sufficient for session setup/teardown signaling
- Single replica in our test environment
- Stateless design enables horizontal scaling

**Production Recommendations:**
- Deploy minimum 2 replicas for high availability
- Scale memory based on active session count (1GB per 10K sessions)
- Consider geographic distribution for latency optimization

#### UPF (User Plane)
**Resource Profile:** Memory for buffering, high CPU for packet processing, stateful

UPF forwards user plane traffic and performs GTP-U encapsulation/decapsulation. It's the most performance-sensitive component.

**Allocation Rationale:**
- 400MB limit for packet buffering and session state
- 0.3 CPU in our limited environment (production would use much more)
- StatefulSet provides stable network identity
- Persistent volume for session state continuity

**Production Recommendations:**
- CPU-intensive workload: allocate 2-4 CPU cores per UPF instance
- Memory scales with throughput: 2-4GB for 1Gbps, 8-16GB for 10Gbps
- Use hardware acceleration (DPDK, SR-IOV) for high throughput
- Deploy UPF geographically close to base stations for latency

### 3. Replica Count Strategy

**Current Configuration:**
- AMF: 2 replicas (demonstrates HA, load distribution)
- Others: 1 replica each (resource optimization for test environment)

**Decision Factors for Replica Count:**

**Always 2+ replicas for:**
- Critical control plane (NRF, AMF, SMF in production)
- Components without graceful degradation
- Services that must meet 99.999% availability

**Single replica acceptable for:**
- Test and development environments
- Non-critical support services
- When resource constraints are severe

**Scaling Triggers:**
- CPU utilization sustained above 70%
- Memory utilization sustained above 80%
- Request latency exceeds SLA thresholds
- Planned redundancy for availability targets

### 4. Storage Sizing

**Current Allocation:**
- MongoDB: 2Gi (subscriber data, NF profiles, session state)
- UPF: 1Gi (session state, packet buffering spillover)

**Sizing Calculations:**

**MongoDB Storage:**
- Subscriber record: ~2-5 KB per subscriber
- NF profile: ~1 KB per NF instance
- Session state: ~500 bytes per active session
- Formula: `Storage = (Subscribers * 5KB) + (NFs * 1KB) + (Sessions * 0.5KB) + 20% overhead`
- Example: 10,000 subscribers = 50MB + overhead ≈ 100MB
- Our 2Gi allocation supports 200,000+ subscribers with comfortable margin

**UPF Storage:**
- Session state: ~1 KB per session
- Packet buffer spillover: typically not used (in-memory)
- Formula: `Storage = Sessions * 1KB + 50% safety margin`
- Our 1Gi allocation supports 600,000+ sessions

**Production Recommendations:**
- MongoDB: Scale storage 1:1 with subscriber growth
- UPF: Minimal persistent storage needed (most state is volatile)
- Use storage class with appropriate IOPS for MongoDB (3000+ for production)

## Optimization Strategies

### Strategy 1: Vertical Pod Autoscaling (VPA)

While not implemented in our basic deployment, VPA can automatically adjust resource requests based on observed usage patterns.

**Benefits:**
- Automatically right-sizes pods over time
- Reduces manual tuning effort
- Optimizes cluster utilization

**Implementation Consideration:**
- VPA restarts pods to apply new resource allocations
- Not suitable for stateful services without careful planning
- Best used in combination with HPA for stateless services

### Strategy 2: Horizontal Pod Autoscaling (HPA)

HPA automatically scales replica count based on CPU, memory, or custom metrics.

**Example HPA Configuration for AMF:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: amf-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: amf
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

This configuration scales AMF replicas between 2-10 based on CPU utilization, adding replicas when average CPU exceeds 70%.

**Implementation in Docker Desktop:**
- Requires metrics-server (not included by default)
- Limited value in single-node environment
- Primarily useful for learning HPA concepts

**Production Benefits:**
- Automatic scaling during traffic surges
- Cost optimization during low traffic periods
- Improved resilience to unexpected load

### Strategy 3: Resource Quotas per Namespace

Resource quotas prevent any single namespace from consuming all cluster resources.

**Example ResourceQuota:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: open5gs-quota
  namespace: open5gs-core
spec:
  hard:
    requests.cpu: "3"
    requests.memory: 3Gi
    limits.cpu: "4"
    limits.memory: 4Gi
    persistentvolumeclaims: "5"
```

This quota limits the namespace to 3 CPU requests, 4 CPU limits, 3Gi memory requests, 4Gi memory limits, and 5 PVCs maximum.

**Benefits:**
- Prevents runaway resource consumption
- Enforces predictable capacity planning
- Enables multi-tenant cluster sharing

### Strategy 4: Pod Priority and Preemption

Priority classes enable critical pods to preempt lower-priority pods when resources are scarce.

**Example Priority Classes:**
```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority-5g
value: 1000
globalDefault: false
description: "High priority for critical 5G control plane"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: medium-priority-5g
value: 500
globalDefault: false
description: "Medium priority for 5G user plane"
```

Then assign priorities in pod specs:
```yaml
spec:
  priorityClassName: high-priority-5g
```

**Priority Ranking for 5G Components:**
1. **Critical (Priority 1000):** NRF, MongoDB (foundation services)
2. **High (Priority 800):** AMF, SMF (control plane)
3. **Medium (Priority 500):** UPF (user plane)
4. **Low (Priority 200):** Monitoring, logging, non-essential services

## Scaling Recommendations

### Small Deployment (Development/Testing)
**Target:** 100-1000 UEs, single site
- AMF: 1-2 replicas, 512MB each
- SMF: 1-2 replicas, 512MB each
- UPF: 1 replica, 1GB, 1 CPU
- NRF: 1 replica, 256MB
- MongoDB: 1 replica, 1GB
- **Total:** ~3GB RAM, 2 CPU

### Medium Deployment (Enterprise/Campus)
**Target:** 10,000-50,000 UEs, multiple sites
- AMF: 3-5 replicas, 1GB each
- SMF: 3-5 replicas, 1GB each
- UPF: 2-4 replicas, 4GB, 4 CPU each
- NRF: 2 replicas, 512MB each
- MongoDB: 3-member replica set, 4GB each
- **Total:** ~40GB RAM, 30 CPU

### Large Deployment (Service Provider)
**Target:** 100,000+ UEs, nationwide
- AMF: 10+ replicas across regions, 2GB each
- SMF: 10+ replicas across regions, 2GB each
- UPF: 20+ replicas distributed geographically, 16GB, 8 CPU each
- NRF: 3+ replicas per region, 1GB each
- MongoDB: Multi-region replica sets, 16GB+ each
- **Total:** 500GB+ RAM, 300+ CPU (distributed)

## Cost Optimization

### Cloud Provider Cost Estimates

**AWS EKS - Small Deployment:**
- 2x t3.large nodes (2 vCPU, 8GB each): $120/month
- 20GB EBS storage: $2/month
- EKS control plane: $73/month
- **Total:** ~$195/month

**AWS EKS - Medium Deployment:**
- 5x c5.2xlarge nodes (8 vCPU, 16GB each): $650/month
- 100GB EBS storage: $10/month
- EKS control plane: $73/month
- **Total:** ~$733/month

**Azure AKS - Medium Deployment:**
- 5x Standard_D8s_v3 (8 vCPU, 32GB): $800/month
- 100GB Managed Disk: $5/month
- AKS control plane: Free
- **Total:** ~$805/month

**Cost Reduction Strategies:**
- Use spot/preemptible instances for non-critical workloads (50-70% savings)
- Right-size nodes to maximize pod packing efficiency
- Use cluster autoscaler to scale down during off-peak hours
- Leverage reserved instances for predictable baseline capacity (30-50% savings)

## Monitoring and Alerting Thresholds

**Memory Alerts:**
- **Warning:** Pod memory usage > 80% of limit
- **Critical:** Pod memory usage > 95% of limit
- **Action:** Scale horizontally or increase limits

**CPU Alerts:**
- **Warning:** Pod CPU usage > 70% of limit
- **Critical:** Pod CPU throttling detected
- **Action:** Increase CPU limits or scale horizontally

**Storage Alerts:**
- **Warning:** PVC usage > 75% of capacity
- **Critical:** PVC usage > 90% of capacity
- **Action:** Expand PVC or cleanup old data

**Pod Health Alerts:**
- **Critical:** Pod restart count > 5 in 1 hour
- **Critical:** Pod not ready for > 2 minutes
- **Action:** Investigate pod logs, check resource constraints

## Conclusion

Our resource allocation strategy balances efficiency with reliability, fitting a complete 5G Core network within Docker Desktop's constraints while maintaining best practices for production scalability. The 45% memory and 57.5% CPU headroom provides adequate safety margin for system overhead and traffic bursts.

Key takeaways:
1. Requests guarantee minimum resources for predictable performance
2. Limits prevent resource exhaustion while allowing burst capacity
3. Multiple replicas for critical services ensure high availability
4. Persistent storage sized appropriately for data durability
5. Monitoring and alerting enable proactive capacity management

This plan serves as a foundation for production deployments, with clear scaling paths as subscriber counts and traffic volumes grow.