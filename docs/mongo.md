# 🔐 MongoDB Setup for AvvocatoFlash

This guide shows how to stand up a secure, authenticated MongoDB replica set in Docker.

---

## 📁 Directory Structure

```bash
/srv/
├── data/
│   ├── mongodb/
│   ├──── mongo1/
│   └──── mongo2/
│   └──── mongo3/
├── logs/
│   ├── mongodb/
│   ├──── mongo1/
│   └──── mongo2/
│   └──── mongo3/
├── infra/
│   └── mongo/docker-compose.yml
```

---

## 🗝️ Generate & Secure `file.key`

```bash
cd ~/srv/infra/mongo
openssl rand -base64 700 > file.key
chmod 400 file.key
ls -l file.key
# -r-------- 1 youruser staff 1024 Apr 22 13:00 file.key
```

---

## 📦 Environment Variables (`.env.mongo`)

Create `~/srv/infra/mongo/.env.mongo`:
```env
# Root user credentials
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=secureRootPwd
MONGO_REPLICA_SET_NAME=rs0
```

---

## 🛠 Connecting

Without authentication (pre-init):
`mongodb://mongo1:27017,mongo2:27018,mongo3:27019/?replicaSet=rs0`

With authentication (post-init):
`mongodb://root:password@mongo1:27017,mongo2:27018,mongo3:27019/?replicaSet=rs0&authSource=admin`

---

## 👤 Managing Database Users

A helper script `mongo-user.sh` automates user creation. You can run it directly:

```bash
# Bash invocation (generic)
./mongo-user.sh -u test-user-db-test -d db-test -p read:write
```

Or via your package.json scripts:

```bash
# npm
yarn mongo:create-user -- -u test-user-db-test -d db-test -p read:write

# Yarn
yarn mongo:create-user -- -u test-user-db-test -d db-test -p read:write
```

### Usage scenarios

1. **Full read/write** on `db-test`:
   ```bash
   yarn mongo:create-user -- -u test-user-db-test -d db-test -p read:write
   ```

2. **Read‑only** on `db-test`:
   ```bash
   yarn mongo:create-user -- -u test-user-db-test -d db-test -p read
   ```

3. **Write‑only** on `db-test`:
   ```bash
   yarn mongo:create-user -- -u test-user-db-test -d db-test -p write
   ```

The script will:
- Load root credentials from `.env.mongo`
- Generate a secure random password
- Create the specified user with the correct roles
- Output the final connection URI:
  ```
  mongodb://<user>:<pwd>@mongo1:27017,mongo2:27018,mongo3:27019/<db>?replicaSet=${MONGO_REPLICA_SET_NAME}&authSource=<user-db>
  ```


---

## 🔒 Security & Networking

- `--auth` enforces client authentication on all operations.
- `--keyFile` secures inter‑node communication.


./mongo/mongo-user.sh -u db-dev -d db-avvocatoflash-dev -p read:write
