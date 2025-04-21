#!/usr/bin/env bash

# Requires env var: REDIS_URL
# Example: redis://redis:6379

redis_uri="${REDIS_URL#redis://}"
host=$(echo "$redis_uri" | cut -d ':' -f 1)
port=$(echo "$redis_uri" | cut -d ':' -f 2)

echo "🔍 Waiting for Redis $host:$port..."
until nc -z "$host" "$port"; do
  sleep 2
done
echo "✅ Redis is up at $host:$port"
