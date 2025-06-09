# Miniworld CICD Setup Guide
This repo is a simulation of a complete CICD process using Docker Compose + Minikube.
## Overview

Before we begin, it’s important to understand the **technology stack** used and the overall **process**.

This repository contains **two main directories**:

* `cicd/`: Contains the complete CI/CD workflow.
* `repo/`: Contains source code and files to be uploaded to [GitLab.com](https://gitlab.com).

### Project Structure

```
.
├── README.md
├── cicd
│   ├── Dockerfile.jenkins
│   ├── config_dind/
│   ├── config_kube/
│   ├── config_vault/
│   └── docker-compose.yml
└── repo
    ├── infa/
    └── microlab_app1/
```

### Technology Stack

* **Application**: Node.js
* **CI/CD**: Jenkins, Helm, Vault, Nexus, Minikube

---

## How to Run

### Step 1: Clone the Repository

```bash
git clone https://github.com/thodsaphon-nueng/miniworld_cicd.git
```

### Step 2: Upload to GitLab

Upload both `infa` and `microlab_app1` directories from `repo/` to your own GitLab repositories.

Example:

```
https://gitlab.com/your_account/infa.git
https://gitlab.com/your_account/microlab_app1.git
```

---

## CI/CD Environment Setup

### Step 3: Start Minikube

```bash
cd miniworld_cicd/cicd
minikube start --driver=docker --insecure-registry="nexus:5000" --apiserver-ips=192.168.49.2
minikube addons enable ingress
sudo minikube tunnel
```

Open a **new terminal** for the next steps.

### Step 4: Start Docker Compose

```bash
docker compose up --build
```

---

## Jenkins Setup

### Get Jenkins Admin Password

```bash
docker exec -it [jenkins_container_id] cat /var/jenkins_home/secrets/initialAdminPassword
```

Access Jenkins at `http://localhost:8080`, enter the password, install suggested plugins, and then install the following manually:

* [HashiCorp Vault Plugin](https://plugins.jenkins.io/hashicorp-vault-plugin/)
* [GitLab Plugin](https://plugins.jenkins.io/gitlab-plugin/)
* [Pipeline: Stage View](https://plugins.jenkins.io/pipeline-stage-view/)

---

### Vault Configuration (Inside Jenkins Container)

```bash
docker exec -it [jenkins_container_id] bash
cd config_vault/
chmod +x vault_script.sh
./vault_script.sh | tee keep-output.txt
unset VAULT_TOKEN
vault kv put secret/myapp PASSWORD="s3cr3t123"
vault kv put secret/myapp_main PASSWORD="main"
```

Vault UI: `http://localhost:8200`
Credentials:

* Username: `devuser`
* Password: `devpass`

---

### Jenkins Credentials Setup

1. Go to **Manage Jenkins > Credentials**
2. Add the following under **Global**:

**GitLab Token**

* Kind: Username with Password
* Username: `your_account`
* Password: `your_gitlab_token`
* ID: `gitlab-token`

**Vault Credential**

* Kind: Vault App Role Credential
* Role ID and Secret ID: *(from Vault setup)*
* ID: `vault_credential`

---

## Ngrok Setup

```bash
ngrok http 8080
```

Use the generated public URL to update Jenkins settings:

**Manage Jenkins > System**

* Jenkins URL → use new ngrok URL

**Manage Jenkins > Security**

* Authorization → "Anyone can do anything" *(for ease of testing only)*

---

## Nexus Setup

Access Nexus at `http://localhost:8081`

```bash
docker exec -it [nexus_container_id] cat /nexus-data/admin.password
```

Login:

* Username: `admin`
* Password: *(output from command above)*

Create a new Docker (hosted) repository:

* Name: `microlab`
* Port: `5000`

Inside Jenkins

    docker login nexus:5000

---

## Networking

Allow Jenkins and Nexus to communicate with Minikube:

```bash
docker network connect minikube jenkins
docker network connect minikube nexus
```

Inside Jenkins container, test with:

```bash
ping -c 3 minikube
```

---

## Kubectl Access in Jenkins

**On Host (Outside Jenkins):**

Copy your Minikube configs:

```bash
cp -rf ~/.kube ~/.minikube [project_path]/cicd/config_kube
```

Edit `config_kube/.kube/config`:

* Change username paths from your host (e.g., `Users/thodsaphon.s`) to `/root`
* Change server URL to: `https://minikube:8443`

**Inside Jenkins Container:**

```bash
cd /config_kube/
cp -rf .kube .minikube /root/
kubectl version
```

Should output both client and server versions.

Create namespaces and registry secrets:

```bash
kubectl create namespace development
kubectl create namespace production

kubectl create secret docker-registry nexus-regcred \
  --docker-server=nexus:5000 \
  --docker-username=admin \
  --docker-password=admin \
  -n development

kubectl create secret docker-registry nexus-regcred \
  --docker-server=nexus:5000 \
  --docker-username=admin \
  --docker-password=admin \
  -n production
```

---

## Jenkins Job Setup

In Jenkins:

1. **Dashboard > New Item > Multibranch Pipeline**
2. Name: `microlab_app1`
3. Branch Sources:

   * Git
   * Repo URL: `https://gitlab.com/your_account/microlab_app1.git`
   * Credentials: `gitlab-token`
4. Behaviours:

   * Filter by name (wildcards): `main _dev`
5. Build Configuration:

   * Script Path: `jenkinsfile` *(note: lowercase)*

Click **Save**.

You should see branches like `main`, `_dev` with appropriate stages.

---

## Helm Deployment Verification

Inside Jenkins container:

```bash
helm list --all-namespaces
```

Expected output:

```
NAME              	NAMESPACE  	STATUS  	    CHART
microlab-app1--dev	development	deployed	    microlab-app1-chart-0.1.0
microlab-app1-main	production 	deployed	    microlab-app1-chart-0.1.0
```

---

## Ingress Setup

**Inside Jenkins Container:**

```bash
cd /config_kube
kubectl apply -f microlab-ingress.yaml --namespace development
kubectl apply -f microlab-prd-ingress.yaml --namespace production
```

**On Host:**

Edit `/etc/hosts`:

```bash
127.0.0.1 dev-microlab.local microlab.local
```

You can now `curl` or open `http://dev-microlab.local` and `http://microlab.local` in your browser.

---

For gitlab webhook tigger, enter the [URL of ngrok] + /project/microlab_app1

repo > settings > webhook

i.e. https://542e-119-110-237-98.ngrok-free.app/project/microlab_app1


---
## Final Notes

All images and steps have been set up. From here, 

<img width="991" alt="Image" src="https://github.com/user-attachments/assets/bf574e60-6f9a-4967-897d-ce9fdc987803" />
<img width="1406" alt="Image" src="https://github.com/user-attachments/assets/65269563-110d-4c04-b8bf-cb84f58b5b1d" />
<img width="1430" alt="Image" src="https://github.com/user-attachments/assets/0a3e86ff-53fd-4b67-a9e8-e1780f18222d" />
<img width="1422" alt="Image" src="https://github.com/user-attachments/assets/c05f5032-dead-4625-ae2f-c5a18f78f3a7" />

Congratulations 🎉 you're encouraged to **study the system** and **customize it** to suit your own workflows.

Happy DevOps 🚀

