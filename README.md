# 🏠 chaos-creation — Home Lab

Personal homelab running on a single Ubuntu machine using Docker, K3s (Lightweight Kubernetes) and Ansible for automation.

---

## 🖥️ Hardware

| Component | Details |
|---|---|
| **Hostname** | chaos-creation |
| **CPU** | AMD Ryzen 3 2200G (4 cores @ 3.5GHz) |
| **RAM** | 16GB DDR4 |
| **Disk** | 500GB HDD (457GB usable) |
| **GPU** | Radeon Vega 8 (integrated) |
| **OS** | Ubuntu 24.04.4 LTS |
| **Kernel** | 6.17.0-19-generic |


---

## 🏗️ Architecture

```
                         🌐 Home Network (192.168.0.x)
                                      │
                              ┌───────┴────────┐
                              │  chaos-creation │
                              │  192.168.0.112  │
                              └───────┬────────┘
                                      │
                    ┌─────────────────┴──────────────────┐
                    │                                    │
                 Docker                               K3s
                    │                                    │
              Portainer                    ┌─────────────┼──────────────┐
           (container UI)                  │             │              │
                                      Traefik      CoreDNS        Metrics
                                    (ingress)       (DNS)         Server
                                          │
                    ┌─────────────────────┼──────────────────────┐
                    │                     │                       │
              monitoring/           networking/               media/
                    │                     │                       │
           ┌────────┴────────┐        Pi-hole               Jellyfin
           │                 │
        Grafana          Prometheus
                        (+ Node Exporter
                         + State Metrics)

                    ┌─────────────────────┐
                    │        tools/        │
                    ├──────────────────────┤
                    │ Uptime Kuma          │
                    │ Stirling PDF         │
                    └──────────────────────┘

                    ┌─────────────────────┐
                    │      dashboard/      │
                    ├──────────────────────┤
                    │ Homepage             │
                    └──────────────────────┘
```

---

## 🌊 Traffic Flow

```
Browser Request (http://grafana.local)
        │
        ▼
/etc/hosts → resolves grafana.local to 192.168.0.112
        │
        ▼
Traefik (port 80) → running in K3s
        │
        ▼
IngressRoute → matches Host(grafana.local)
        │
        ▼
Grafana Service (ClusterIP: 10.43.148.37)
        │
        ▼
Grafana Pod → response served
```

---

## 📦 Stack

### Infrastructure
| Tool | Version | Purpose |
|---|---|---|
| Ubuntu | 24.04.4 LTS | Host OS |
| Docker | 29.3.0 | Container runtime |
| K3s | v1.34.5+k3s1 | Lightweight Kubernetes |
| Helm | v3.20.1 | K8s package manager |
| Ansible | 2.20.3 | Automation |
| Traefik | v3.6.9 | Ingress controller (built-in K3s) |

### Applications
| App | Namespace | URL | Purpose |
|---|---|---|---|
| Homepage | dashboard | http://home.local | Homelab dashboard |
| Grafana | monitoring | http://grafana.local | Metrics visualization |
| Prometheus | monitoring | http://prometheus.local | Metrics collection |
| Pi-hole | networking | http://pihole.local/admin | Network ad blocker |
| Jellyfin | media | http://jellyfin.local | Media server |
| Uptime Kuma | tools | http://uptime.local | Service uptime monitor |
| Stirling PDF | tools | http://pdf.local | Self-hosted PDF tools |
| Portainer | Docker | http://localhost:9000 | Container manager |

---

## 🔐 Credentials

> ⚠️ These credentials only work on the local network. All URLs are `.local` and not accessible from the internet.

| Service | Username | Password |
|---|---|---|
| Grafana | admin | homelab123 |
| Pi-hole | admin | *(set manually via UI)* |
| qBittorrent | admin | *(set manually via UI)* |
| Portainer | admin | *(set during first launch)* |
| Uptime Kuma | *(set during first launch)* | *(set during first launch)* |

---

## 📁 Directory Structure

```
~/homelab/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   └── hosts.ini            # Target hosts (localhost)
├── playbooks/
│   ├── 01_install_docker.yml
│   ├── 02_install_k3s.yml
│   ├── 03_setup_repos.yml
│   ├── 04_deploy_monitoring.yml
│   ├── 05_deploy_pihole.yml
│   ├── 06_deploy_jellyfin.yml
│   ├── 07_deploy_uptimekuma.yml
│   ├── 08_deploy_stirlingpdf.yml
│   ├── 09_deploy_homepage.yml
│   ├── 10_deploy_portainer.yml
│   ├── start_mediastack.yml  # Spin up temp download stack
│   └── stop_mediastack.yml   # Tear down temp download stack
└── .gitignore

/mnt/
├── media/
│   ├── movies/              # Jellyfin movies library
│   ├── tvshows/             # Jellyfin TV library
│   ├── music/               # Jellyfin music library
│   └── downloads/           # Temp download folder
├── homepage/                # Homepage config
│   ├── services.yaml
│   ├── settings.yaml
│   ├── bookmarks.yaml
│   └── widgets.yaml
├── jellyfin/
│   └── config/              # Jellyfin config
├── uptimekuma/              # Uptime Kuma data
└── config/                  # Media stack configs
    ├── radarr/
    ├── prowlarr/
    └── qbittorrent/
```

---

## 🚀 Deployment Order

Fresh Ubuntu install to full homelab:

```bash
# 1. System prep (curl, git, pip3)
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git vim htop python3 python3-pip

# 2. Install Ansible
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.general
pip3 install kubernetes --break-system-packages

# 3. Run playbooks in order
cd ~/homelab/playbooks
ansible-playbook -i ~/homelab/inventory/hosts.ini 01_install_docker.yml --ask-become-pass
ansible-playbook -i ~/homelab/inventory/hosts.ini 02_install_k3s.yml --ask-become-pass
ansible-playbook -i ~/homelab/inventory/hosts.ini 03_setup_repos.yml --ask-become-pass
ansible-playbook -i ~/homelab/inventory/hosts.ini 04_deploy_monitoring.yml --ask-become-pass
ansible-playbook -i ~/homelab/inventory/hosts.ini 05_deploy_pihole.yml --ask-become-pass
ansible-playbook -i ~/homelab/inventory/hosts.ini 06_deploy_jellyfin.yml --ask-become-pass
ansible-playbook -i ~/homelab/inventory/hosts.ini 07_deploy_uptimekuma.yml --ask-become-pass
ansible-playbook -i ~/homelab/inventory/hosts.ini 08_deploy_stirlingpdf.yml --ask-become-pass
ansible-playbook -i ~/homelab/inventory/hosts.ini 09_deploy_homepage.yml --ask-become-pass
ansible-playbook -i ~/homelab/inventory/hosts.ini 10_deploy_portainer.yml --ask-become-pass
```

---

## 🎬 Temp Media Download Stack

Spin up on demand, tear down when done:

```bash
# Start stack (Radarr + Prowlarr + qBittorrent)
ansible-playbook -i ~/homelab/inventory/hosts.ini playbooks/start_mediastack.yml --ask-become-pass

# URLs while running:
# http://radarr.local
# http://prowlarr.local
# http://qbit.local

# Stop and remove when done
ansible-playbook -i ~/homelab/inventory/hosts.ini playbooks/stop_mediastack.yml --ask-become-pass
```

Media files in `/mnt/media/` are never deleted by the stop playbook.

---

## 🔧 Useful Commands

```bash
# Check all running pods
kubectl get pods -A

# Check all services
kubectl get svc -A

# Watch pods in real time
kubectl get pods -A -w

# Check logs for a pod
kubectl logs -n <namespace> <pod-name>

# Restart a deployment
kubectl rollout restart deployment <name> -n <namespace>

# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods -A

# Helm releases
helm list -A
```

---

## 📊 Grafana Dashboards

| Dashboard | ID | Purpose |
|---|---|---|
| Node Exporter Full | 1860 | CPU, RAM, Disk, Network |
| K3s Cluster Monitoring | 15759 | K3s pods, namespaces |

---

## 🌐 Pi-hole Network Setup

Pi-hole is configured as the primary DNS for the entire home network:

```
Router DNS Settings:
Primary DNS:   192.168.0.112   ← Pi-hole
Secondary DNS: 8.8.8.8          ← Google fallback
```

If Pi-hole goes down, traffic automatically falls back to Google DNS — internet never stops working.

---

## ⚠️ What's Missing / Next Steps

### Security
- [ ] **SSL certificates** — currently all services run on HTTP. Add cert-manager + Let's Encrypt for HTTPS
- [ ] **Ansible Vault** — encrypt credentials in playbooks instead of plaintext
- [ ] **Firewall rules** — configure UFW to restrict access to services
- [ ] **Fail2ban** — protect against brute force attacks
- [ ] **Portainer** — currently accessible without HTTPS on port 9000

### Access & Networking
- [ ] **Tailscale/WireGuard VPN** — access homelab securely from anywhere
- [ ] **Static IP** — assign a static IP to chaos-creation so Pi-hole DNS never breaks
- [ ] **Custom domain** — use a real domain with Cloudflare for remote access
- [ ] **IPv6** — currently not configured

### Services
- [ ] **Nextcloud** — self-hosted personal cloud (file sync, photos, calendar)
- [ ] **Vaultwarden** — self-hosted Bitwarden password manager
- [ ] **Gitea** — self-hosted Git server
- [ ] **Nginx Proxy Manager** — easier reverse proxy management with UI
- [ ] **Watchtower** — auto update Docker containers
- [ ] **Heimdall** — alternative dashboard

### Monitoring
- [ ] **Grafana alerting** — get notified when CPU/RAM spikes or pods go down
- [ ] **Prometheus retention** — increase beyond default 15 days
- [ ] **Loki + Promtail** — centralized log aggregation
- [ ] **Alert routing** — send alerts to Telegram or email

### Reliability
- [ ] **ClamAV scheduled scan** — auto scan /mnt/media/ weekly
- [ ] **Automated backups** — backup configs to external drive or cloud
- [ ] **UPS** — uninterruptible power supply to prevent data corruption on power cuts
- [ ] **SMART monitoring** — monitor disk health

### Hardware Upgrades (Future)
- [ ] **More RAM** — 32GB would allow more VMs
- [ ] **SSD** — faster disk I/O for K3s and databases
- [ ] **Second disk** — separate OS disk from media storage
- [ ] **Network switch** — for multi-device wired connections

---

## 📚 Resources

| Resource | URL |
|---|---|
| K3s Docs | https://docs.k3s.io |
| Ansible Docs | https://docs.ansible.com |
| Helm Docs | https://helm.sh/docs |
| Traefik Docs | https://doc.traefik.io/traefik |
| Jellyfin Docs | https://jellyfin.org/docs |
| Pi-hole Docs | https://docs.pi-hole.net |
| Homepage Docs | https://gethomepage.dev |

---

*Built on chaos-creation — because every homelab needs a dramatic name* 🚀
