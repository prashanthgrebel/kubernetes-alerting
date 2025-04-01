# Test alerting 

```bash
kubectl run cpu-test --image=busybox --restart=Never --command -- sh -c "while true; do :; done"
kubectl run memory-test --image=busybox --restart=Never --command -- sh -c "dd if=/dev/zero of=/dev/null bs=1M"
```
