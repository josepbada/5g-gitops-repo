# Week 9 CNF Practice - Architecture Decision Record

## Document Purpose

This document records the key architectural decisions made during the design and implementation of the cloud-native 5G Core deployment. Each decision is documented with its context, rationale, alternatives considered, and implications.

## Decision 1: Stateless Control Plane Design

**Context**: Control plane functions (AMF and SMF) need to manage user sessions and maintain state.

**Decision**: Implement AMF and SMF as stateless applications with external state storage in MongoDB.

**Rationale**:
- Enables horizontal scaling by adding more replicas
- Facilitates zero-downtime updates through rolling deployments
- Provides automatic failover without complex state synchronization
- Aligns with cloud-native 12-factor app principles
- Simplifies operational procedures

**Alternatives Considered**:
1. Stateful with local storage - Rejected due to scaling limitations
2. Stateful with distributed cache - Rejected due to complexity
3. Active-standby with state replication - Rejected due to resource waste

**Implications**:
- Requires reliable database infrastructure (MongoDB)
- All session state must be serializable to database format
- Slight latency increase due to database queries
- Database becomes critical dependency

**Status**: Implemented

---

## Decision 2: MongoDB for State Storage

**Context**: Need persistent storage for AMF and SMF session state, subscriber data, and operational data.

**Decision**: Use MongoDB as the persistent data store for all control plane state.

**Rationale**:
- Schema-less design accommodates evolving 5G data structures
- Horizontal scalability through sharding
- High availability through replica sets
- Native JSON document storage matches 5G data models
- Wide adoption in telecommunications industry
- Open5GS native support for MongoDB

**Alternatives Considered**:
1. PostgreSQL - Rejected due to rigid schema requirements
2. Cassandra - Rejected due to eventual consistency model
3. Redis - Rejected due to in-memory only (though could be supplementary)

**Implications**:
- Additional operational overhead for MongoDB management
- Need for MongoDB expertise in operations team
- Requires backup and recovery procedures
- Resource overhead of running MongoDB

**Status**: Implemented

---

## Decision 3: DaemonSet for UPF Deployment

**Context**: User plane functions require high performance and low latency for packet processing.

**Decision**: Deploy UPF as a DaemonSet with one pod per Kubernetes node.

**Rationale**:
- Ensures user plane capacity is distributed across all nodes
- Localizes data plane processing for lower latency
- Simplifies UPF discovery - one UPF per node with predictable addressing
- Aligns with telecommunications practice of distributing user plane
- Automatic scaling as cluster grows

**Alternatives Considered**:
1. Deployment with multiple replicas - Rejected due to less predictable placement
2. StatefulSet - Rejected as stable identity less important than node distribution
3. Single UPF instance - Rejected due to single point of failure

**Implications**:
- UPF resource allocation multiplied by number of nodes
- Node maintenance affects user plane capacity
- Requires privileged security context on all nodes
- Limits flexibility in UPF placement

**Status**: Implemented

---

## Decision 4: Privileged Security Context for UPF

**Context**: UPF needs to create tunnel interfaces, modify routing tables, and potentially use hardware acceleration.

**Decision**: Grant UPF pods privileged security context with NET_ADMIN, SYS_ADMIN, and NET_RAW capabilities.

**Rationale**:
- Required for creating GTP tunnel interfaces (ogstun, ogstun2)
- Necessary for modifying kernel routing tables
- Enables future use of DPDK or SR-IOV
- Standard practice for telecommunications data plane functions
- No viable alternative for required networking operations

**Alternatives Considered**:
1. User-space networking only - Rejected due to performance limitations
2. Sidecar with privileges - Rejected due to complexity
3. Host networking without privileges - Not technically feasible

**Implications**:
- Security risk if UPF is compromised
- Not suitable for multi-tenant clusters
- Requires careful security auditing
- May not be allowed by some security policies

**Status**: Implemented with awareness of security implications

---

## Decision 5: Calico CNI for NetworkPolicy Support

**Context**: Need to implement network security segmentation between 5G Core components.

**Decision**: Use Calico as the Container Network Interface (CNI) plugin.

**Rationale**:
- Full support for Kubernetes NetworkPolicy API
- High performance with minimal overhead
- Supports both iptables and eBPF datapaths
- Mature and widely adopted in production
- Good documentation and community support
- Required for implementing security zones

**Alternatives Considered**:
1. Default kubenet - Rejected due to no NetworkPolicy support
2. Flannel - Rejected due to limited NetworkPolicy support
3. Cilium - Considered equivalent but Calico chosen for familiarity

**Implications**:
- Additional resource overhead for Calico pods
- Learning curve for Calico-specific features
- Dependency on Calico for network security

**Status**: Implemented

---

## Decision 6: NetworkPolicy Security Model

**Context**: Need to implement security segmentation similar to traditional telecom VLANs and firewalls.

**Decision**: Implement "default deny, explicit allow" NetworkPolicy model with specific policies for each communication path.
Rationale:

Follows security best practice of least privilege
Prevents unauthorized lateral movement between pods
Makes authorized communication paths explicit and auditable
Aligns with telecommunications security requirements
Reduces attack surface in case of pod compromise

Alternatives Considered:

No NetworkPolicies - Rejected due to security risks
Default allow with specific denies - Rejected as less secure
Service mesh mTLS only - Could be complementary but not replacement

Implications:

Requires careful policy design to avoid blocking legitimate traffic
Troubleshooting connectivity issues more complex
Policy updates needed when adding new components
Additional operational overhead

Status: Implemented
Decision 7: Active-Active High Availability for Control Plane
Context: Need high availability for AMF and SMF without single points of failure.
Decision: Deploy AMF and SMF with multiple replicas in active-active configuration with session affinity.
Rationale:

All replicas actively process requests - better resource utilization
Automatic load distribution by Kubernetes service
No failover delay - surviving pods continue immediately
Simpler than active-standby with state synchronization
Enables zero-downtime rolling updates

Alternatives Considered:

Active-standby - Rejected due to wasted resources and failover delay
Single instance with fast restart - Rejected due to service disruption
Shared-nothing without session affinity - Rejected due to PFCP requirements

Implications:

Requires careful session affinity configuration
Database becomes critical shared resource
Need for connection pooling and management
More complex troubleshooting with multiple instances

Status: Implemented

Decision 8: Separate IP Pools for Different DNNs
Context: Need to support multiple types of data services (internet, IMS) with different characteristics.
Decision: Configure separate IP address pools (10.45.0.0/16 and 10.46.0.0/16) for different Data Network Names.
Rationale:

Allows different routing policies for different service types
Enables separate QoS treatment for IMS vs internet traffic
Simplifies troubleshooting by identifying service type from IP
Aligns with 3GPP architecture for multiple DNNs
Supports future addition of more specialized DNNs

Alternatives Considered:

Single IP pool for all services - Rejected due to lack of differentiation
Overlapping IP spaces with VRFs - Rejected due to complexity
IPv6 only for differentiation - Rejected due to IPv4 requirement

Implications:

Requires more IP address space
UPF must maintain separate tunnel interfaces
Routing configuration more complex
Need to manage multiple address pools

Status: Implemented

Decision 9: Resource Limits and Requests
Context: Need to define appropriate resource allocations for each network function.
Decision: Set conservative resource requests with higher limits, allowing bursting.
Rationale:

Ensures pods can be scheduled on resource-constrained nodes
Allows performance bursts for handling traffic spikes
Prevents OOM kills during normal operation
Balances efficiency with reliability
Suitable for development environment

Alternatives Considered:

Equal requests and limits - Rejected as too restrictive
No limits - Rejected due to potential resource starvation
Much higher allocations - Rejected due to limited Minikube resources

Implications:

Pods may be throttled when reaching limits
Resource usage monitoring essential
May need tuning based on actual load
Production would require different values

Status: Implemented with expectation of future tuning

Decision 10: Git-Based Configuration Management
Context: Need version control and change tracking for all infrastructure configuration.
Decision: Store all Kubernetes manifests and configuration in Git repository with clear directory structure.
Rationale:

Complete audit trail of all changes
Enables rollback to previous configurations
Facilitates collaboration and code review
Enables GitOps workflows
Industry standard practice
Supports CI/CD integration

Alternatives Considered:

Manual configuration - Rejected due to no audit trail
Configuration management database - Rejected as overkill
Helm charts - Considered for future but YAML chosen for learning

Implications:

Requires discipline to commit all changes
Need for meaningful commit messages
Git expertise required
Potential for configuration drift if changes made without commits

Status: Implemented

Summary of Key Architectural Patterns

Microservices Architecture: Each network function is independent service
Stateless Applications: Control plane functions externalize all state
Database-Backed State: MongoDB provides durable state storage
Container Orchestration: Kubernetes manages lifecycle and scaling
Declarative Configuration: Infrastructure as Code with YAML manifests
Network Segmentation: NetworkPolicies implement security zones
High Availability: Multiple replicas with automatic failover
Observability: Metrics endpoints for monitoring
Infrastructure as Code: Git version control for all configuration
Cloud Native: Follows CNCF and 12-factor principles

Future Architecture Evolution
Short Term (Next 3 Months)

Implement Prometheus and Grafana for comprehensive monitoring
Add HorizontalPodAutoscaler for automatic scaling
Implement pod disruption budgets
Add init containers for dependency checking

Medium Term (3-6 Months)

Deploy MongoDB replica set for HA
Implement service mesh (Istio) for mTLS and observability
Add complete 5G Core functions (NRF, AUSF, UDM, PCF)
Implement CI/CD pipeline with automated testing

Long Term (6-12 Months)

Multi-cluster deployment for geographic distribution
Implement DPDK in UPF for higher throughput
Add network slice-specific routing
Implement automated capacity management
Deploy on production-grade Kubernetes cluster

References

3GPP TS 23.501: System architecture for the 5G System
Kubernetes Documentation: https://kubernetes.io/docs/
12-Factor App Methodology: https://12factor.net/
Cloud Native Computing Foundation Best Practices
Open5GS Architecture Documentation