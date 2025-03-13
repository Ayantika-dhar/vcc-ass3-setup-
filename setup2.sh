#!/bin/bash

echo "🚀 Setting up CPU Auto-Scaler Project..."

# Create main directory
mkdir -p cpu-autoscaler/backend cpu-autoscaler/frontend
cd cpu-autoscaler

# Backend Setup
echo "📦 Setting up Backend..."
cd backend
npm init -y

# Install necessary backend dependencies
npm install express cors os-utils @google-cloud/compute

# Create backend server file
cat > server.js <<EOL
const express = require("express");
const cors = require("cors");
const os = require("os-utils");
const { Worker } = require("worker_threads");
const { exec } = require("child_process");

const app = express();
app.use(cors());

let worker = null;
let cpuUsage = 0;

setInterval(() => {
    os.cpuUsage((v) => {
        cpuUsage = (v * 100).toFixed(2);
        console.log(\`CPU Usage: \${cpuUsage}%\`);
        if (cpuUsage > 75) {
            console.log("⚠️ High CPU Load Detected. Scaling Up...");
            scaleUp();
        }
    });
}, 3000);

app.get("/start", (req, res) => {
    if (!worker) {
        worker = new Worker("./worker.js");
        res.json({ message: "Computation started" });
    } else {
        res.json({ message: "Already running" });
    }
});

app.get("/stop", (req, res) => {
    if (worker) {
        worker.terminate();
        worker = null;
        res.json({ message: "Computation stopped" });
    } else {
        res.json({ message: "No computation running" });
    }
});

app.get("/cpu", (req, res) => {
    res.json({ cpuUsage });
});

app.get("/open-gcp", (req, res) => {
    exec("xdg-open https://console.cloud.google.com/compute/instances", () => {
        res.json({ message: "Opening GCP Console" });
    });
});

function scaleUp() {
    exec("gcloud compute instances create new-vm --zone=us-central1-a", (err, stdout, stderr) => {
        if (err) {
            console.error(\`Error: \${stderr}\`);
            return;
        }
        console.log(\`VM Created: \${stdout}\`);
    });
}

app.listen(5000, () => console.log("Backend running on port 5000"));
EOL

# Create worker thread file
cat > worker.js <<EOL
function isPrime(num) {
    for (let i = 2, sqrt = Math.sqrt(num); i <= sqrt; i++) {
        if (num % i === 0) return false;
    }
    return num > 1;
}

let num = 2;
while (true) {
    if (isPrime(num)) {}
    num++;
}
EOL

# Navigate back to project root
cd ..

# Upgrade Node.js to version 20
echo "⬆️ Upgrading Node.js to version 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v

# Frontend Setup using Vite.js
echo "🎨 Setting up Frontend..."
cd frontend
npm create vite@latest . --template react --yes
npm install

# Navigate back to project root
cd ..

# Install GCP SDK manually
echo "☁️ Adding Google Cloud SDK repository..."
sudo apt remove google-cloud-sdk -y  # Remove broken installations
sudo apt-get install -y apt-transport-https ca-certificates gnupg

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

sudo apt update && sudo apt install -y google-cloud-sdk

# Authenticate with GCP
echo "🔑 Authenticating Google Cloud..."
gcloud auth login
gcloud config set project vcc-ass3

# Completion Message
echo "✅ Setup complete! Use the following commands to start the project:"
echo ""
echo "Backend: cd cpu-autoscaler/backend && node server.js"
echo "Frontend: cd cpu-autoscaler/frontend && npm run dev"
