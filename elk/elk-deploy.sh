#!/usr/bin/env bash
set -euo pipefail

# 📄 Set env-specific filenames
ENV_FILE="elk/.env.elk"
DOCKER_FILE="elk/docker-compose.elk.yml"
SECURE_CONFIG_PATH="/tmp-config/elk-secure-config"
MODULES_PATH="/tmp-modules/modules.d"

# 📦 Load environment variables
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Environment file '$ENV_FILE' not found"
  exit 1
fi

echo "📦 Loading environment variables from $ENV_FILE..."
export $(grep -v '^#' "$ENV_FILE" | xargs)

# 🔐 Secure elk/config/*.yml
echo "🧹 Cleaning up old secure config..."
sudo rm -rf "$SECURE_CONFIG_PATH"
mkdir -p "$SECURE_CONFIG_PATH"
cp elk/config/*.yml "$SECURE_CONFIG_PATH"
sudo chown root:root "$SECURE_CONFIG_PATH"/*.yml
sudo chmod go-w "$SECURE_CONFIG_PATH"/*.yml

# 🔐 Secure metricbeat modules.d config
echo "🧹 Cleaning and preparing secure modules.d config..."
sudo rm -rf "$MODULES_PATH"
mkdir -p "$MODULES_PATH"
cp -r elk/modules.d/* "$MODULES_PATH"
sudo chown -R root:root "$MODULES_PATH"
sudo chmod -R go-w "$MODULES_PATH"


# ✅ COMPOSE_PROJECT_NAME now available
echo "🔧 Project: ${COMPOSE_PROJECT_NAME}"
echo "🔧 Compose file: ${DOCKER_FILE}"


echo "🛠️  Environment variables:"
echo "   COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-<not set>}"

# 🧹 Clean previous containers/networks
echo "🧹 Cleaning up containers and networks for ${COMPOSE_PROJECT_NAME}..."
docker compose -f "$DOCKER_FILE" -p "$COMPOSE_PROJECT_NAME" down --remove-orphans

# 🚀 Build and launch services
echo "🚀 Starting services for elastic search..."
docker compose -f "$DOCKER_FILE" -p "$COMPOSE_PROJECT_NAME" up -d --build

