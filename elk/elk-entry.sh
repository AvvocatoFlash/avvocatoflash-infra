#!/bin/bash
set -e

# 1) Start Elasticsearch in the background
bash /usr/local/bin/docker-entrypoint.sh &

# 2) Wait until ES is online
until curl -s -u elastic:"${ELASTIC_PASSWORD}" http://localhost:9200 \
      | grep -q "You Know, for Search"; do
  echo "Still waiting for Elasticsearch…"
  sleep 5
done
echo "✅ Elasticsearch is up!"

# 3) Check for our “once‑and‑done” marker: the custom_monitoring_role role
HTTP_CODE=$(
  curl -s -o /dev/null -w "%{http_code}" \
    -u elastic:"${ELASTIC_PASSWORD}" \
    -X GET http://localhost:9200/_security/role/custom_monitoring_role
)
if [ "$HTTP_CODE" -eq 200 ]; then
  echo "⚡️ Security already initialized—skipping user & role setup."
else
  echo "🚀 Bootstrapping security for the first time…"

  # 4) Reset kibana_system password
  echo "🔐 Resetting kibana_system password…"
  curl -s -u elastic:"${ELASTIC_PASSWORD}" \
       -H "Content-Type: application/json" \
       -X POST http://localhost:9200/_security/user/kibana_system/_password \
       -d '{"password":"'"${KIBANA_SYSTEM_PASSWORD}"'"}'

  # 5) Create your custom monitoring & logs roles
  echo "🔧 Creating custom_monitoring_role…"
  curl -s -u elastic:"${ELASTIC_PASSWORD}" -X PUT \
       http://localhost:9200/_security/role/custom_monitoring_role \
       -H "Content-Type: application/json" -d '{
         "cluster":["monitor","monitor_watcher"],
         "indices":[{"names":[".monitoring-*",".kibana*","metricbeat-*","filebeat-*","logs-*"],"privileges":["read","view_index_metadata"]}]
       }'

#  echo "🔧 Creating logs_viewer_role…"
#  curl -s -u elastic:"${ELASTIC_PASSWORD}" -X PUT \
#       http://localhost:9200/_security/role/logs_viewer_role \
#       -H "Content-Type: application/json" -d '{
#         "cluster":["monitor"],
#         "indices":[{"names":["logs-*",".logs-*",".kibana*"],"privileges":["read","view_index_metadata"]}]
#       }'

#  # 6) Create kibana_admin user
#  echo "👤 Creating kibana_admin user…"
#  curl -s -u elastic:"${ELASTIC_PASSWORD}" -X POST \
#       http://localhost:9200/_security/user/kibana_admin \
#       -H "Content-Type: application/json" -d '{
#         "password":"'"${KIBANA_SYSTEM_PASSWORD}"'",
#         "roles":["superuser","custom_monitoring_role","logs_viewer_role"],
#         "full_name":"Kibana Admin",
#         "email":"admin@example.com"
#       }'

#  # 7) Create non‑reserved kibana_log_writer & assign it
#  echo "📝 Creating kibana_log_writer role…"
#  curl -s -u elastic:"${ELASTIC_PASSWORD}" -X PUT \
#       http://localhost:9200/_security/role/kibana_log_writer \
#       -H "Content-Type: application/json" -d '{
#         "cluster":[],
#         "indices":[{"names":["node-logs*"],"privileges":["create_index","create","write"]}]
#       }'
#  echo "🔗 Granting kibana_log_writer to kibana_admin…"
#  curl -s -u elastic:"${ELASTIC_PASSWORD}" -X POST \
#       http://localhost:9200/_security/user/kibana_admin \
#       -H "Content-Type: application/json" -d '{
#         "roles":["superuser","custom_monitoring_role","logs_viewer_role","kibana_log_writer"]
#       }'

  echo "✅ Security bootstrap complete."
#fi

# 8) Wait on Elasticsearch process so container doesn’t exit
wait -n
