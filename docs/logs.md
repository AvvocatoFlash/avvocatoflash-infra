# ELK Stack Configuration

## Components

- **Elasticsearch (v8.17.4)**: Search engine that stores logs
- **Kibana (v8.17.4)**: Visualization platform
- **Filebeat (v8.17.4)**: Log shipper for containers
- **Metricbeat (v8.17.4)**: System metrics collector
- **APM Server (v8.17.4)**: Application monitoring

## Docker Log Rotation

Configuration in `/etc/docker/daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
```

- **Limits each container log file to 100MB**
- **Keeps only 3 rotated files (300MB total per container)**
- **Prevents disk space from being filled by logs**
- **Requires Docker restart: `sudo systemctl restart docker`**


## Disk Space Issues
Check large files: `sudo find /var/lib/docker/containers -name "*-json.log" -exec ls -lh {} \; | sort -hr`

