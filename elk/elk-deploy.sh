#!/usr/bin/env bash
set -euo pipefail

# 📄 Set env-specific filenames
ENV_FILE="elk/.env.elk"
DOCKER_FILE="elk/docker-compose.elk.yml"
SECURE_CONFIG_PATH="/tmp/elk-secure-config"
MODULES_SRC_PATH="elk/modules.d"
MODULES_TARGET_PATH="$SECURE_CONFIG_PATH/modules.d"


# 📦 Load environment variables
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Environment file '$ENV_FILE' not found"
  exit 1
fi

echo "📦 Loading environment variables from $ENV_FILE..."
export $(grep -v '^#' "$ENV_FILE" | xargs)

# 🧹 Clean and prepare secure config dir
echo "🧹 Resetting secure config path at $SECURE_CONFIG_PATH..."
sudo rm -rf "$SECURE_CONFIG_PATH"
mkdir -p "$SECURE_CONFIG_PATH"

# 🔐 Copy elk/config/*.yml
echo "🔐 Copying general *.yml configs..."
cp elk/config/*.yml "$SECURE_CONFIG_PATH"
sudo chown root:root "$SECURE_CONFIG_PATH"/*.yml
sudo chmod go-w "$SECURE_CONFIG_PATH"/*.yml

# 🔐 Copy metricbeat modules.d/*.yml if it exists
echo "🔐 Copying metricbeat modules.d config..."
mkdir -p "$MODULES_TARGET_PATH"
cp -r "$MODULES_SRC_PATH"/* "$MODULES_TARGET_PATH"
sudo chown -R root:root "$MODULES_TARGET_PATH"
sudo chmod -R go-w "$MODULES_TARGET_PATH"

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

