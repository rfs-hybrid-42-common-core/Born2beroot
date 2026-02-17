# 🐧 Debian Installation & Setup Guide (Bonus Included)

This step-by-step guide will walk you through setting up a headless Debian virtual machine that perfectly satisfies both the mandatory and bonus requirements of the Born2beroot project.

## 📑 Table of Contents
1. [Phase 1: Virtual Machine Creation](#-phase-1-virtual-machine-creation)
2. [Phase 2: OS Installation & Encrypted LVM](#-phase-2-os-installation--encrypted-lvm-bonus-layout)
3. [Phase 3: Base Configuration & Sudo Setup](#-phase-3-base-configuration--sudo-setup)
4. [Phase 4: SSH & UFW (Firewall) Configuration](#-phase-4-ssh--ufw-firewall-configuration)
5. [Phase 5: Password Policy & User Management](#-phase-5-password-policy--user-management)
6. [Phase 6: The Monitoring Script](#-phase-6-the-monitoring-script)
7. [Phase 7: Bonus Services (WordPress & FTP)](#-phase-7-bonus-services-wordpress--ftp)

---

## 💿 Phase 1: Virtual Machine Creation

### Prerequisite: Download the ISO
Before starting, ensure you have downloaded the latest **Debian netinst ISO** (Network Installer) directly from the official Debian website (e.g., `debian-12.x.x-amd64-netinst.iso` or `debian-13.x.x`). Do not use the "Live" or "DVD" versions.

### Setting up VirtualBox
1. Open **VirtualBox** and click **New**.
2. **Name:** Enter your machine name (e.g., `maaugust_born2beroot`).
3. **ISO Image:** Click the dropdown, select "Other...", and choose the `debian-netinst.iso` file you just downloaded.
4. ⚠️ **CRITICAL STEP:** You MUST check the box that says **Skip Unattended Installation**. If you do not check this, VirtualBox will automatically bypass the encrypted partitioning phase and install a forbidden graphical interface!

> **[Insert Screenshot: The VirtualBox "New" screen showing the ISO selected and the "Skip Unattended Installation" box checked]**

5. Click **Next**. Allocate at least **1024 MB** of Base Memory (RAM) and 1 CPU.
6. Click **Next**. Create a Virtual Hard Disk. For the bonus partitioning scheme, a **30 GB** dynamically allocated disk is highly recommended. Click **Finish**.
7. Now, select your newly created VM and click **Settings**.
8. Go to **Network** and ensure Adapter 1 is set to **NAT**. Click **Advanced** and set up **Port Forwarding**:
   * **SSH:** Host Port `4242` -> Guest Port `4242`
   * **HTTP (Bonus):** Host Port `8080` -> Guest Port `80`
   * **FTP (Bonus):** Host Port `2121` -> Guest Port `21`

> **[Insert Screenshot: VirtualBox Port Forwarding Rules showing the 4242 mapping]**

---

## 🏗️ Phase 2: OS Installation & Encrypted LVM (Bonus Layout)
Start your virtual machine and select **Install** (do not select Graphical Install, as graphical interfaces are strictly forbidden).

### Basic Localization
1. Select your Language, Location, and Keyboard layout.
2. **Hostname:** Enter your login followed by 42 (e.g., `maaugust42`).
3. **Domain Name:** Leave blank.

### User Setup
1. **Root Password:** Choose a strong password (we will enforce the strict 42 password policy later).
2. **Full Name & Username:** Enter your login (e.g., `maaugust`). Set the user password.

> **[Insert Screenshot: Setting the Hostname to maaugust42]**

### Partitioning Disks (The Most Critical Step)
To achieve the bonus score, you must set up specific logical volumes. 

1. Select **Guided - use entire disk and set up encrypted LVM**.
2. Select your 30GB VDI disk.
3. Select **Separate /home, /var, and /tmp partitions** (this gives us a head start on the bonus layout).
4. Select `<Yes>` to write the current partition table and wait for the disk erasure to finish (this can be skipped/cancelled if you are testing, but let it run for your final VM).
5. Enter your **Encryption Passphrase**. You will need this every time you boot the server!

> **[Insert Screenshot: The "Separate /home, /var, and /tmp" selection screen]**

#### Configuring the Bonus Logical Volumes

After the encrypted volume is created, Debian will show you the proposed sizes. We need to manually adjust them to match the bonus subject requirements:

1. Scroll down to **Configure the Logical Volume Manager**. Keep current layout? Select `<Yes>`.
2. You are now in the LVM menu. You will see existing Logical Volumes (root, var, swap, tmp, home). 
3. We need to create two missing volumes: `/srv` and `/var/log`.
   * Select **Create logical volume**.
   * Select your Volume Group (usually named `hostname-vg`).
   * Name it `srv`. Assign it `3G`.
   * Repeat the process to create a volume named `var-log` and assign it `4G`.
4. Select **Finish** to exit the LVM configuration menu.

> **[Insert Screenshot: The LVM Configuration menu showing all 7 Logical Volumes]**

#### Formatting and Mounting the Volumes
Now, assign mount points to the logical volumes you just created so the OS knows how to use them:
1. Scroll to the `srv` logical volume, select `#1`, set **Use as:** `Ext4`, and set **Mount point:** `/srv`.
2. Scroll to the `var-log` logical volume, select `#1`, set **Use as:** `Ext4`, and set **Mount point:** Enter manually as `/var/log`.
3. Select **Finish partitioning and write changes to disk**.

> **[Insert Screenshot: The final partition overview screen before writing to disk. This is the exact screenshot evaluators want to see!]**

### Software Selection
1. Scan extra installation media? `<No>`.
2. Participate in package usage survey? `<No>`.
3. **Software selection:** Uncheck "Debian desktop environment" and "GNOME" (Graphical interfaces equal an instant 0!).
4. **ONLY** leave **SSH server** and **standard system utilities** checked.

> **[Insert Screenshot: Software selection screen with ONLY SSH and Standard Utilities checked]**

5. Install the GRUB boot loader to your primary drive (`/dev/sda`).
6. Installation complete! Reboot your new headless server.

## 🛠️ Phase 3: Base Configuration & Sudo Setup
Log into your new virtual machine using the `root` password you created during installation. 

### 1. Update the System
Before installing anything, ensure your package lists are up to date:
```bash
apt update && apt upgrade -y
```

### 2. Install Sudo and Manage Groups
The subject requires your user to belong to the `user42` and `sudo` groups.
```bash
# Install sudo
apt install sudo -y

# Create the user42 group
addgroup user42

# Add your user to both groups (replace 'maaugust' with your actual username)
usermod -aG sudo,user42 maaugust

# Verify the groups
groups maaugust
```

> **[Insert Screenshot: Output of the `groups maaugust` command showing both groups]**

### 3. Strict Sudo Configuration
The subject enforces very strict rules for `sudo` (limited attempts, custom error messages, TTY requirements, path restrictions, and logging).

First, create the required log directory:
```bash
mkdir -p /var/log/sudo
```

Next, open the sudoers file securely:
```bash
visudo
```

Add the following `Defaults` lines directly below the existing `Defaults env_reset` line:
```plaintext
Defaults        env_reset
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
Defaults        passwd_tries=3
Defaults        badpass_message="Wrong password! This incident will be reported."
Defaults        requiretty
Defaults        logfile="/var/log/sudo/sudo.log"
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

> **[Insert Screenshot: The visudo file showing all the custom Defaults explicitly defined]**

### 4. Verify AppArmor is Running
Because we installed Debian using the `netinst` ISO and selected "standard system utilities," AppArmor is already installed and enabled by default in the kernel. You simply need to know how to verify it is running for your defense.

```bash
# Verify that AppArmor is loaded and active
aa-status
```

> **[Insert Screenshot: Output of `aa-status` showing that the AppArmor module is loaded]**

## 🛡️ Phase 4: SSH & UFW (Firewall) Configuration

### 1. Configure the UFW Firewall
We must install `ufw` and lock down the server so only port 4242 is open.
```bash
# Install UFW
apt install ufw -y

# Enable the firewall (Press 'y' when warned about disrupting SSH)
ufw enable

# Allow port 4242
ufw allow 4242

# Verify the rules
ufw status numbered
```

> **[Insert Screenshot: Output of `ufw status numbered` showing ONLY port 4242 allowed for both IPv4 and IPv6]**

### 2. Configure SSH
We need to change the default SSH port from 22 to 4242 and disable root login for security.

Open the SSH daemon configuration file:
```bash
nano /etc/ssh/sshd_config
```

Find and modify the following lines (make sure to remove the `#` symbol to uncomment them):
```plaintext
Port 4242
PermitRootLogin no
```

Save and exit. Then, restart the SSH service to apply the changes:
```bash
systemctl restart ssh
```

> **[Insert Screenshot: The modified sshd_config file showing Port 4242 and PermitRootLogin no]**

### 3. Test Your Connection
To ensure everything works smoothly, open a terminal on your Host Machine (your actual physical computer) and attempt to SSH into the VM:
```bash
ssh maaugust@localhost -p 4242
```

If you connect successfully, your port forwarding, firewall, and SSH configuration are all perfect!

---

## 🔐 Phase 5: Password Policy & User Management

The subject requires a highly strict password policy: passwords must expire every 30 days, have a minimum of 2 days between changes, send a 7-day warning, and require at least 10 characters with specific complexity (uppercase, lowercase, numeric, max 3 identical consecutive characters, no usernames, and 7 characters different from the previous password).

### 1. Configure Password Expiration (Aging)
First, we modify the default expiration rules for all *newly created* users.
Open the login definitions file:
```bash
nano /etc/login.defs
```

Find and change the following values:
```plaintext
PASS_MAX_DAYS   30
PASS_MIN_DAYS   2
PASS_WARN_AGE   7
```

Save and exit.

Because `/etc/login.defs` only applies to users created after this change, we must manually apply these rules to the users we already created (`root` and `maaugust`):
```bash
# Apply to root
chage -m 2 -M 30 -W 7 root

# Apply to your user
chage -m 2 -M 30 -W 7 maaugust

# Verify the changes for your user
chage -l maaugust
```

> **[Insert Screenshot: Output of `chage -l maaugust` showing the 30-day expiration policy]**

### 2. Configure Password Complexity
To enforce the character requirements, we need to install the Password Quality PAM (Pluggable Authentication Module).
```bash
apt install libpam-pwquality -y
```

Now, edit the common password configuration file:
```bash
nano /etc/pam.d/common-password
```

Find the line that starts with `password requisite pam_pwquality.so` and modify it so it looks exactly like this:
```plaintext
password requisite pam_pwquality.so retry=3 minlen=10 ucredit=-1 dcredit=-1 lcredit=-1 maxrepeat=3 reject_username difok=7 enforce_for_root
```

**Explanation of flags for your defense:**
* `minlen=10`: Minimum 10 characters.
* `ucredit=-1`, `dcredit=-1`, `lcredit=-1`: Requires at least one uppercase, digit, and lowercase letter.
* `maxrepeat=3`: Denies more than 3 consecutive identical characters.
* `reject_username`: Prevents the password from containing the user's name.
* `difok=7`: Requires at least 7 characters that are different from the old password.
* `enforce_for_root`: Ensures the root user is also bound by these strict complexity rules.

> **[Insert Screenshot: The modified common-password file showing the long pwquality.so line]**

---

## ⏱️ Phase 6: The Monitoring Script

The subject requires a bash script that broadcasts system information on all terminals every 10 minutes.

### 1. Create the Script
Create the script in the `/usr/local/bin` directory, which is standard for local executable scripts:
```bash
nano /usr/local/bin/monitoring.sh
```

Paste your optimized bash script:
```bash
#!/bin/bash

arc=$(uname -a)
pcpu=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
vcpu=$(grep "^processor" /proc/cpuinfo | wc -l)
ram=$(free -m | awk '$1 == "Mem:" {printf "%d/%dMB (%.2f%%)", $3, $2, $3/$2*100}')
disk=$(df -m | grep "^/dev/" | grep -v "/boot$" | awk '{ut += $3; tt += $2} END {printf "%d/%dGb (%d%%)", ut, tt/1024, ut/tt*100}')
cpul=$(top -bn1 | grep '^%Cpu' | awk '{printf "%.1f%%", 100 - $8}')
lb=$(who -b | awk '$1 == "system" {print $3 " " $4}')
lvmu=$(if [ $(lsblk | grep "lvm" | wc -l) -gt 0 ]; then echo yes; else echo no; fi)
tcpc=$(ss -ta | grep ESTAB | wc -l)
ulog=$(users | wc -w)
ip=$(hostname -I | awk '{print $1}')
mac=$(ip link | grep "link/ether" | awk '{print $2}')
cmds=$(journalctl _COMM=sudo | grep COMMAND | wc -l)

wall "#Architecture: $arc
#Physical CPU: $pcpu
#vCPU: $vcpu
#Memory Usage: $ram
#Disk Usage: $disk
#CPU load: $cpul
#Last boot: $lb
#LVM use: $lvmu
#TCP Connections: $tcpc ESTABLISHED
#User log: $ulog
#Network: IP $ip ($mac)
#Sudo: $cmds cmd"
```

Save and exit. Now, make the script executable:
```bash
chmod +x /usr/local/bin/monitoring.sh
```

### 2. Schedule the Script with Cron
We will use `cron` to execute this script. Since standard cron (`*/10`) triggers on the wall-clock (e.g., 10:00, 10:10), we will use an advanced configuration to ensure it triggers at **startup** and exactly every 10 minutes **from the boot time**.
```bash
# Open the root crontab
crontab -e
```

*(If prompted to select an editor, press `1` for nano).*
Scroll to the very bottom of the file and add the following rules:
```plaintext
@reboot /usr/local/bin/monitoring.sh
* * * * * min=$(cat /proc/uptime | awk '{print int($1/60)}'); if [ "$min" -gt 0 ] && [ "$((min \% 10))" -eq 0 ]; then /usr/local/bin/monitoring.sh; fi
```

Save and exit.

**🧠 Explanation for your defense:**
* `@reboot`: Fulfills the "At server startup" requirement.
* `* * * * *`: Forces cron to run a check every single minute.
* `min=$(cat /proc/uptime...)`: Calculates exactly how many minutes the server has been alive.
* `$((min \% 10)) -eq 0`: Checks if the uptime in minutes is a multiple of 10. If it is, it executes the script!
> *(Note: You must explain to the evaluator that the `%` modulo operator is escaped with a backslash `\%`. If you don't escape it, cron reads `%` as a newline character and the script will fail!)*

> **[Insert Screenshot: The crontab file showing both the @reboot and the uptime rules]**

### 3. Verify the Script
To ensure it works without waiting 10 minutes, you can run it manually:
```bash
/usr/local/bin/monitoring.sh
```

You should see the wall broadcast pop up on your terminal instantly.

> **[Insert Screenshot: The output of the monitoring script perfectly matching the subject's example format]**

---

## 🌟 Phase 7: Bonus Services (WordPress & FTP)

To achieve the bonus, we must set up a functional WordPress website using Lighttpd, MariaDB, and PHP (a LEMP stack) . We also need to configure an FTP service (vsftpd) and a security service (Fail2ban) to protect them.

### 🧠 Evaluation Prep: Defending Your Bonus Choices
During the defense, the evaluator will ask you to explain exactly what these services do and **why you chose them** (especially your "free-choice" service). Here is how you answer to secure those points:

* **Lighttpd (Web Server):** The subject strictly forbids using the industry standards, Apache2 and NGINX. Lighttpd is the optimal alternative because it is exceptionally fast, uses a tiny memory footprint, and seamlessly handles PHP via FastCGI.
* **MariaDB (Database):** A fully open-source, highly secure, drop-in replacement for MySQL. It is required to store all of WordPress's dynamic data, user accounts, and settings.
* **PHP:** A server-side scripting language. Since the core of WordPress is written in PHP, this processor is mandatory to dynamically generate the HTML web pages and communicate with the MariaDB database.
* **vsftpd (File Transfer):** Stands for "Very Secure FTP Daemon". I chose this because of its incredibly strict security defaults. It allows us to easily "jail" (chroot) our FTP user, guaranteeing they can only upload files to the `/srv/wordpress` directory and cannot access the rest of the server.
* **Fail2ban (The "Free-Choice" Service):** An active intrusion prevention framework . I chose this as my extra service because it perfectly aligns with the project's core theme of extreme server security. Because the bonus requires us to open new ports (80 and 21) to the outside world, we increased our attack surface. Fail2ban monitors our service logs in real-time and automatically bans the IP addresses of attackers trying to brute-force our SSH or FTP passwords.

### 1. Update the Firewall
Our new services need specific ports open to communicate with the outside world.
```bash
# Allow HTTP (Web Server)
ufw allow 80

# Allow FTP (File Transfer Protocol)
ufw allow 21

# Verify the new rules
ufw status numbered
```

### 2. Install the LEMP Stack (Lighttpd, MariaDB, PHP)
Install the core packages required to host a dynamic website:
```bash
apt install lighttpd mariadb-server php-cgi php-mysql wget -y
```

Now, we need to enable the PHP processor (FastCGI) within our Lighttpd server:
```bash
lighty-enable-mod fastcgi
lighty-enable-mod fastcgi-php
systemctl restart lighttpd
```

### 3. Configure the MariaDB Database
WordPress needs a database to store its posts, users, and settings. First, let's secure the database installation:
```bash
mysql_secure_installation
```

* **Enter current password for root: Press `Enter` (it's blank by default).**
* **Switch to unix_socket authentication: `n`**
* **Change the root password: `Y` (Set a strong password).**
* **Remove anonymous users: `Y`**
* **Disallow root login remotely: `Y`**
* **Remove test database: `Y`**
* **Reload privilege tables: `Y`**

Next, log into the MySQL console to create the WordPress database and user:
```bash
mariadb -u root -p
```

*(Enter the MySQL root password you just created).*
Run the following SQL commands exactly as written (don't forget the semicolons!):

```sql
CREATE DATABASE wordpress;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'YourStrongPassword123!';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

> **[Insert Screenshot: The MariaDB console showing the successful creation of the database and user]**

### 4. Install and Configure WordPress
We will download WordPress and place it inside the `/srv` partition we created during Phase 2.
```bash
# Download the latest WordPress archive
wget https://wordpress.org/latest.tar.gz

# Extract it directly into our bonus partition
tar -xzvf latest.tar.gz -C /srv/

# Remove the downloaded archive to save space
rm latest.tar.gz
```

Next, we must tell Lighttpd to look in `/srv/wordpress` for the website instead of the default `/var/www/html`.
```bash
nano /etc/lighttpd/lighttpd.conf
```

Find the line that says `server.document-root = "/var/www/html"` and change it to:
```plaintext
server.document-root        = "/srv/wordpress"
```

Save and exit, then restart the web server:
```bash
systemctl restart lighttpd
```

Finally, configure the WordPress connection to the database we made:
```bash
# Create the actual config file from the sample template
cp /srv/wordpress/wp-config-sample.php /srv/wordpress/wp-config.php

# Open it to edit the database credentials
nano /srv/wordpress/wp-config.php
```

Update these three specific lines with the database info you created in Step 3:
```php
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'wp_user' );
define( 'DB_PASSWORD', 'YourStrongPassword123!' );
```

Save and exit. Now, test it! Open a web browser on your Host Machine and go to `http://localhost:8080` (You will need to add a VirtualBox port forwarding rule mapping Host Port `8080` to Guest Port `80`). You should see the WordPress installation screen!

> **[Insert Screenshot: The WordPress welcome screen in your browser]**

### 5. Set up the FTP Server (vsftpd)
We need an FTP server to allow file uploads to our website.
```bash
apt install vsftpd -y
```

Configure the FTP daemon:
```bash
nano /etc/vsftpd.conf
```

Find and modify (or add) the following lines to lock the FTP user into their directory securely:
```plaintext
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO
```

Save and exit.

Now, create the FTP user and give them ownership of the `/srv/wordpress` folder:
```bash
# Create the user (it will prompt you to set a password)
adduser ftpuser

# Add the user to the allowed FTP list
echo "ftpuser" | tee -a /etc/vsftpd.userlist

# Set the user's home directory to our WordPress folder
usermod -d /srv/wordpress ftpuser

# Give the FTP user and the Web Server ownership of the files
chown -R ftpuser:www-data /srv/wordpress

# Restart the service
systemctl restart vsftpd
```

> **[Insert Screenshot: Using FileZilla or an FTP client on your host to successfully log into the VM as 'ftpuser' on port 21]**

### 6. Set up Fail2ban (Extra Security Bonus)
Fail2ban scans log files and bans IPs that show malicious signs, like too many password failures.
```bash
apt install fail2ban -y
```

We never edit the default `jail.conf`. Instead, we copy it to `.local` and edit that:
```bash
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
nano /etc/fail2ban/jail.local
```

Scroll down to the `[sshd]` section and make sure it is enabled and listening on our custom port:
```plaintext
[sshd]
enabled = true
port    = 4242
```

Scroll down to the `[vsftpd]` section and enable it as well:
```plaintext
[vsftpd]
enabled = true
```

Save and exit. Restart the service to apply the bans:
```bash
systemctl restart fail2ban
fail2ban-client status
```

> **[Insert Screenshot: Output of `fail2ban-client status` showing both the sshd and vsftpd jails are active]**

### 7. Evaluation Prep: Live Testing the Bonus Services
The evaluator will demand that you prove these services are actually working. Here is the exact script to follow to demonstrate each service perfectly:

#### Test 1: Lighttpd, PHP, and MariaDB (The WordPress Site)
* **The Proof:** By successfully loading the WordPress site, you prove that all three of these services are working together seamlessly. Lighttpd is serving the web pages, PHP is processing the code, and MariaDB is storing the configuration.
* **The Action:** 1. On your **Host Machine** (your physical computer), open a web browser.
  2. Navigate to `http://localhost:8080` (ensure you mapped Host Port `8080` to Guest Port `80` in VirtualBox).
  3. Show the evaluator the functioning WordPress site. Create a test post to prove the database is actively writing data!

> **[Insert Screenshot: Your host machine's browser showing a published WordPress test post]**

#### Test 2: vsftpd (File Transfer)
* **The Proof:** You must show that the `ftpuser` can connect, upload a file, and is securely locked (chrooted) into the `/srv/wordpress` directory.
* **The Action:**
  1. In VirtualBox, add a new Port Forwarding rule (Host Port: `2121`, Guest Port: `21`).
  2. On your **Host Machine**, open an FTP client (like FileZilla) or use the terminal: `ftp localhost 2121`.
  3. Log in with the `ftpuser` credentials. 
  4. Upload a random text file (e.g., `test_upload.txt`).
  5. On your **Virtual Machine**, navigate to `/srv/wordpress` and type `ls -l` to prove the file successfully arrived!

> **[Insert Screenshot: Terminal on the VM showing the newly uploaded file sitting in the /srv/wordpress directory]**

#### Test 3: Fail2ban (The Security Service)
* **The Proof:** You must intentionally trigger Fail2ban to prove it is actively monitoring logs and blocking malicious attacks.
* **The Action:**
  1. On your **Host Machine**, open a terminal and try to SSH into your server: `ssh maaugust@localhost -p 4242`.
  2. Intentionally type the **WRONG password** 3 to 5 times until the connection drops or hangs.
  3. On your **Virtual Machine**, check the Fail2ban status:
     ```bash
     sudo fail2ban-client status sshd
     ```
  4. You will see your Host Machine's gateway IP (usually `10.0.2.2`) listed under **Banned IP list**!
  5. **To unban yourself (so you can use SSH again):**
     ```bash
     sudo fail2ban-client set sshd unbanip 10.0.2.2
     ```

> **[Insert Screenshot: The output of the fail2ban-client command showing the actively banned IP address]**

---

**🎉 Congratulations!**

If you have followed this guide exactly, your Debian server is a perfectly secure, automated, and strictly partitioned masterpiece. You are fully prepared to pass the Born2beroot evaluation with a **125% Bonus score**!
