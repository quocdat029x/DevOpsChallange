### Troubleshooting High Memory Usage on an Ubuntu VM Running NGINX


---

## Initial Assessment and Data Collection

Go through all these steps to collect the informations.

1. **Check Memory Usage**:
    - Run `free -h` to display total, used, and free memory in a human-readable format. This confirms the 99% memory usage reported by monitoring tools.

2. **Identify Processes**:
    - Use `htop` to list running processes sorted by memory consumption. Filter the NGINX process since it is the only service running.

3. **Review NGINX Configuration**:
    - Take a look at `/etc/nginx/nginx.conf` to understand settings like worker processes, connections, and caching that might influence memory usage.

---

## Possible Root Causes


### 1. NGINX Worker Processes Configuration (highly possible)
- **Scenario**: NGINX may be configured with too many worker processes or connections, consuming excessive memory.
- **Impact**: High memory usage can make the VM unresponsive, causing service downtime or degraded performance for upstream traffic.
- **Recovery Steps**:
    1. Open `/etc/nginx/nginx.conf` and adjust `worker_processes` to match the number of CPU cores (e.g., `worker_processes auto;` or a specific number like `2`).
    2. Tune `worker_connections` (inside the `events` block) to a reasonable value based on traffic load (e.g., `worker_connections 1024;`).
    3. Restart NGINX with `sudo systemctl restart nginx` to apply changes.
    4. Monitor memory usage with `free -h` or `top` to confirm improvement.

### 2. Memory Leak in NGINX or Plugins (less possible)
- **Scenario**: A bug in NGINX or a loaded module might cause a memory leak, leading to gradual memory exhaustion.
- **Impact**: Memory usage increases over time, risking out-of-memory (OOM) errors and service crashes.
- **Recovery Steps**:
    1. Check the NGINX version with `nginx -v` and update to the latest stable version using `sudo apt update && sudo apt upgrade nginx`.
    2. Review loaded modules in `nginx.conf` and disable unnecessary ones by commenting out `load_module` directives.
    3. Restart NGINX (`sudo systemctl restart nginx`) and monitor memory trends with `htop` to verify the leak is resolved.

### 3. Large Access or Error Logs (less possible)
- **Scenario**: Unmanaged NGINX logs (e.g., `access.log` or `error.log`) may grow excessively, consuming memory when accessed.
- **Impact**: Large logs can fill disk space and increase memory usage during log operations, slowing down NGINX.
- **Recovery Steps**:
    1. Check log sizes with `ls -lh /var/log/nginx/`.
    2. Configure log rotation by editing `/etc/logrotate.d/nginx` (e.g., set `daily`, `rotate 7`, and `compress`).
    3. Manually archive or delete old logs (e.g., `sudo mv /var/log/nginx/access.log /var/log/nginx/access.log.old` and `sudo truncate -s 0 /var/log/nginx/access.log`).
    4. Reload NGINX with `sudo systemctl reload nginx`.

### 4. Upstream Service Issues (slightly possible)
- **Scenario**: Slow or unresponsive upstream services might force NGINX to keep connections open longer, increasing memory usage.
- **Impact**: A backlog of connections degrades performance and risks overwhelming the load balancer.
- **Recovery Steps**:
    1. Test upstream health with `curl -I http://upstream-server` or similar tools.
    2. Adjust NGINX timeouts in `nginx.conf` (e.g., `proxy_read_timeout 10s;`, `proxy_connect_timeout 5s;`) to drop slow connections.
    3. Add or optimize health checks (e.g., `upstream backend { server 192.168.1.10; check interval=3000 rise=2 fall=3 timeout=1000; }`) if using a module like `nginx_upstream_check_module`.
    4. Restart NGINX (`sudo systemctl restart nginx`) and verify memory usage drops.

### 5. Caching Configuration (highly possible)
- **Scenario**: If NGINX caching is enabled, an oversized or misconfigured cache might consume excessive memory.
- **Impact**: Large cache sizes reduce available memory, impacting overall system performance.
- **Recovery Steps**:
    1. Review cache settings in `nginx.conf` (e.g., `proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=1g;`).
    2. Reduce `max_size` or clear the cache with `rm -rf /var/cache/nginx/*`.
    3. Set appropriate expiration times or disable caching (`proxy_cache off;`) if unnecessary.
    4. Reload NGINX (`sudo systemctl reload nginx`) and check memory with `free -h`.

### 6. System-Level Issues
- **Scenario**: Non-NGINX processes or services might be running on the VM, consuming memory unexpectedly.
- **Impact**: Resource contention reduces memory available for NGINX, affecting load balancing performance.
- **Recovery Steps**:
    1. Use htop and sort the memory usage for informations
    2. Stop unnecessary services (e.g., `kill -9 <service-name>`). Try to avoid not killing the system services.
    3. Keep monitoring on investigation
