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

1. Create `server_setup.sh` to the server.
2. Open the linux terminal and navigate to project directory.
3. And run the following commands:

```bash
chmod +x server_setup.sh
./server_setup.sh
```

---


### Test the streamlit app on local:

1. Install required dependencies on local:

```commandline
pip install -r requirements.txt
```


2. Test the streamlit app on local:

```
streamlit run app.py
```


### Building the docker image

(Note: Run as administrator on Windows and remove "sudo" in commands)

3. Important - Make sure you have installed Docker on your PC:
- Linux: Docker
- Windows/Mac: Docker Desktop

4. Start Docker:
- Linux (Home Directory):
  ```
  sudo systemctl start docker
  ```
- Windows: You can start Docker engine from Docker Desktop.

5. Build Docker image from the project directory:

```commandline
sudo docker build -t Image_name:tag .
```

### (Note: Rerun the Docker build command if you want to make any changes to the code files and redeploy.)

### Running the container & removing it

6. witch to Home Directory:

```
cd ~
```
List the built Docker images
```
$ sudo docker images
```

7. Start a container:
```commandline
sudo docker run -p 80:80 Image_ID
```

8. This will display the URL to access the Streamlit app (http://0.0.0.0:80). Note that this URL may not work on Windows. For Windows, go to http://localhost/.

9. In a different terminal window, you can check the running containers with:
```
sudo docker ps
```

10. Stop the container:
 - Use `ctrl + c` or stop it from Docker Desktop.

11. Check all containers:
 ```
 sudo docker ps -a
 ```

12. Delete the container if you are not going to run this again:
 ```
 sudo docker container prune
 ```

### Pushing the docker image to Docker Hub

13. Sign up on Docker Hub.

14. Create a repository on Docker Hub.

15. Log in to Docker Hub from the terminal. You can log in with your password or access token.
```
sudo docker login
```

17. Tag your local Docker image to the Docker Hub repository:
 ```
 sudo docker tag Image_ID username/repo-name:tag
 ```

17. Push the local Docker image to the Docker Hub repository:
 ```
 sudo docker push username/repo-name:tag
 ```

(If you want to delete the image, you can delete the repository in Docker Hub and force delete it locally.)

18. Command to force delete an image (but don't do this yet):
 ```
 $ sudo docker rmi -f IMAGE_ID
 ```

 ---

## 2. Dependency Setup (CI) & 3. Project Deployment (CD)
A combined workflow file (ci-cd.yml) is used for both the CI and CD processes. This file is located in the .github/workflows/ directory.

### **GitHub Actions Workflow (ci-cd.yml)**
Create a file at .github/workflows/ci-cd.yml with the following content:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  install-dependencies:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v3
        with:
          python-version: '3.10'

      - name: Install dependencies
        run: |
          python -m venv venv
          source venv/bin/activate
          pip install -r app/requirements.txt

  build-and-push-docker-image:
    needs: install-dependencies
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Log in to DockerHub
        run: echo "${{ secrets.DOCKERHUB_PASSWORD }}" | docker login -u "${{ secrets.DOCKERHUB_USERNAME }}" --password-stdin

      - name: Build and push Docker image
        run: |
          docker build -t ${{ secrets.DOCKERHUB_USERNAME }}/plant-leaf-diseases-classifier:latest -f app/Dockerfile .
          docker push ${{ secrets.DOCKERHUB_USERNAME }}/plant-leaf-diseases-classifier:latest

  deploy:
    needs: build-and-push-docker-image
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Install Docker Compose
        run: |
          sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
          sudo chmod +x /usr/local/bin/docker-compose

      - name: Pull and run Docker image
        run: |
          echo "${{ secrets.DOCKERHUB_PASSWORD }}" | docker login -u "${{ secrets.DOCKERHUB_USERNAME }}" --password-stdin
          docker pull ${{ secrets.DOCKERHUB_USERNAME }}/plant-leaf-diseases-classifier:latest
          docker stop plant-leaf-diseases-classifier || true
          docker rm plant-leaf-diseases-classifier || true
          docker run -d --name plant-leaf-diseases-classifier -p 80:80 ${{ secrets.DOCKERHUB_USERNAME }}/plant-leaf-diseases-classifier:latest
        env:
          DOCKER_USERNAME: ${{ secrets.DOCKERHUB_USERNAME }}
          DOCKER_PASSWORD: ${{ secrets.DOCKERHUB_PASSWORD }}

```



### **How to Configure DockerHub Secrets**

1. Go to GitHub Repository > Settings > Secrets > Actions
2. Add the following secrets:
   - DOCKERHUB_USERNAME
   - DOCKERHUB_PASSWORD

Since this pipeline uses GitHub-hosted runners, no additional runner setup is required.


### Conclusion

    Server Setup: Installs Docker and Nginx on the target Linux machine.

    CI Process: Installs project dependencies, builds a Docker image from your code, and pushes it to DockerHub.

    CD Process: Pulls the latest image from DockerHub and deploys it on your server using GitHub-hosted runners.

This setup ensures an automated CI/CD pipeline for your project. 


## Resources used

- **[ Getting Started with CI/CD Pipeline in MLOps | DevOps Made Easy 🚀 ](https://www.youtube.com/watch?v=4T1upPqoYm8)**
- **[ Deploy a Machine Learning Streamlit App Using Docker Containers | 2024 Tutorial | Step-by-Step Guide ](https://www.youtube.com/watch?v=5pPTNzUcIxg)**
- **[github.com/siddhardhan23/ci-cd-pipeline-getting-started](https://github.com/siddhardhan23/ci-cd-pipeline-getting-started)**
- **[ Integrating CI/CD Pipeline in Python Project with GitHub Actions 🚀 | Hands-On Tutorial ](https://www.youtube.com/watch?v=T-l00oT4yfA&t=1057s)**
- **[ How To Deploy A Machine Learning Model On AWS EC2 | AUG 2021 Updated | ML Model To Flask Website ](https://www.youtube.com/watch?v=_rwNTY5Mn40)**
- **[ How to Create Nginx Server in AWS | Nginx Server using EC2 Instance | Deploy Nginx Server using EC2 ](https://www.youtube.com/watch?v=casCo-d872I&t=177s)**