# Monitoring Documentation

## Overview

This document outlines the monitoring setup for the Craftista microservices application. All services expose Prometheus-compatible metrics that can be scraped and visualized.

## Services and Metrics

### 1. Catalogue Service (Python/Flask)

**Technology**: Python Flask with `prometheus_client` library

**Metrics Endpoint**: `http://<catalogue-service>:5000/metrics`

**Exposed Metrics**:

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|--------|
| `catalogue_http_requests_total` | Counter | Total HTTP requests received | `method`, `endpoint`, `status` |
| `catalogue_http_request_duration_seconds` | Histogram | HTTP request latency in seconds | `method`, `endpoint` |
| `catalogue_db_connection_status` | Gauge | Database connection status (1=connected, 0=disconnected) | - |
| `catalogue_products_total` | Gauge | Total number of products in catalogue | - |

**Additional Notes**:
- Metrics are collected via Flask middleware (before_request/after_request)
- Database connection status updates on each DB operation
- Product count updates when products are fetched from database
- Health endpoint available at `/health`

---

### 2. Frontend Service (Node.js/Express)

**Technology**: Node.js Express with `prom-client` library

**Metrics Endpoint**: `http://<frontend-service>:3000/metrics`

**Exposed Metrics**:

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|--------|
| `frontend_http_request_duration_seconds` | Histogram | HTTP request duration in seconds | `method`, `route`, `status_code` |
| `frontend_http_requests_total` | Counter | Total number of HTTP requests | `method`, `route`, `status_code` |
| `frontend_service_dependency_up` | Gauge | Service dependency status (1=up, 0=down) | `service` |

**Default Node.js Metrics** (with `frontend_` prefix):
- `nodejs_eventloop_lag_*` - Event loop lag metrics
- `nodejs_active_handles` - Number of active handles
- `nodejs_active_requests` - Number of active requests
- `process_cpu_*` - CPU usage metrics
- `process_resident_memory_bytes` - Memory usage
- `nodejs_gc_duration_seconds` - Garbage collection metrics

**Service Dependencies Tracked**:
- `catalogue` - Catalogue service health
- `recommendation` - Recommendation service health
- `voting` - Voting service health

**Additional Notes**:
- Metrics collected via Express middleware
- Service dependency status updated on each health check
- Histogram buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10]
- Health endpoint available at `/health`

---

### 3. Recommendation Service (Go/Gin)

**Technology**: Go with Gin framework and `prometheus/client_golang` library

**Metrics Endpoint**: `http://<recommendation-service>:8080/metrics`

**Exposed Metrics**:

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|--------|
| `recommendation_http_requests_total` | Counter | Total number of HTTP requests | `method`, `endpoint`, `status` |
| `recommendation_http_request_duration_seconds` | Histogram | HTTP request duration in seconds | `method`, `endpoint` |
| `recommendation_origami_of_day_total` | Counter | Total origami-of-the-day recommendations served | - |

**Additional Notes**:
- Metrics collected via Gin middleware (prometheusMiddleware)
- Uses Prometheus default buckets for histogram
- Special counter for tracking recommendation API usage
- Health endpoint available at `/health`

---

### 4. Voting Service (Java/Spring Boot)

**Technology**: Spring Boot with Actuator and Micrometer Prometheus registry

**Metrics Endpoint**: `http://<voting-service>:8080/actuator/prometheus`

**Actuator Endpoints**:
- `/actuator/health` - Health status with details
- `/actuator/info` - Application information
- `/actuator/metrics` - Available metrics list
- `/actuator/prometheus` - Prometheus formatted metrics

**Exposed Metrics** (Spring Boot Actuator defaults):

| Metric Category | Example Metrics | Description |
|-----------------|-----------------|-------------|
| JVM Memory | `jvm_memory_used_bytes`, `jvm_memory_max_bytes` | JVM memory usage |
| JVM GC | `jvm_gc_pause_seconds_*`, `jvm_gc_memory_allocated_bytes` | Garbage collection metrics |
| JVM Threads | `jvm_threads_live`, `jvm_threads_daemon` | Thread pool metrics |
| HTTP Server | `http_server_requests_seconds_*` | HTTP request metrics with method, uri, status |
| System | `system_cpu_usage`, `system_cpu_count` | System-level metrics |
| Process | `process_uptime_seconds`, `process_cpu_usage` | Process metrics |
| Tomcat | `tomcat_sessions_*`, `tomcat_threads_*` | Tomcat container metrics |
| Database | `hikaricp_connections_*` | Database connection pool metrics |

**Custom Tags**:
- `application=voting-service`
- `environment=${ENVIRONMENT:dev}`

**Additional Notes**:
- All actuator endpoints exposed: health, info, prometheus, metrics
- Health endpoint shows detailed component status
- Application info includes name, description, and version
- Base path for actuator: `/actuator`

---

## Prometheus Configuration

### ServiceMonitor Configuration (Kubernetes)

To scrape metrics from these services in Kubernetes, create ServiceMonitor resources:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: catalogue-metrics
  labels:
    app: catalogue
spec:
  selector:
    matchLabels:
      app: catalogue
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: frontend-metrics
  labels:
    app: frontend
spec:
  selector:
    matchLabels:
      app: frontend
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: recommendation-metrics
  labels:
    app: recommendation
spec:
  selector:
    matchLabels:
      app: recommendation
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: voting-metrics
  labels:
    app: voting
spec:
  selector:
    matchLabels:
      app: voting
  endpoints:
  - port: http
    path: /actuator/prometheus
    interval: 30s
```

### Prometheus Scrape Configuration (prometheus.yml)

If using standalone Prometheus:

```yaml
scrape_configs:
  - job_name: 'catalogue'
    static_configs:
      - targets: ['catalogue:5000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'frontend'
    static_configs:
      - targets: ['frontend:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'recommendation'
    static_configs:
      - targets: ['recommendation:8080']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'voting'
    static_configs:
      - targets: ['voting:8080']
    metrics_path: '/actuator/prometheus'
    scrape_interval: 30s
```

---

## Viewing Metrics in Prometheus

### Accessing Prometheus UI

1. Port-forward to Prometheus (if running in Kubernetes):
   ```bash
   kubectl port-forward -n monitoring svc/prometheus 9090:9090
   ```

2. Access Prometheus UI at `http://localhost:9090`

### Useful PromQL Queries

**Request Rate (Requests per second)**:
```promql
# Catalogue service request rate
rate(catalogue_http_requests_total[5m])

# Frontend service request rate
rate(frontend_http_requests_total[5m])

# Recommendation service request rate
rate(recommendation_http_requests_total[5m])

# Voting service request rate (Spring Boot)
rate(http_server_requests_seconds_count{application="voting-service"}[5m])
```

**Request Latency (95th percentile)**:
```promql
# Catalogue service latency
histogram_quantile(0.95, rate(catalogue_http_request_duration_seconds_bucket[5m]))

# Frontend service latency
histogram_quantile(0.95, rate(frontend_http_request_duration_seconds_bucket[5m]))

# Recommendation service latency
histogram_quantile(0.95, rate(recommendation_http_request_duration_seconds_bucket[5m]))

# Voting service latency
histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{application="voting-service"}[5m]))
```

**Error Rate**:
```promql
# Catalogue 5xx errors
rate(catalogue_http_requests_total{status=~"5.."}[5m])

# Frontend 5xx errors
rate(frontend_http_requests_total{status_code=~"5.."}[5m])

# Voting service errors
rate(http_server_requests_seconds_count{application="voting-service",status=~"5.."}[5m])
```

**Service Health**:
```promql
# Database connection status
catalogue_db_connection_status

# Service dependencies (from frontend)
frontend_service_dependency_up

# Number of products
catalogue_products_total

# Recommendations served
recommendation_origami_of_day_total
```

**Resource Metrics**:
```promql
# Frontend Node.js memory usage
process_resident_memory_bytes{job="frontend"}

# Voting service JVM memory
jvm_memory_used_bytes{application="voting-service"}

# Voting service JVM heap usage
jvm_memory_used_bytes{application="voting-service",area="heap"}
```

---

## Grafana Dashboard Setup

### Accessing Grafana

1. Port-forward to Grafana (if running in Kubernetes):
   ```bash
   kubectl port-forward -n monitoring svc/grafana 3000:3000
   ```

2. Access Grafana UI at `http://localhost:3000`
3. Default credentials: `admin/admin` (change on first login)

### Adding Prometheus Data Source

1. Navigate to **Configuration** → **Data Sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Configure:
   - **Name**: Prometheus
   - **URL**: `http://prometheus:9090` (or appropriate service URL)
   - Click **Save & Test**

### Creating Dashboards

#### Dashboard 1: Application Overview

**Panels to include**:

1. **Total Request Rate** (Graph)
   ```promql
   sum(rate(catalogue_http_requests_total[5m])) by (job)
   + sum(rate(frontend_http_requests_total[5m])) by (job)
   + sum(rate(recommendation_http_requests_total[5m])) by (job)
   + sum(rate(http_server_requests_seconds_count{application="voting-service"}[5m])) by (application)
   ```

2. **Service Health Status** (Gauge)
   ```promql
   frontend_service_dependency_up
   ```

3. **Request Latency by Service** (Graph)
   ```promql
   histogram_quantile(0.95, rate(catalogue_http_request_duration_seconds_bucket[5m]))
   histogram_quantile(0.95, rate(frontend_http_request_duration_seconds_bucket[5m]))
   histogram_quantile(0.95, rate(recommendation_http_request_duration_seconds_bucket[5m]))
   ```

4. **Database Connection Status** (Stat)
   ```promql
   catalogue_db_connection_status
   ```

#### Dashboard 2: Catalogue Service

1. **HTTP Request Rate** (Graph)
   ```promql
   sum(rate(catalogue_http_requests_total[5m])) by (endpoint)
   ```

2. **Request Duration** (Heatmap)
   ```promql
   rate(catalogue_http_request_duration_seconds_bucket[5m])
   ```

3. **Status Code Distribution** (Pie Chart)
   ```promql
   sum(catalogue_http_requests_total) by (status)
   ```

4. **Products Count** (Stat)
   ```promql
   catalogue_products_total
   ```

5. **Database Connection** (Stat/Gauge)
   ```promql
   catalogue_db_connection_status
   ```

#### Dashboard 3: Frontend Service

1. **HTTP Request Rate** (Graph)
   ```promql
   sum(rate(frontend_http_requests_total[5m])) by (route)
   ```

2. **Node.js Event Loop Lag** (Graph)
   ```promql
   nodejs_eventloop_lag_seconds{job="frontend"}
   ```

3. **Memory Usage** (Graph)
   ```promql
   process_resident_memory_bytes{job="frontend"}
   ```

4. **Service Dependencies** (Status Panel)
   ```promql
   frontend_service_dependency_up
   ```

5. **Request Latency by Route** (Graph)
   ```promql
   histogram_quantile(0.95, rate(frontend_http_request_duration_seconds_bucket[5m])) by (route)
   ```

#### Dashboard 4: Recommendation Service

1. **HTTP Request Rate** (Graph)
   ```promql
   sum(rate(recommendation_http_requests_total[5m])) by (endpoint)
   ```

2. **Recommendations Served** (Counter/Stat)
   ```promql
   recommendation_origami_of_day_total
   ```

3. **Request Duration** (Graph)
   ```promql
   histogram_quantile(0.95, rate(recommendation_http_request_duration_seconds_bucket[5m]))
   ```

#### Dashboard 5: Voting Service (JVM Metrics)

1. **HTTP Request Rate** (Graph)
   ```promql
   sum(rate(http_server_requests_seconds_count{application="voting-service"}[5m])) by (uri)
   ```

2. **JVM Heap Memory** (Graph)
   ```promql
   jvm_memory_used_bytes{application="voting-service",area="heap"}
   jvm_memory_max_bytes{application="voting-service",area="heap"}
   ```

3. **GC Pause Time** (Graph)
   ```promql
   rate(jvm_gc_pause_seconds_sum{application="voting-service"}[5m])
   ```

4. **Thread Count** (Graph)
   ```promql
   jvm_threads_live{application="voting-service"}
   ```

5. **CPU Usage** (Graph)
   ```promql
   process_cpu_usage{application="voting-service"}
   system_cpu_usage{application="voting-service"}
   ```

6. **Database Connections (HikariCP)** (Graph)
   ```promql
   hikaricp_connections_active{application="voting-service"}
   hikaricp_connections_idle{application="voting-service"}
   ```

### Importing Pre-built Dashboards

Grafana provides pre-built dashboards for common metrics:

1. **Node.js Application Dashboard**:
   - Dashboard ID: `11159`
   - Suitable for Frontend service

2. **JVM (Micrometer) Dashboard**:
   - Dashboard ID: `4701`
   - Suitable for Voting service

3. **Flask/Python Application Dashboard**:
   - Dashboard ID: `3894`
   - Suitable for Catalogue service

**To import**:
1. Click **+** → **Import**
2. Enter Dashboard ID
3. Select Prometheus data source
4. Click **Import**

---

## Alerting Rules

### Example Prometheus Alert Rules

```yaml
groups:
  - name: application_alerts
    interval: 30s
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: |
          sum(rate(catalogue_http_requests_total{status=~"5.."}[5m]))
          / sum(rate(catalogue_http_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: warning
          service: catalogue
        annotations:
          summary: "High error rate on {{ $labels.service }}"
          description: "Error rate is {{ $value | humanizePercentage }}"

      # Database connection down
      - alert: DatabaseConnectionDown
        expr: catalogue_db_connection_status == 0
        for: 1m
        labels:
          severity: critical
          service: catalogue
        annotations:
          summary: "Database connection lost"
          description: "Catalogue service cannot connect to database"

      # Service dependency down
      - alert: ServiceDependencyDown
        expr: frontend_service_dependency_up == 0
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Service dependency is down"
          description: "{{ $labels.service }} is unreachable from frontend"

      # High latency
      - alert: HighLatency
        expr: |
          histogram_quantile(0.95,
            rate(catalogue_http_request_duration_seconds_bucket[5m])
          ) > 2
        for: 10m
        labels:
          severity: warning
          service: catalogue
        annotations:
          summary: "High latency detected"
          description: "95th percentile latency is {{ $value }}s"

      # JVM memory pressure
      - alert: HighJVMMemoryUsage
        expr: |
          (jvm_memory_used_bytes{application="voting-service",area="heap"}
          / jvm_memory_max_bytes{application="voting-service",area="heap"}) > 0.9
        for: 5m
        labels:
          severity: warning
          service: voting
        annotations:
          summary: "High JVM heap usage"
          description: "JVM heap usage is {{ $value | humanizePercentage }}"
```

---

## Best Practices

1. **Scrape Intervals**: Use 15-30 second intervals for application metrics
2. **Retention**: Configure Prometheus retention based on your needs (default 15 days)
3. **Cardinality**: Avoid high-cardinality labels (like user IDs) in metrics
4. **Dashboard Organization**: Create service-specific dashboards and an overview dashboard
5. **Alerting**: Set up alerts for critical metrics (error rates, latency, resource usage)
6. **Labels**: Use consistent label names across services
7. **Documentation**: Keep metric descriptions up to date

---

## Troubleshooting

### Metrics not appearing in Prometheus

1. Check service is running and healthy:
   ```bash
   curl http://<service>:<port>/health
   curl http://<service>:<port>/metrics
   ```

2. Verify Prometheus configuration:
   ```bash
   kubectl get servicemonitor -A
   ```

3. Check Prometheus targets:
   - Navigate to Prometheus UI → Status → Targets
   - Look for errors in target scraping

### Grafana not showing data

1. Verify Prometheus data source connection
2. Check query syntax in panel edit mode
3. Verify time range selection
4. Check Prometheus has data for the metric

### High cardinality warnings

- Review labels used in metrics
- Avoid using dynamic values (IDs, timestamps) as labels
- Use metric relabeling to drop unnecessary labels

---

## Summary

| Service | Endpoint | Port | Key Metrics |
|---------|----------|------|-------------|
| Catalogue | `/metrics` | 5000 | HTTP requests, DB status, Product count |
| Frontend | `/metrics` | 3000 | HTTP requests, Node.js metrics, Service health |
| Recommendation | `/metrics` | 8080 | HTTP requests, Recommendations served |
| Voting | `/actuator/prometheus` | 8080 | JVM metrics, HTTP requests, Database pool |

All services expose Prometheus-compatible metrics and can be monitored using Prometheus and visualized using Grafana dashboards.
