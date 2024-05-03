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

# Function to check if a node has a specific taint
has_taint() {
  local node=$1
  local key=$2
  local effect=$3
  kubectl get node "$node" -o json | jq -e --arg key "$key" --arg effect "$effect" \
    '.spec.taints // [] | any(.key == $key and .effect == $effect)' > /dev/null
}

# Function to add a taint to a node
add_taint() {
  local node=$1
  local key=$2
  local effect=$3

  if ! has_taint "$node" "node.kubernetes.io/out-of-service" "$effect"; then
    log "Adding taint '$key:$effect' to node '$node'"
    log 'kubectl taint nodes "$node" "$key:$effect"'
    kubectl taint nodes "$node" "$key:$effect"
  else
    log "Node '$node' already has taint '$key-$effect'"
  fi
}


# Function to remove a taint from a node
remove_taint() {
  local node=$1
  local key=$2
  local effect=$3
  if has_taint "$node" "$key" "$effect"; then
    log "Removing taint '$key:$effect' from node '$node'"
    kubectl taint nodes "$node" "$key:$effect-"
  fi
}

while true; do
  # Get nodes that are unreachable
  unreachable_nodes=$(get_nodes_with_specific_taints)
  log "Unreachable nodes: $unreachable_nodes"

  for node in $unreachable_nodes; do
    log "Processing unreachable node: $node"
    sleep 20
    add_taint "$node" "node.kubernetes.io/out-of-service=nodeshutdown" "NoExecute"
    add_taint "$node" "node.kubernetes.io/out-of-service=nodeshutdown" "NoSchedule"
  done

  # Get all nodes
  all_nodes=$(kubectl get nodes -o json | jq -r '.items[].metadata.name')

  for node in $all_nodes; do
    if [[ ! " $unreachable_nodes " =~ " $node " ]]; then
      log "Processing reachable node: $node"
      remove_taint "$node" "node.kubernetes.io/out-of-service" "NoExecute"
      remove_taint "$node" "node.kubernetes.io/out-of-service" "NoSchedule"
    fi
  done

  # Wait for a while before the next check
  log "Waiting for the next cycle"
  sleep 10
done
