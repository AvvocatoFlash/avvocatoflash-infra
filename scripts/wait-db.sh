#!/usr/bin/env bash

# Requires env var: MONGODB_URI
# Example: mongodb://mongo1:27017,mongo2:27017,mongo3:27017/db?replicaSet=rs0

replica_uri="${MONGODB_URI#mongodb://}"
replica_uri="${replica_uri%%/*}"  # Trim off after first slash

IFS=',' read -ra HOSTS <<< "$replica_uri"

for hostport in "${HOSTS[@]}"; do
  host=$(echo "$hostport" | cut -d ':' -f 1)
  port=$(echo "$hostport" | cut -d ':' -f 2)
  echo "🔍 Waiting for MongoDB node $host:$port..."
  until nc -z "$host" "$port"; do
    sleep 2
  done
  echo "✅ $host:$port is up"
done
