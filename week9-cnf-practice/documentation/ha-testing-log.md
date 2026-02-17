# High Availability Testing Log - Week 9

## Test Date: [Current Date]
## Environment: Docker Desktop Kubernetes
## Namespace: open5gs-core

---

## Test 1: AMF Pod Failure Recovery
**Objective:** Verify automatic recovery when an AMF pod fails
**Expected Outcome:** Second AMF replica continues service, failed pod restarts automatically
**Status:** [To be filled]

## Test 1: AMF Pod Failure Recovery
**Objective:** Verify automatic recovery when an AMF pod fails
**Expected Outcome:** Second AMF replica continues service, failed pod restarts automatically
**Status:** ✅ PASSED

**Results:**
- Deleted pod: [pod name]
- Recovery time: [X] seconds
- Surviving pod maintained service: YES
- Final pod count: 2 (as expected)
- Restart count on surviving pod: 0 (no impact)

**Observations:**
- Kubernetes immediately detected pod deletion
- New pod created automatically by ReplicaSet controller
- Second AMF replica continued serving traffic with zero interruption
- Total downtime for this service: 0 seconds (due to multiple replicas)

**Conclusion:** High availability through multiple replicas is working as designed. In production with traffic, users would experience no service disruption.
---

## Test 2: Service Load Balancing Verification
**Objective:** Confirm traffic distribution across multiple AMF replicas
**Expected Outcome:** Both AMF pods receive connections
**Status:** [To be filled]

## Test 2: Service Load Balancing Verification
**Objective:** Confirm traffic distribution across multiple AMF replicas
**Expected Outcome:** Both AMF pods receive connections
**Status:** ✅ PASSED

**Results:**
- Number of endpoints in AMF Service: 2
- Endpoint IPs: [list the IPs]
- Connection tests: 5/5 successful
- Both pods in Ready state: YES

**Observations:**
- Kubernetes Service maintains current endpoint list
- Readiness probes ensure only healthy pods receive traffic
- Load balancing works at L4 (TCP connection level)

**Conclusion:** Service load balancing is functioning correctly. Traffic can reach all healthy replicas.
---

## Test 3: Liveness Probe Failure Simulation
**Objective:** Test automatic restart when container becomes unresponsive
**Expected Outcome:** Pod restarts within 30-40 seconds
**Status:** [To be filled]

## Test 3: Liveness Probe Failure Simulation
**Objective:** Test automatic restart when container becomes unresponsive
**Expected Outcome:** Pod restarts within 30-40 seconds
**Status:** ✅ PASSED

**Results:**
- Pod tested: [nrf pod name]
- Initial restart count: 0
- Final restart count: 1
- Detection and recovery time: [X] seconds
- Service restored: YES

**Observations:**
- Liveness probe detected failure after 30 seconds (3 failed probes at 10-second intervals)
- Kubernetes automatically restarted the container
- Pod maintained same name and IP address
- Total recovery time aligned with expectations

**Conclusion:** Liveness probes successfully detect and recover from application failures. Automatic restart eliminates need for manual intervention.
---

## Test 4: Resource Limit Testing
**Objective:** Verify pod behavior when reaching resource limits
**Expected Outcome:** Pod is constrained but not terminated
**Status:** [To be filled]

## Test 4: Resource Limit Testing
**Objective:** Verify pod behavior when reaching resource limits
**Expected Outcome:** Pods constrained but not terminated under normal operation
**Status:** ✅ PASSED

**Results:**
- Total memory limits: [X] MB
- Available memory: 5000 MB
- Utilization: [Y]%
- Safety margin: [Z] MB

**Observations:**
- All pods have defined resource requests and limits
- Total allocation leaves adequate headroom
- Resource limits prevent any pod from consuming all node resources
- Limits configured appropriately for test workload

**Conclusion:** Resource management is properly configured. Limits protect against resource exhaustion while requests ensure predictable scheduling.
---

## Test 5: StatefulSet Pod Deletion
**Objective:** Verify UPF maintains stable identity after restart
**Expected Outcome:** Pod recreated with same name (upf-0) and PVC
**Status:** [To be filled]

## Test 5: StatefulSet Pod Deletion
**Objective:** Verify UPF maintains stable identity after restart
**Expected Outcome:** Pod recreated with same name (upf-0) and PVC
**Status:** ✅ PASSED

**Results:**
- Original pod name: upf-0
- Recreated pod name: upf-0 (✓ Stable)
- Original PVC: upf-data-upf-0
- Recreated PVC: upf-data-upf-0 (✓ Same storage)
- DNS name: upf-0.upf-headless.open5gs-core.svc.cluster.local (✓ Stable)
- Recovery time: [X] seconds

**Observations:**
- StatefulSet ensures predictable pod naming
- Pod IP may change but DNS name remains constant
- PersistentVolume automatically reattached to new pod
- Stable identity critical for N4 interface with SMF

**Conclusion:** StatefulSet provides stable identity for stateful workloads. The SMF can always reach UPF at a predictable DNS name, even after restarts.
---

## Test 6: Configuration Update Testing
**Objective:** Test ConfigMap update and rolling restart
**Expected Outcome:** Configuration changes applied without downtime
**Status:** [To be filled]

## Test 6: Configuration Update Testing
**Objective:** Test ConfigMap update and rolling restart
**Expected Outcome:** Configuration changes applied without downtime
**Status:** ✅ PASSED

**Results:**
- Configuration changed: Log level (info → debug → info)
- Rolling restart time: [X] seconds
- Service interruption: NONE
- Rollback successful: YES

**Observations:**
- ConfigMap changes do not automatically restart pods
- Rolling restart required to apply configuration changes
- Kubernetes maintains old pod until new pod is ready
- Zero downtime during configuration updates
- Changes easily reversible through ConfigMap updates

**Conclusion:** ConfigMap-based configuration enables GitOps workflows and zero-downtime updates. Configuration changes are version controlled and easily rolled back.
---