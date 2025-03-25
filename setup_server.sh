#!/bin/bash

# Update system packages
sudo apt update -y

# --- Docker Setup ---
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "Docker is already installed. Skipping installation."
fi

# --- Nginx Setup ---
if ! command -v nginx &> /dev/null
then
    echo "Nginx is not installed. Installing Nginx..."
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
else
    echo "Nginx is already installed. Skipping installation."
fi

# --- Nginx Configuration ---
NGINX_CONF="/etc/nginx/sites-available/default"
echo "Configuring Nginx..."

# Configure Nginx using sudo tee to write to the file with proper permissions
NGINX_CONF="/etc/nginx/sites-available/default"
echo "Configuring Nginx..."
sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name your_domain_or_ip;

    location / {
        proxy_pass http://localhost:8501;  # Adjust as needed
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

echo "Restarting Nginx..."
sudo systemctl restart nginx
