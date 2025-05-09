#!/usr/bin/env bash
set -euo pipefail

# 📄 Set env-specific filenames
ENV_FILE="elk/.env.elk"
DOCKER_FILE="elk/docker-compose.elk.yml"
SECURE_CONFIG_PATH="/etc/elk-secure-config"
MODULES_SRC_PATH="elk/modules.d"
MODULES_TARGET_PATH="$SECURE_CONFIG_PATH/modules.d"


# 📦 Load environment variables
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Environment file '$ENV_FILE' not found"
  exit 1
fi

echo "📦 Loading environment variables from $ENV_FILE..."
export $(grep -v '^#' "$ENV_FILE" | xargs)

# 📂 Prepare secure config dir (without completely deleting)
echo "📂 Preparing secure config path at $SECURE_CONFIG_PATH..."
# Create directories if they don't exist
sudo mkdir -p "$SECURE_CONFIG_PATH"
sudo mkdir -p "$MODULES_TARGET_PATH"

# 🧹 Only remove specific module files we want to update
echo "🧹 Removing specific module files to update..."
if [ -f "$MODULES_TARGET_PATH/docker.yml" ]; then
  sudo rm -f "$MODULES_TARGET_PATH/docker.yml"
  echo "  - Removed docker.yml for update"
fi

if [ -f "$MODULES_TARGET_PATH/mongodb.yml" ]; then
  sudo rm -f "$MODULES_TARGET_PATH/mongodb.yml"
  echo "  - Removed mongodb.yml for update"
fi

# 🔐 Copy or update general config files
echo "🔐 Updating general *.yml configs..."
sudo cp elk/config/*.yml "$SECURE_CONFIG_PATH"

# 🔐 Copy metricbeat modules.d/*.yml
echo "🔐 Updating metricbeat modules.d config..."
sudo cp -f "$MODULES_SRC_PATH/docker.yml" "$MODULES_TARGET_PATH/docker.yml"
sudo cp -f "$MODULES_SRC_PATH/mongodb.yml" "$MODULES_TARGET_PATH/mongodb.yml"

# 🔐 Ensure proper permissions
sudo chown root:root "$SECURE_CONFIG_PATH"/*.yml
sudo chmod go-w "$SECURE_CONFIG_PATH"/*.yml
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

