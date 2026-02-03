# Subdomain Enumeration Script

## Introduction

This repository contains a script designed for subdomain enumeration. Subdomain enumeration is a critical component of cybersecurity and penetration testing, helping to identify and map out subdomains associated with a given domain name.

## Features

- Fast and efficient subdomain scanning.
- Easy to use.
- Can be integrated into larger penetration testing frameworks.

📋 Subdomain Enumeration Tools
🔵 Passive Enumeration (Archive/Public Data)

Subfinder - Multi-source passive subdomain discovery
Assetfinder - Cross-platform subdomain finder
Amass (passive mode) - OWASP subdomain enumeration
Findomain - Fast passive subdomain scanner
crt.sh - Certificate Transparency logs querying
Chaos - ProjectDiscovery public dataset

🔴 Active Enumeration (DNS Brute-forcing)

ShuffleDNS - High-performance DNS brute-forcing
Puredns - Wildcard-aware DNS resolver
Amass (active mode) - Active DNS brute-forcing with alterations

🟡 Permutation Generation

Gotator - Advanced subdomain permutation generator
ShuffleDNS (resolve mode) - Used to resolve generated permutations

🟢 Validation & Verification

httpx - HTTP probe to check live subdomains

## How to Use

1. Clone the repository:
   ```bash
   git clone https://github.com/shii9/Subdomain-Enumeration-Script.git
   cd Subdomain-Enumeration-Script
   ```

2. Install the necessary dependencies:
   ```bash
   # Example command
   pip install -r requirements.txt
   ```

3. Run the script:
   ```bash
   # Example command
   python script_name.py -d example.com
   ```

4. Output will include the list of enumerated subdomains.

## Contributing

If you’d like to contribute, please fork the repository and submit a pull request. To report issues or suggest features, use the issue tracker.



Feel free to update this README file as your project evolves!
