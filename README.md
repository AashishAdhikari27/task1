# CI/CD Deployment Task Using GitHub Runner

## Introduction
This guide explains how to set up a CI/CD pipeline using GitHub Runner for deploying a React/Express project. It includes steps for server setup, dependency installation, Docker image management, and project deployment.

---

## 1. Server Setup (Bash Script)
The following Bash script ensures Docker and Nginx are installed and configured on a Linux machine.

### **server_setup.sh**
```bash
#!/bin/bash

# Update the package list
sudo apt update -y

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "Docker is already installed. Skipping installation."
fi

# Install Nginx if not installed
if ! command -v nginx &> /dev/null; then
    echo "Nginx not found. Installing Nginx..."
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
else
    echo "Nginx is already installed. Restarting service."
    sudo systemctl restart nginx
fi
```

## How to Run the Script

1. SSH into the Linux server.
2. Upload `server_setup.sh` to the server.
3. Run the following commands:

```bash
chmod +x server_setup.sh
./server_setup.sh
```

---

## 2. Dependency Setup (CI)
This step installs dependencies, builds a Docker image, and pushes it to DockerHub.

### **GitHub Actions Workflow (ci.yml)**
Create a file at `.github/workflows/ci.yml` with the following content:

```yaml
name: CI Pipeline

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v3

      - name: Set up Docker
        run: |
          sudo apt update
          sudo apt install -y docker.io

      - name: Build and Push Docker Image
        run: |
          docker build -t ${{ secrets.DOCKERHUB_USERNAME }}/my-app:latest .
          echo "${{ secrets.DOCKERHUB_PASSWORD }}" | docker login -u "${{ secrets.DOCKERHUB_USERNAME }}" --password-stdin
          docker push ${{ secrets.DOCKERHUB_USERNAME }}/my-app:latest
```

### **How to Configure DockerHub Secrets**

1. Go to GitHub Repository > Settings > Secrets.
2. Add the following secrets:
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_PASSWORD`

---

## 3. Project Deployment (CD)
This step pulls the latest Docker image and deploys it.

### **GitHub Actions Workflow (cd.yml)**
Create a file at `.github/workflows/cd.yml` with the following content:

```yaml
name: CD Pipeline

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: self-hosted
    steps:
      - name: Pull Latest Docker Image
        run: |
          echo "${{ secrets.DOCKERHUB_PASSWORD }}" | docker login -u "${{ secrets.DOCKERHUB_USERNAME }}" --password-stdin
          docker pull ${{ secrets.DOCKERHUB_USERNAME }}/my-app:latest
          docker stop my-app || true
          docker rm my-app || true
          docker run -d --name my-app -p 80:80 ${{ secrets.DOCKERHUB_USERNAME }}/my-app:latest
```

### **How to Set Up GitHub Runner**

1. Go to GitHub Repository > Settings > Actions > Runners.
2. Click **New self-hosted runner**.
3. Follow the instructions to install and start the runner.

---

## Conclusion

- **Server Setup**: Installs Docker and Nginx on the target Linux machine.
- **CI Process**: Builds a Docker image from your code and pushes it to DockerHub.
- **CD Process**: Pulls the latest image from DockerHub and deploys it on your server via a self-hosted GitHub Runner.

This setup ensures an automated CI/CD pipeline for your project. 🚀

Feel free to modify any part of this document to better fit your project's specifics!