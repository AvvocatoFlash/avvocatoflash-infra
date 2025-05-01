#!/usr/bin/env bash
set -euo pipefail

# 📄 Set env-specific filenames
ENV_FILE="elk/.env.elk"
DOCKER_FILE="elk/docker-compose.elk.yml"
SECURE_CONFIG_PATH="/tmp/elk-secure-config"

# 📦 Load environment variables
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Environment file '$ENV_FILE' not found"
  exit 1
fi

echo "📦 Loading environment variables from $ENV_FILE..."
export $(grep -v '^#' "$ENV_FILE" | xargs)

# 🧹 Clean old root-owned temp configs
echo "🧹 Cleaning up old secure config..."
sudo rm -rf "$SECURE_CONFIG_PATH"
mkdir -p "$SECURE_CONFIG_PATH"
cp elk/config/*.yml "$SECURE_CONFIG_PATH"
sudo chown root:root "$SECURE_CONFIG_PATH"/*.yml
sudo chmod go-w "$SECURE_CONFIG_PATH"/*.yml


# ✅ COMPOSE_PROJECT_NAME now available
echo "🔧 Project: ${COMPOSE_PROJECT_NAME}"
echo "🔧 Compose file: ${DOCKER_FILE}"


echo "🛠️  Environment variables:"
echo "   COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-<not set>}"
echo "   ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-<not set>}"
echo "   KIBANA_SYSTEM_PASSWORD=${KIBANA_SYSTEM_PASSWORD:-<not set>}"

# 🧹 Clean previous containers/networks
echo "🧹 Cleaning up containers and networks for ${COMPOSE_PROJECT_NAME}..."
docker compose -f "$DOCKER_FILE" -p "$COMPOSE_PROJECT_NAME" down --remove-orphans

# 🚀 Build and launch services
echo "🚀 Starting services for elastic search..."
docker compose -f "$DOCKER_FILE" -p "$COMPOSE_PROJECT_NAME" up -d --build

