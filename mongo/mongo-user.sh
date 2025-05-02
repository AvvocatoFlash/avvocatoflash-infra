#!/usr/bin/env bash
# mongo-user.sh
# Create a MongoDB user with specified permissions on a database within a replica set,
# generate a secure random password, and print a connection URI.
set -euo pipefail

# 📄 Env file
ENV_FILE="mongo/.env.mongo"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Environment file '$ENV_FILE' not found"
  exit 1
fi

# 📦 Load environment variables (ignore comments)
export $(grep -v '^#' "$ENV_FILE" | xargs)

# ⚙️ Replica set hosts (override via env if needed)
REPLICA_HOSTS="${REPLICA_HOSTS:-mongo1:27017,mongo2:27018,mongo3:27019}"

usage() {
  echo "Usage: $0 -u <username> -d <database> -p <permissions>"
  echo "  -u  Username to create"
  echo "  -d  Target database name"
  echo "  -p  Permissions: read, write, or read:write"
  exit 1
}

# Parse arguments
USER=""
DB=""
PERM=""
while getopts "u:d:p:" opt; do
  case $opt in
    u) USER="$OPTARG" ;;
    d) DB="$OPTARG" ;;
    p) PERM="$OPTARG" ;;
    *) usage ;;
  esac
done

[[ -z "$USER" || -z "$DB" || -z "$PERM" ]] && usage

# Determine roles
if [[ "$PERM" == "metricbeat" ]]; then
  ROLES="[
    { role: 'clusterMonitor', db: 'admin' },
    { role: 'read', db: 'local' }
  ]"
elif [[ "$PERM" == "read" ]]; then
  ROLES="[{ role: 'read', db: '$DB' }]"
elif [[ "$PERM" == "write" || "$PERM" == "read:write" ]]; then
  ROLES="[{ role: 'readWrite', db: '$DB' }]"
else
  echo "Invalid permissions '$PERM'. Must be 'read', 'write', or 'read:write'."
  exit 1
fi

# 🔑 Generate a secure random password
PWD=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 32)

# 🕸 Build connection URI for the root user
ROOT_URI="mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@${REPLICA_HOSTS}/admin?replicaSet=${MONGO_REPLICA_SET_NAME}&authSource=admin"

# 🛠 Create the user via full URI (no --host/--port flags)
mongosh "$ROOT_URI" --quiet --eval \
  "db.getSiblingDB('$DB').createUser({ user: '$USER', pwd: '$PWD', roles: $ROLES });"

# ✅ Done!
echo "User '$USER' created on database '$DB' with permissions '$PERM'."

# 🔗 App connection URI
echo "Connection URI for '$USER':"
echo "Password for '$PWD':"
echo "mongodb://${USER}:${PWD}@${REPLICA_HOSTS}/${DB}?replicaSet=${MONGO_REPLICA_SET_NAME}&authSource=${DB}"
