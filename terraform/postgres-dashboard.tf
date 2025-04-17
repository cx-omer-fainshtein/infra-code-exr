resource "grafana_dashboard" "postgres_dashboard" {
  config_json = jsonencode({
    title  = "PostgreSQL Metrics"
    tags   = ["postgres", "metrics"]
    panels = [
      {
        title = "PostgreSQL CPU Usage"
        type  = "graph"
        gridPos = { h = 8, w = 12, x = 0, y = 0 }
        targets = [{
          expr = "rate(process_cpu_seconds_total{job=\"postgresql\"}[5m])"
          legendFormat = "CPU"
        }]
      },
      {
        title = "Memory Usage"
        type  = "graph"
        gridPos = { h = 8, w = 12, x = 12, y = 0 }
        targets = [{
          expr = "process_resident_memory_bytes{job=\"postgresql\"}"
          legendFormat = "Memory"
        }]
      },
      {
        title = "Throughput"
        type  = "graph"
        gridPos = { h = 8, w = 24, x = 0, y = 8 }
        targets = [{
          expr = "rate(pg_stat_database_blks_hit{job=\"postgresql\"}[5m])"
          legendFormat = "Throughput"
        }]
      }
    ]
  })
}
