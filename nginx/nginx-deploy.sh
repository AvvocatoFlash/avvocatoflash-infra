#!/usr/bin/env bash
set -euo pipefail

# 📄 Set env-specific filenames
ENV_FILE="nginx/.env.nginx"
DOCKER_FILE="nginx/docker-compose.nginx.yml"

# 📦 Load environment variables
if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Environment file '$ENV_FILE' not found"
  exit 1
fi

echo "📦 Loading environment variables from $ENV_FILE..."
export $(grep -v '^#' "$ENV_FILE" | xargs)

# ✅ COMPOSE_PROJECT_NAME now available
echo "🔧 Project: ${COMPOSE_PROJECT_NAME}"
echo "🔧 Compose file: ${DOCKER_FILE}"

echo "🛠️  Environment variables:"
echo "   COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}"
echo "   FILES_PATH=${FILES_PATH:-<not set>}"

# 🧹 Clean previous containers/networks
echo "🧹 Cleaning up containers and networks for ${COMPOSE_PROJECT_NAME}..."
docker compose -f "$DOCKER_FILE" -p "$COMPOSE_PROJECT_NAME" down --remove-orphans

# 🚀 Build and launch services
echo "🚀 Starting services for nginx..."
docker compose -f "$DOCKER_FILE" -p "$COMPOSE_PROJECT_NAME" up -d --build

