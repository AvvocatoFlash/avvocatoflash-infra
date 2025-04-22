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

## 🗝️ Generate & Secure file.key
```bash
openssl rand -base64 700 > file.key
chmod 400 file.key
ls -l file.key
```

---

## 🛠 Connecting

Without authentication (pre-init):
`mongodb://mongo1:27017,mongo2:27018,mongo3:27019/?replicaSet=rs0`

With authentication (post-init):
`mongodb://root:password@mongo1:27017,mongo2:27018,mongo3:27019/?replicaSet=rs0&authSource=admin`

---


./mongo/mongo-user.sh -u db-dev -d db-avvocatoflash-dev -p read:write
