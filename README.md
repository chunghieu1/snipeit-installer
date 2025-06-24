# Auto Snipe-IT Installer

A fully automated script to install [Snipe-IT](https://snipeitapp.com/), the popular open-source asset management system, using Docker and Docker Compose.  
No manual steps, no configuration headaches — just run and go.

---

## Features

- Silent and unattended setup
- Automatically installs Docker & Docker Compose
- Dynamically sets up `.env` and `docker-compose.yml`
- Auto-detects VPS public IP for use in the Snipe-IT URL
- Starts both Snipe-IT and MariaDB containers
- Designed for Ubuntu-based VPS (20.04/22.04/24.04)

---

## Requirements

- Ubuntu-based server (20.04+)
- Root or sudo privileges
- Internet connection

---

## Usage

### 1. Clone the repository

```bash
git clone https://github.com/chunghieu1/auto-snipeit-installer.git
cd auto-snipeit-installer
```

### 2. Run the installation script

```bash
chmod +x setup_snipeit.sh
./setup_snipeit.sh
```

This script will:

- Update your system
- Install Docker and Docker Compose
- Create the Snipe-IT `.env` and `docker-compose.yml` files
- Start the containers in the background

### 3. Run directly using `wget` (optional)

If you prefer not to clone the repository, you can run the script directly:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/chunghieu1/auto-snipeit-installer/main/setup_snipeit.sh)
```

### 4. Access Snipe-IT

After the installation is complete, open your browser and navigate to:

```plaintext
http://your-server-ip
```

Replace `your-server-ip` with the public IP address of your server.

---

## Notes

- Ensure your server meets the requirements before running the script.
- For troubleshooting or customization, refer to the script comments or the [Snipe-IT documentation](https://snipeitapp.com/docs).