# Subdomain Enumeration Script

## Introduction

This repository contains a script designed for subdomain enumeration. Subdomain enumeration is a critical component of cybersecurity and penetration testing, helping to identify and map out subdomains associated with a given domain name.

## Features

- **Fast and efficient subdomain scanning**: Optimized for performance to quickly enumerate subdomains.
- **Ease of use**: Designed with simplicity in mind, making it suitable for users of all experience levels.
- **Integration-friendly**: Can be integrated into larger penetration testing or cybersecurity frameworks.

## Subdomain Enumeration Tools

The script leverages popular tools to enhance its functionality:

### 🔵 Passive Enumeration (Archive/Public Data)
- **Subfinder**: Multi-source passive subdomain discovery.
- **Assetfinder**: Cross-platform subdomain finding.
- **Amass (passive mode)**: OWASP subdomain enumeration tool.
- **Findomain**: A fast, passive subdomain scanner.
- **crt.sh**: Querying Certificate Transparency logs.
- **Chaos**: Utilizes the ProjectDiscovery public dataset.

### 🔴 Active Enumeration (DNS Brute-forcing)
- **ShuffleDNS**: High-performance DNS brute-forcing.
- **Puredns**: A wildcard-aware DNS resolver.
- **Amass (active mode)**: Performs active DNS brute-forcing with various alterations.

### 🟡 Permutation Generation
- **Gotator**: Generates advanced subdomain permutations.
- **ShuffleDNS (resolve mode)**: Resolves generated permutations.

### 🟢 Validation & Verification
- **httpx**: Conducts HTTP probing to validate live subdomains.

## How to Use

Follow the instructions below to clone, set up, and execute the script for subdomain enumeration:

### Step 1: Clone the Repository
```bash
git clone https://github.com/shii9/Subdomain-Enumeration-Script.git
cd Subdomain-Enumeration-Script
chmod +x web_subdomain
```

### Step 2: Install Dependencies
Install the required dependencies using the following command:
```bash
pip install -r requirements.txt
```

### Step 3: Run the Script
Execute the script to enumerate subdomains for a specific domain:
```bash
python script_name.py -d example.com
```

Replace `example.com` with the domain name you want to enumerate. The output will include a list of identified subdomains.

## Contributing

We welcome contributions to improve the project. Here’s how you can contribute:

1. **Fork the Repository**: Create a copy of the repository in your GitHub account.
2. **Make Changes**: Enhance the code, fix bugs, or improve documentation.
3. **Open a Pull Request**: Submit your changes for review.

For issues or feature suggestions, please use the **issue tracker** in this repository.

---

Feel free to update this README file as the project evolves and more features/tools are added! If you have suggestions for improvement, don’t hesitate to contribute.
