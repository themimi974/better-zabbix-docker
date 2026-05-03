# Better Zabbix Docker - Clustered HA Deployment

> High-Availability Docker Compose configuration for Zabbix monitoring system with Grafana dashboards

- [GitHub Repository](https://github.com/themimi974/better-zabbix-docker)
- [Official Zabbix Dockerfiles](https://github.com/zabbix/zabbix-docker)
- [Zabbix plugin for Grafana dashboard](https://github.com/grafana/grafana-zabbix)

![Architecture Scheme](./.images/scheme.excalidraw.png)

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Network: network-zabbix                          │
│                                                                     │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐          │
│  │ postgres-   │───│ postgres-   │   │ zabbix-     │          │
│  │ primary    │◄──│ replica    │   │ server-1    │          │
│  │   :5432   │   │   :5433   │   │   :10051   │          │
│  └──────────────┘   └──────────────┘   └──────┬───────┘          │
│                                              │                   │
│                                    ┌─────────┴─────────┐             │
│                                    │ zabbix-server-2 │             │
│                                    │ (passive)      │             │
│                                    │   :10052      │             │
│                                    └───────┬────────┘             │
│                                            │                     │
│      ┌───────────────────────────────────────┼───────────────┐      │
│      │                                       │               │      │
│      ▼                                       ▼               ▼      │
│  ┌──────────┐                           ┌──────────┐         │
│  │ frontend │                           │ grafana  │         │
│  │ :8080   │                           │ :3000   │         │
│  └──────────┘                           └──────────┘         │
└─────────────────────────────────────────────────────────────────────┘
```

### Components

| Component | Description | Ports |
|-----------|-------------|-------|
| `postgres-primary` | PostgreSQL 17 primary database | 5432 |
| `postgres-replica` | PostgreSQL read replica (streaming) | 5433 |
| `zabbix-server-1` | Zabbix Server (active/HA) | 10051 |
| `zabbix-server-2` | Zabbix Server (passive/HA) | 10052 |
| `zabbix-frontend` | Zabbix Web UI (Nginx + PHP) | 8080, 8443 |
| `zabbix-agent` | Zabbix Agent for cluster | 10050 |
| `grafana` | Grafana dashboards | 3000 |

### HA Features

- **PostgreSQL**: Streaming replication with hot standby
- **Zabbix Server**: Active/Passive HA with automatic failover
- **Failover Delay**: 10 seconds (configurable)

## Quick Start

### 1. Clone Repository

```shell
git clone https://github.com/themimi974/better-zabbix-docker.git
cd better-zabbix-docker
```

### 2. Configure Environment (Optional)

```shell
cp .env .env.local  # Optional: create local copy
nano .env           # Edit configuration
```

### 3. Start Services

```shell
docker compose up -d
```

> **Note**: On first start, PostgreSQL primary must be healthy before replica starts. This is expected behavior for replication setup.

⏱️ **First launch takes 2-3 minutes** while PostgreSQL initializes, replication syncs, and Zabbix servers start.

### 4. Verify Installation

```shell
docker compose ps
```

Expected output:
```
NAME                IMAGE                              STATUS
postgres-primary   postgres:17-alpine                Up (healthy)
postgres-replica  postgres:17-alpine                Up (healthy)
zabbix-server-1   zabbix/zabbix-server-pgsql:...    Up
zabbix-server-2   zabbix/zabbix-server-pgsql:...    Up
zabbix-frontend  zabbix/zabbix-web-nginx-pgsql:...  Up
zabbix-agent     zabbix/zabbix-agent2:...           Up
grafana          grafana/grafana:12.4.2           Up
```

### 5. Check HA Status

```shell
# Check Zabbix HA
docker compose exec zabbix-server-1 zabbix_ha_status

# Check PostgreSQL replication
docker compose exec postgres-replica psql -U zabbix -c "SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;"
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `zabbix` | PostgreSQL username |
| `POSTGRES_PASSWORD` | `zabbix` | PostgreSQL password |
| `POSTGRES_DB` | `zabbix` | Database name |
| `POSTGRES_REPLICA_USER` | `repl_user` | Replication user |
| `POSTGRES_REPLICA_PASSWORD` | `repl_password` | Replication password |
| `ZBX_SERVER_ID_1` | `1` | Server 1 ID |
| `ZBX_SERVER_ID_2` | `2` | Server 2 ID |
| `ZBX_ENABLEHA` | `1` | Enable HA mode |
| `ZBX_HA_FAILOVER_DELAY` | `10s` | Failover delay |
| `GRAFANA_USER` | `admin` | Grafana admin |
| `GRAFANA_SECRET` | `12345` | Grafana password |
| `TZ` | `Asia/Yekaterinburg` | Timezone |

> ⚠️ **Security Note**: Change default passwords in production!

## Services & Ports

| Service | Internal Port | External Port | URL |
|---------|---------------|---------------|-----|
| Zabbix Frontend | 8080 | 8080 | [http://localhost:8080](http://localhost:8080) |
| Zabbix Frontend SSL | 8443 | 8443 | https://localhost:8443 |
| Grafana | 3000 | 3000 | [http://localhost:3000](http://localhost:3000) |
| Zabbix Agent | 10050 | 10050 | (internal) |
| Zabbix Server-1 | 10051 | 10051 | (internal) |
| Zabbix Server-2 | 10052 | 10052 | (internal) |
| PostgreSQL Primary | 5432 | - | (internal only) |
| PostgreSQL Replica | 5433 | - | (internal only) |

## Usage

### Zabbix Web Interface

**URL:** [http://localhost:8080](http://localhost:8080)

**Default Credentials:**
- **Username:** `Admin`
- **Password:** `zabbix`

#### Configure Zabbix Agent Connection

1. Navigate to **Configuration** → **Hosts**
2. Click on **Zabbix server** host
3. Go to **Interfaces** tab
4. Change **Connect to** from IP to **DNS**
5. Set **DNS name** to `zabbix-agent`
6. **Update** the host

![Zabbix Agent Settings](./.images/zabbix-agent-settings.png)
![Zabbix Agent Check](./.images/zabbix-agent-check.png)

### Grafana Dashboard

**URL:** [http://localhost:3000](http://localhost:3000)

**Default Credentials:**
- **Username:** `admin`  
- **Password:** `12345`

> 💡 Anonymous access is enabled by default (see `grafana/grafana.ini`)

#### Test Zabbix Data Source

1. Go to **Connections** → **Data sources**
2. Select **Zabbix** data source
3. Click **Test** button
4. Should show "Data source is working"

![Data Source Test](./.images/data-source-test.png)

## Troubleshooting

### Check Service Logs

```shell
# All services
docker compose logs --tail=10 -f

# Specific service
docker compose logs -f zabbix-server-1
docker compose logs -f postgres-primary
```

### Check HA Status

```shell
# Zabbix HA
docker compose exec zabbix-server-1 zabbix_ha_status

# PostgreSQL replication lag
docker compose exec postgres-replica psql -U zabbix -c "SELECT * FROM pg_stat_replication;"
```

### Common Issues

#### 1. Replica Not Syncing

```shell
# Check replication status
docker compose logs postgres-replica

# Verify primary has replication user
docker compose exec postgres-primary psql -U zabbix -c "SELECT * FROM pg_replication_slots;"
```

#### 2. Zabbix HA Not Working

```shell
# Check both servers are running
docker compose ps

# Check HA status
docker compose exec zabbix-server-1 zabbix_ha_status

# Check logs
docker compose logs zabbix-server-1 zabbix-server-2
```

#### 3. Can't Access Web Interface

```shell
# Check if ports are available
netstat -tulpn | grep -E ':(8080|3000|10051)'

# Check container status
docker compose ps
```

## Failover Scenarios

| Scenario | Behavior |
|----------|----------|
| Active Zabbix Server fails | Passive takes over within 10s |
| Primary PostgreSQL fails | Manual failover required to replica |
| Frontend container fails | Restarted automatically |
| Host machine fails | All containers restart on healthy host |

## Performance Tuning

For better performance with large datasets:

```yaml
# Add to zabbix-server environment in compose.yaml
ZBX_CACHESIZE: "128M"
ZBX_CACHEUPDATEFREQUENCY: "60"
ZBX_STARTDBSYNCERS: "4"
```

## Security Considerations

### Production Deployment Checklist

- [ ] Change default passwords in `.env`
- [ ] Enable PostgreSQL TLS
- [ ] Use strong database passwords
- [ ] Restrict access to ports (use firewall/security groups)
- [ ] Enable HTTPS for Zabbix frontend
- [ ] Configure proper backup strategy
- [ ] Enable network policies for container isolation

## References

- [Zabbix HA Documentation](https://www.zabbix.com/documentation/current/manual/config/ha)
- [PostgreSQL Replication](https://www.postgresql.org/docs/current/static/high-availability.html)
- [Official Zabbix Docker Images](https://github.com/zabbix/zabbix-docker)
- [Zabbix Plugin for Grafana](https://github.com/grafana/grafana-zabbix)
- [Zabbix Documentation](https://www.zabbix.com/documentation/current/)
- [Grafana Documentation](https://grafana.com/docs/)