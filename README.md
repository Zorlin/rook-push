# rook push
`tl;dr:` This is a simple set of tools that allows you to automatically mark Kubernetes nodes as "out of service" when they are unreachable and "in service" when they are reachable again.

Kubernetes does this automatically, but Rook is conservative (depending on your use case, this is a good thing or a bad thing) and will not mark a node as "out of service" until it has been unreachable for a long period of time. This can be a problem if you have a service that can only run on a single node at a time, but must stay online most of the time. By managing the taints on a node, we can encourage Rook to evacuate dead or offline nodes faster, while still preserving safe Kubernetes behaviours.

Thus, Rook Push is a hack that runs as a persistent Kubernetes daemon (running in a container) which will use the Kubernetes API to check if a node has the usual taints that indicate an out of service node, and if so, simply adds the appropriate taints for Rook to begin evacuating it.

## Usage
Open `node-evictor.yaml` and edit this section to reflect your Kubernetes cluster:
```
          env:
            - name: KUBERNETES_SERVICE_HOST
              value: "opal.riff.cc"
```

Then, apply the configuration to your cluster:
```
kubectl apply -f node-evictor.yaml
```

## How it works
The node-evictor will check the Kubernetes API every 10 seconds to see if any nodes are unreachable. If they are, it will wait 20 seconds, then add the `rook.io/unschedulable` taint to the node, which will cause Rook to begin evacuating PVCs from it.

This will allow PVCs that would normally end up stuck on a dead node to be moved to a live node, and thus the workloads associated with them to restart naturally.