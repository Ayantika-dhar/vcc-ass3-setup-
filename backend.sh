#!/bin/bash

echo "Setting up the backend for CPU Monitoring App..."

# Navigate to the project directory (create if not exists)
mkdir -p ~/cpu-monitoring-app && cd ~/cpu-monitoring-app

# Initialize a Node.js project
npm init -y

# Install required dependencies
npm install express cors os-utils child_process @google-cloud/compute

# Create server.js with backend code
cat <<EOF > server.js
const express = require("express");
const osUtils = require("os-utils");
const { spawn, exec } = require("child_process");

const app = express();
const PORT = 5000;

let computeProcess = null; // Tracks the prime calculation process

app.use(express.json());
app.use(require("cors")());

// Endpoint to get CPU usage
app.get("/cpu-usage", (req, res) => {
    osUtils.cpuUsage((usage) => {
        res.json({ cpuUsage: usage * 100 });
    });
});

// Start CPU-intensive task (Prime Number Calculation)
app.post("/start-computation", (req, res) => {
    if (!computeProcess) {
        computeProcess = spawn("node", ["compute.js"], { detached: true, stdio: "ignore" });
        computeProcess.unref();
        return res.json({ message: "Computation started" });
    }
    res.json({ message: "Already running" });
});

// Stop CPU-intensive task
app.post("/stop-computation", (req, res) => {
    if (computeProcess) {
        process.kill(-computeProcess.pid);
        computeProcess = null;
        return res.json({ message: "Computation stopped" });
    }
    res.json({ message: "No computation running" });
});

// Monitor CPU usage and trigger auto-scaling if usage exceeds 75%
setInterval(() => {
    osUtils.cpuUsage((usage) => {
        const cpuPercent = usage * 100;
        console.log(\`CPU Usage: \${cpuPercent.toFixed(2)}%\`);

        if (cpuPercent > 75) {
            console.log("CPU usage exceeded 75%! Triggering GCP VM creation...");
            exec("gcloud compute instances create auto-scaled-vm --zone=us-central1-a --machine-type=e2-medium", 
                (error, stdout, stderr) => {
                    if (error) {
                        console.error(\`Error creating VM: \${error.message}\`);
                        return;
                    }
                    console.log(\`GCP Response: \${stdout}\`);
                }
            );
        }
    });
}, 5000); // Check CPU usage every 5 seconds

// Endpoint to check GCP status (Placeholder)
app.get("/gcp-status", (req, res) => {
    res.json({ message: "Monitoring GCP VM status..." });
});

// Start server
app.listen(PORT, () => console.log(\`Server running on http://localhost:\${PORT}\`));
EOF

echo "Backend API created successfully!"

# Create compute.js for CPU-intensive task
cat <<EOF > compute.js
// Function to check if a number is prime
function isPrime(num) {
    for (let i = 2; i < num; i++) {
        if (num % i === 0) return false;
    }
    return num > 1;
}

let num = 2;
while (true) {
    if (isPrime(num)) console.log(num);
    num++;
}
EOF

echo "CPU-intensive computation script created successfully!"

echo "Backend setup complete! Run 'node server.js' to start the server."
