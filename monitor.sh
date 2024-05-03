#!/bin/bash

# Function to log messages with timestamps to stdout
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Function to get the list of nodes with specific taints
get_nodes_with_specific_taints() {
  kubectl get nodes -o json | jq -r \
    '.items[] | select(.spec.taints != null) | select(.spec.taints[] | select(.key == "node.kubernetes.io/unreachable" and (.effect == "NoExecute" or .effect == "NoSchedule"))) | .metadata.name' \
    | sort | uniq
}

# Function to add a taint to a node
add_taint() {
  local node=$1
  local taint=$2
  log "Adding taint '$taint' to node '$node'"
  kubectl taint nodes "$node" "$taint"
}

# Function to remove a taint from a node
remove_taint() {
  local node=$1
  local taint=$2
  log "Removing taint '$taint' from node '$node'"
  kubectl taint nodes "$node" "$taint-"
}

while true; do
  # Get nodes that are unreachable
  unreachable_nodes=$(get_nodes_with_specific_taints)
  log "Unreachable nodes: $unreachable_nodes"

  for node in $unreachable_nodes; do
    log "Processing unreachable node: $node"
    add_taint "$node" "node.kubernetes.io/out-of-service=nodeshutdown:NoExecute"
    add_taint "$node" "node.kubernetes.io/out-of-service=nodeshutdown:NoSchedule"
  done

  # Get all nodes
  all_nodes=$(kubectl get nodes -o json | jq -r '.items[].metadata.name')

  for node in $all_nodes; do
    if [[ ! " $unreachable_nodes " =~ " $node " ]]; then
      log "Processing reachable node: $node"
      remove_taint "$node" "node.kubernetes.io/out-of-service=nodeshutdown:NoExecute"
      remove_taint "$node" "node.kubernetes.io/out-of-service=nodeshutdown:NoSchedule"
    fi
  done

  # Wait for a while before the next check
  log "Waiting for the next cycle"
  sleep 10
done
