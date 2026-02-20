# 5G Core Network Service Model Documentation

## Overview

This service model defines a minimal 5G core network suitable for learning orchestration concepts. It includes all essential components needed for basic 5G functionality while remaining simple enough to deploy in resource-constrained environments.

## Architecture

The service consists of three logical layers:

### Data Layer
- **MongoDB**: Persistent storage for subscriber data, session information, and configuration

### Control Plane Layer
- **NRF**: Service discovery and registration for all network functions
- **AUSF**: Authentication server implementing 5G-AKA
- **UDM**: Unified data management for subscriber profiles
- **AMF**: Access and Mobility Management coordinating RAN connections
- **SMF**: Session Management handling PDU session establishment

### User Plane Layer
- **UPF**: User Plane Function forwarding data packets

## Network Interfaces

| Interface | Purpose | Network | Components |
|-----------|---------|---------|------------|
| N2 | Control plane between RAN and AMF | 10.100.50.0/24 | AMF |
| N3 | User plane between RAN and UPF | 10.100.51.0/24 | UPF |
| N4 | Control plane between SMF and UPF | 10.100.52.0/24 | SMF, UPF |
| N6 | Data network connectivity | 10.100.53.0/24 | UPF |
| SBI | Service Based Interface | Kubernetes ClusterIP | All CP NFs |

## Deployment Workflow

The service model defines a four-phase deployment process:

1. **Infrastructure Phase**: Deploy MongoDB and create network attachments
2. **Foundation Phase**: Deploy NRF, AUSF, UDM
3. **Core Phase**: Deploy AMF and SMF
4. **User Plane Phase**: Deploy UPF

Each phase includes validation steps to ensure proper deployment before proceeding.

## Resource Requirements

| Component | CPU | Memory | Storage |
|-----------|-----|---------|---------|
| MongoDB | 500m | 512Mi | 1Gi |
| NRF | 200m | 256Mi | - |
| AUSF | 200m | 256Mi | - |
| UDM | 200m | 256Mi | - |
| AMF | 400m | 512Mi | - |
| SMF | 400m | 512Mi | - |
| UPF | 600m | 512Mi | - |
| **Total** | **2.5 CPUs** | **2.5GB** | **1Gi** |

## Configuration Parameters

### Network Identity
- **PLMN**: Configured via MCC/MNC parameters
- **TAC**: Tracking Area Code for location management
- **DNN**: Data Network Name (default: "internet")

### Security
- **Integrity Protection**: NIA2, NIA1, NIA0
- **Ciphering**: NEA0, NEA1, NEA2
- **Subscriber Credentials**: OPC and K values

### Capacity
- **Maximum UEs**: 1000 (configurable via AMF capacity parameter)
- **UE IP Pool**: 10.45.0.0/16 (provides 65,534 addresses)

## Lifecycle Management

### Day 0 (Deployment)
Automated deployment through orchestrator following defined phases and dependencies.

### Day 1 (Configuration)
- Load ConfigMaps for each network function
- Initialize subscriber database
- Configure network interfaces
- Test connectivity between components

### Day 2 (Operations)
- Automated scaling based on CPU utilization and session count
- Health monitoring with automatic restart on failure
- Configuration updates through GitOps workflow
- Performance monitoring and optimization

## Operational Policies

### Scaling Policies
- **AMF**: Scale at 75% CPU, min 1, max 3 replicas
- **SMF**: Scale at 800 active sessions, min 1, max 3 replicas

### Health Checks
- **Liveness Probe**: HTTP /health every 10s
- **Readiness Probe**: HTTP /ready every 5s

### Failure Recovery
- **Automatic Restart**: Up to 3 attempts with 60s backoff
- **Database Backup**: Daily at 02:00, 7-day retention

## Service Level Objectives

- **Availability**: 99.9% uptime
- **Registration Latency**: < 200ms
- **Session Setup Latency**: < 500ms
- **Throughput**: 1 Gbps aggregate
- **Concurrent Users**: 1000 maximum

## Integration with ONAP Concepts

This service model demonstrates several ONAP principles:

1. **Declarative Specification**: The entire service is defined declaratively
2. **Separation of Concerns**: Topology, configuration, and policies are separate
3. **Lifecycle Management**: Clear distinction between Day 0, Day 1, and Day 2
4. **Policy-Driven**: Automation through defined policies rather than scripts
5. **Model-Driven**: Configuration from templates and parameters

## Customization

To customize this model for different deployments:

1. Modify `parameter_sets` in the configuration template
2. Adjust resource allocations based on expected load
3. Update scaling policies for specific requirements
4. Configure appropriate network subnets for your environment

## Limitations

This is a simplified model for learning purposes:

- Single replica for most components (production would use multiple)
- Minimal security configuration
- No integration with external AAA systems
- Limited monitoring and observability
- No disaster recovery across availability zones

## Future Enhancements

Potential additions to make this production-ready:

- Multi-region deployment support
- Integration with external policy servers
- Advanced security (mTLS, certificate management)
- Comprehensive monitoring with Prometheus/Grafana
- Log aggregation with ELK stack
- Configuration backup and versioning
- Blue-green deployment capability