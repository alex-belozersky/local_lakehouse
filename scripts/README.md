# Local Lakehouse – Quick Intro

This repository contains two parts:

* **`scripts/`** – automation scripts for installing dependencies, preparing the `.env`, pulling the lakehouse repository, and starting/stopping the entire stack.
* **`lakehouse_repo/`** – the actual lakehouse setup (MinIO, Nessie, Trino, Airflow), including updated Dockerfiles and Compose files.

### Environment Variable

All scripts respect the environment variable:

```bash
export LAKEHOUSE_HOME=/your/custom/base/path
# Default base path: /opt
# Lakehouse repo will be placed at: $LAKEHOUSE_HOME/lakehouse_repo (default: /opt/lakehouse_repo)
```

---

## How to Use

### 1. Clone only the `scripts/` directory into `/opt/scripts`:

```bash
sudo git clone --no-checkout https://github.com/itslavrov/local_lakehouse.git /opt/scripts-tmp
cd /opt/scripts-tmp

git sparse-checkout init --cone
git sparse-checkout set scripts

git checkout main
sudo mv scripts /opt/scripts

cd /
sudo rm -rf /opt/scripts-tmp

sudo chmod +x /opt/scripts/*.sh
```

---

## 2. Run installation and setup scripts step-by-step

```bash
/opt/scripts/01-install-deps.sh
/opt/scripts/02-clone-lakehouse.sh
/opt/scripts/03-generate-env.sh      # or 03-regenerate-env.sh to regenerate .env
/opt/scripts/04-start-lakehouse.sh
```

---

## 3. Check stack status

```bash
/opt/scripts/05-status-lakehouse.sh
```

---

## 4. Stop the stack

```bash
/opt/scripts/06-stop-lakehouse.sh
```
