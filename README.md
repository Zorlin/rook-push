# rook push
`tl;dr:` This is a simple set of tools that allows you to automatically mark Kubernetes nodes as "out of service" when they are unreachable and "in service" when they are reachable again.

Kubernetes does this automatically, but Rook is conservative (depending on your use case, this is a good thing or a bad thing) and will not mark a node as "out of service" until it has been unreachable for a long period of time. This can be a problem if you have a service that can only run on a single node at a time, but must stay online most of the time. By managing the taints on a node, we can encourage Rook to evacuate dead or offline nodes faster, while still preserving safe Kubernetes behaviours.

Thus, Rook Push is a hack that runs as a persistent Kubernetes daemon (running in a container) which will use the Kubernetes API to check if a node has the usual taints that indicate an out of service node, and if so, simply adds the appropriate taints for Rook to begin evacuating it.