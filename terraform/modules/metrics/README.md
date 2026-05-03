
**Metrics Source:** Metrics Server (installed via `monitoring` module)

**Testing:**
```bash
# Check HPA status
kubectl get hpa -n nginx

# Watch pods scaling
kubectl get pods -n nginx -w

# Load test (generate CPU load)
kubectl run -it --rm load-generator --image=busybox /bin/sh
# Then inside:
# > while sleep 0.01; do wget -q -O- http://nginx:80; done
```
