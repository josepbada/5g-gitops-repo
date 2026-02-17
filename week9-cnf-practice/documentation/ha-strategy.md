# High Availability Strategy for Cloud-Native 5G Core

## Executive Summary

This document describes the high availability (HA) architecture implemented in our Open5GS deployment. The goal is to demonstrate how cloud-native network functions achieve telecommunications-grade availability (99.999% or "five nines") through automated orchestration, redundancy, and self-healing capabilities.

## Availability Target: 99.999% (Five Nines)

**Downtime Budget:**
- Per year: 5.26 minutes
- Per month: 26.3 seconds  
- Per week: 6.05 seconds
- Per day: 0.86 seconds

This extreme availability requirement means we have almost no tolerance for prolonged outages. Every failure must be detected and recovered within seconds to stay within budget.

## HA Strategy Components

### 1. Redundancy Through Multiple Replicas

**Implementation:** The AMF deployment is configured with 2 replicas, providing redundancy for this critical control plane function.

**How it works:** Kubernetes maintains two independent AMF pods running simultaneously. The Kubernetes Service load balances traffic across both pods. If one pod fails, traffic automatically flows to the remaining healthy pod without any manual intervention.

**Recovery time:** Immediate (0 seconds). When one pod fails, the Service instantly stops routing traffic to it and directs all requests to the healthy pod.

**Configuration:**
```yaml
spec:
  replicas: 2
```

**Trade-offs:** Multiple replicas consume more resources (800MB RAM for 2 AMF pods instead of 400MB for 1). However, this investment is essential for high availability.

### 2. Pod Anti-Affinity Rules

**Implementation:** The AMF deployment includes pod anti-affinity rules that prefer to schedule replicas on different nodes.

**How it works:** The Kubernetes scheduler uses affinity rules to influence pod placement. With anti-affinity, the scheduler tries to place AMF pods on different physical nodes to protect against node failures.

**Configuration:**
```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - amf
        topologyKey: kubernetes.io/hostname
```

**Note:** In Docker Desktop with a single node, both pods run on the same node, but the rule is configured correctly for multi-node production environments.

### 3. Liveness Probes for Automatic Recovery

**Implementation:** All deployments include liveness probes that check if the container is functioning correctly.

**How it works:** Every 10 seconds, Kubernetes attempts to establish a TCP connection to port 7777 on each pod. If three consecutive checks fail (30 seconds total), Kubernetes assumes the container is unhealthy and restarts it.

**Recovery time:** Approximately 30-50 seconds from failure detection to pod restart and readiness.

**Configuration:**
```yaml
livenessProbe:
  tcpSocket:
    port: 7777
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3
```

**Why this matters:** Without liveness probes, a hung or crashed container would remain in the "Running" state indefinitely, even though it cannot serve traffic. Liveness probes enable automatic recovery without operator intervention.

### 4. Readiness Probes for Traffic Management

**Implementation:** All deployments include readiness probes that determine when a pod is ready to receive traffic.

**How it works:** Every 5 seconds, Kubernetes checks if the pod is ready by testing the TCP connection on port 7777. If the check fails, Kubernetes removes the pod from the Service endpoints, preventing traffic from being routed to it. Once the pod recovers and passes the readiness check, it's automatically added back to the Service.

**Recovery time:** 5-10 seconds to detect readiness and resume traffic routing.

**Configuration:**
```yaml
readinessProbe:
  tcpSocket:
    port: 7777
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3
```

**Why this matters:** Readiness probes prevent traffic from being sent to pods that are starting up or temporarily unable to serve requests, ensuring users only connect to fully functional instances.

### 5. Service Load Balancing

**Implementation:** Kubernetes Services automatically load balance traffic across all ready pods.

**How it works:** The Service maintains a list of endpoints (pod IP addresses) that have passed their readiness probes. When a client connects to the Service, kube-proxy distributes the connection to one of the healthy endpoints using round-robin or random selection.

**Recovery time:** Immediate. As soon as a pod fails its readiness probe, it's removed from the endpoint list within 5-10 seconds.

**Why this matters:** Load balancing distributes workload evenly and provides seamless failover when pods become unhealthy.

### 6. Resource Requests and Limits

**Implementation:** Every container specifies both resource requests (guaranteed minimum) and limits (maximum allowed).

**How it works:** Resource requests ensure Kubernetes only schedules pods on nodes with sufficient available resources. Resource limits prevent any single pod from consuming all node resources and starving other pods.

**Example for AMF:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "400Mi"
    cpu: "300m"
```

**Why this matters:** Resource management prevents cascading failures where one misbehaving pod consumes all resources and causes other pods to fail.

### 7. StatefulSet for Stable Identity

**Implementation:** The UPF and MongoDB are deployed as StatefulSets rather than Deployments.

**How it works:** StatefulSets provide stable, predictable pod names (upf-0, mongodb-0) and stable network identities. This allows the SMF to reliably connect to a specific UPF instance even after restarts.

**Recovery time:** 30-50 seconds for pod restart with the same identity.

**Why this matters:** Some network functions require stable network identities for peer relationships. The SMF needs to establish PFCP sessions with specific UPF instances, which requires knowing their stable addresses.

### 8. Persistent Volumes for Data Durability

**Implementation:** MongoDB and UPF use PersistentVolumeClaims to store data that must survive pod restarts.

**How it works:** Kubernetes creates a PersistentVolume for each StatefulSet pod. The volume remains attached even if the pod is deleted and recreated. Data written to the volume persists across pod lifecycles.

**Recovery time:** Data is immediately available when the pod restarts (no data recovery time).

**Why this matters:** Subscriber data, network function profiles, and session state must survive pod failures to maintain service continuity.

### 9. Externalized Configuration

**Implementation:** All configuration is stored in ConfigMaps rather than baked into container images.

**How it works:** ConfigMaps are mounted as volumes into pods. Configuration changes can be made by updating the ConfigMap and performing a rolling restart of pods.

**Why this matters:** Separating configuration from images enables:
- Quick configuration changes without rebuilding images
- Version control of configuration through GitOps
- Consistent configuration across all replicas
- Easy rollback to previous configurations

### 10. Service Discovery Through NRF

**Implementation:** The NRF maintains a registry of all network function instances. Other functions query the NRF to discover services.

**How it works:** When a network function starts, it registers with the NRF. Other functions query the NRF to find available instances of the services they need. If a function fails, its registration expires and it's automatically removed from the registry.

**Why this matters:** Service discovery enables dynamic scaling and automatic recovery. New instances are automatically discovered, and failed instances are automatically removed from service.

## Combined Strategy for Five Nines

Achieving 99.999% availability requires all strategies working together:

**Prevention Layer:**
- Multiple replicas eliminate single points of failure
- Resource limits prevent resource exhaustion
- Anti-affinity rules protect against node failures

**Detection Layer:**
- Liveness probes detect failed containers (10-second intervals)
- Readiness probes detect pods unable to serve traffic (5-second intervals)
- Service continuously monitors pod health

**Recovery Layer:**
- Automatic pod restart on liveness failure (20-30 seconds)
- Immediate traffic rerouting to healthy pods
- Persistent data survives pod restarts

**Resilience Layer:**
- Externalized state in MongoDB survives control plane restarts
- Persistent volumes maintain UPF session state
- ConfigMaps enable quick reconfiguration without image rebuilds

## Typical Failure Scenarios

### Scenario 1: AMF Pod Crashes

**Timeline:**
- T0: AMF pod crashes
- T+5s: Readiness probe fails, pod removed from Service endpoints
- T+10s: Liveness probe fails
- T+11s: Kubernetes terminates the crashed pod
- T+12s: Kubernetes creates new pod
- T+30s: New pod starts and passes readiness probe
- T+31s: New pod added to Service endpoints

**User Impact:** Zero. The second AMF replica continues serving all traffic during the entire recovery period.

**Downtime:** 0 seconds (due to multiple replicas)

### Scenario 2: Single Replica Service (SMF) Fails

**Timeline:**
- T0: SMF pod crashes
- T+5s: Readiness probe fails
- T+10s: Liveness probe fails
- T+11s: Kubernetes restarts pod
- T+30s: Pod ready and added to Service

**User Impact:** Existing sessions may be disrupted. New session requests fail during the 30-second recovery window.

**Downtime:** ~30 seconds

**Note:** This demonstrates why critical services should have multiple replicas. SMF is deployed with a single replica in our simplified setup, but production deployments should use 2+ replicas.

### Scenario 3: Node Failure (Docker Desktop Restart)

**Timeline:**
- T0: Node becomes unavailable
- T+30s: Kubernetes marks node as NotReady
- T+300s: Kubernetes begins evicting pods (5-minute timeout)
- T+301s: Pods scheduled on new node (in multi-node cluster)
- T+330s: All pods running and ready

**User Impact:** Total outage during recovery unless running multi-replica deployments across multiple nodes.

**Downtime:** 5-6 minutes in single-node cluster (exceeds five nines budget)

**Mitigation:** Production environments must use multi-node clusters with pod anti-affinity to survive node failures.

### Scenario 4: MongoDB Failure

**Timeline:**
- T0: MongoDB pod crashes
- T+10s: Liveness probe fails
- T+11s: Kubernetes restarts pod
- T+40s: MongoDB starts and data is loaded from persistent volume
- T+45s: Pod ready

**User Impact:** Control plane functions cannot access subscriber data during the 45-second recovery. Existing sessions continue (state cached), but new registrations fail.

**Downtime:** ~45 seconds for data plane operations

**Note:** Production deployments should use MongoDB replica sets for high availability.

## Resource Allocation Summary

Total resource allocation optimized for Docker Desktop (4 CPU, 5GB RAM):

| Component | Replicas | Memory per Pod | CPU per Pod | Total Memory | Total CPU |
|-----------|----------|----------------|-------------|--------------|-----------|
| MongoDB   | 1        | 800MB          | 0.4         | 800MB        | 0.4       |
| NRF       | 1        | 256MB          | 0.2         | 256MB        | 0.2       |
| AMF       | 2        | 400MB          | 0.3         | 800MB        | 0.6       |
| SMF       | 1        | 300MB          | 0.2         | 300MB        | 0.2       |
| UPF       | 1        | 400MB          | 0.3         | 400MB        | 0.3       |
| **Total** | **6**    | -              | -           | **2.56GB**   | **1.7**   |

**Headroom:** Approximately 2.4GB RAM and 2.3 CPU remain available for system overhead and burst capacity.

## Recommendations for Production

1. **Increase Replicas:** Deploy at least 2 replicas of all critical control plane functions (NRF, SMF, AMF)

2. **Multi-Node Cluster:** Use a minimum of 3 worker nodes with pod anti-affinity to survive node failures

3. **Database High Availability:** Deploy MongoDB as a replica set with at least 3 members

4. **Resource Scaling:** Allocate more resources per pod based on actual traffic loads

5. **Monitoring:** Implement Prometheus and Grafana for real-time monitoring and alerting

6. **Automated Testing:** Regularly perform chaos engineering tests to validate recovery procedures

7. **Geographic Distribution:** For disaster recovery, deploy across multiple availability zones or regions

## Conclusion

Our cloud-native 5G Core demonstrates several key HA principles:
- Automated failure detection through health probes
- Self-healing through automatic pod restarts
- Load distribution through multiple replicas
- Data persistence through StatefulSets and PersistentVolumes
- Zero-downtime updates through rolling deployments

While our simplified deployment on Docker Desktop cannot achieve true five nines availability (due to single-node constraints), the architecture and patterns we've implemented are production-ready and will scale to meet telecommunications requirements in multi-node environments.