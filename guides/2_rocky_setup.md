# 🪨 Rocky Linux Installation & Setup Guide (Bonus Included)

This step-by-step guide will walk you through setting up a headless Rocky Linux virtual machine that perfectly satisfies both the mandatory and bonus requirements of the Born2beroot project.

## 📑 Table of Contents
1. [Phase 1: Virtual Machine Creation](#-phase-1-virtual-machine-creation)
2. [Phase 2: OS Installation & Encrypted LVM](#-phase-2-os-installation--encrypted-lvm-bonus-layout)
3. [Phase 3: Base Configuration & Sudo Setup](#-phase-3-base-configuration--sudo-setup)
4. [Phase 4: SSH, Firewalld & SELinux Configuration](#-phase-4-ssh-firewalld--selinux-configuration)
5. [Phase 5: Password Policy & User Management](#-phase-5-password-policy--user-management)
6. [Phase 6: The Monitoring Script](#-phase-6-the-monitoring-script)
7. [Phase 7: Bonus Services (WordPress & FTP)](#-phase-7-bonus-services-wordpress--ftp)

---

## 💿 Phase 1: Virtual Machine Creation

### Prerequisite: Download the ISO
Ensure you have downloaded the **Rocky Linux Minimal ISO** directly from the official Rocky Linux website (e.g., `Rocky-9.x-x86_64-minimal.iso`).

### Setting up VirtualBox
1. Open **VirtualBox** and click **New**.
2. **Name:** Enter your machine name (e.g., `maaugust_born2beroot_rocky`).
3. **ISO Image:** Choose the `Rocky-minimal.iso` file you just downloaded.
4. ⚠️ **CRITICAL STEP:** You MUST check the box that says **Skip Unattended Installation**.
5. Click **Next**. Allocate at least **1024 MB** of RAM and 1 CPU.
6. Click **Next**. Create a **30 GB** dynamically allocated Virtual Hard Disk (required for the bonus layout). Click **Finish**.
7. Select your newly created VM and click **Settings**.
8. Go to **Network** and ensure Adapter 1 is set to **NAT**. Click **Advanced** and set up **Port Forwarding**:
   * **SSH:** Host Port `4242` -> Guest Port `4242`
   * **HTTP (Bonus):** Host Port `8080` -> Guest Port `80`
   * **FTP (Bonus):** Host Port `2121` -> Guest Port `21`

> **[Insert Screenshot: VirtualBox Port Forwarding Rules showing the three port mappings]**

---

## 🏗️ Phase 2: OS Installation & Encrypted LVM (Bonus Layout)
Start your virtual machine and select **Install Rocky Linux**. Rocky uses the "Anaconda" installer. 

### Localization & User Setup
1. **Language:** Select your preferred language.
2. **Root Password:** Click this, set a strong password, and check "Lock root account". 
3. **User Creation:** Create your user (e.g., `maaugust`). Check **"Make this user administrator"**. Set your user password.

### Software Selection
1. Click **Software Selection**.
2. Ensure **"Minimal Install"** is selected on the left. Leave all right-side options unchecked to guarantee a headless environment.

> **[Insert Screenshot: Software Selection screen showing Minimal Install]**

### Partitioning Disks (The Most Critical Step)
1. Click **Installation Destination**.
2. Select your 30GB disk. Under Storage Configuration, select **Custom**, then click **Done** at the top left.

3. A new menu opens. Change the dropdown from "LVM" to **LVM Thin Provisioning** or standard **LVM** (Standard LVM is recommended for this project). Check the **Encrypt** box.
4. Click the blue link: **"Click here to create them automatically"**. Enter your Encryption Passphrase.
5. Anaconda will generate default partitions. **You must delete the `/home` and `/` (root) partitions to redistribute the space manually.**
6. Click the `+` button to create the required Bonus Logical Volumes:
   * **Mount Point:** `/` | **Capacity:** `10G`
   * **Mount Point:** `/home` | **Capacity:** `5G`
   * **Mount Point:** `/var` | **Capacity:** `3G`
   * **Mount Point:** `/tmp` | **Capacity:** `3G`
   * **Mount Point:** `/srv` | **Capacity:** `3G`
   * **Mount Point:** `/var/log` | **Capacity:** `4G`
   * *(Note: Keep the automatically generated `/boot` and `swap` partitions).*
7. Click **Done**, then click **Accept Changes**.

> **[Insert Screenshot: The Custom Partitioning screen showing all 7 required logical volumes mapped out]**

8. Click **Begin Installation**. Once finished, reboot the system.

---

## 🛠️ Phase 3: Base Configuration & Sudo Setup
Log in with your user account (`maaugust`) and your user password. Since you checked "Make this user administrator," you can use `sudo`.

### 1. Update the System
Rocky Linux uses `dnf` instead of `apt`.
```bash
sudo dnf update -y
```

### 2. Group Management
In Rocky Linux, administrators are added to the `wheel` group by default, but the 42 subject specifically requires the `sudo` and `user42` groups.
```bash
# Create the required groups
sudo groupadd user42
sudo groupadd sudo

# Add your user to the groups
sudo usermod -aG sudo,user42 maaugust

# Verify the groups
groups maaugust
```

> **[Insert Screenshot: Output of the `groups maaugust` command showing user42 and sudo]**

### 3. Strict Sudo Configuration
```bash
sudo mkdir -p /var/log/sudo
sudo visudo
```

In Rocky, you must first tell `sudo` to recognize the `sudo` group. Find the line that allows people in group wheel to run all commands (`%wheel ALL=(ALL) ALL`), and add this directly below it:

```plaintext
%sudo   ALL=(ALL)       ALL
```

Next, add our strict subject requirements. Add these `Defaults` lines:
```plaintext
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults        passwd_tries=3
Defaults        badpass_message="Wrong password! This incident will be reported."
Defaults        requiretty
Defaults        logfile="/var/log/sudo/sudo.log"
```

Save and exit (`:wq` if using vi/vim).

> **[Insert Screenshot: The visudo file showing the new %sudo rule and the custom Defaults]**

### 4. Verify SELinux is Running
SELinux is the Mandatory Access Control system for Rocky Linux. It is enabled by default.
```bash
sestatus
```

> **[Insert Screenshot: Output of `sestatus` showing the current mode as "enforcing"]**

---

## 🛡️ Phase 4: SSH, Firewalld & SELinux Configuration

### 1. Configure Firewalld
Rocky uses `firewalld` instead of UFW.

```bash
# Check if it is running
sudo systemctl status firewalld

# Allow our custom SSH port and remove the default port 22
sudo firewall-cmd --permanent --add-port=4242/tcp
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --reload

# Verify the rules
sudo firewall-cmd --list-all
```

> **[Insert Screenshot: Output of `firewall-cmd --list-all` showing port 4242/tcp is open]**

### 2. Configure SELinux for SSH (Critical Step)
If you change the SSH port without telling SELinux, it will aggressively block the SSH service from starting.
```bash
# Install the SELinux management tools
sudo dnf install policycoreutils-python-utils -y

# Tell SELinux that port 4242 is officially an SSH port
sudo semanage port -a -t ssh_port_t -p tcp 4242
```

### 3. Configure SSH
Now we can safely change the port in the configuration file.
```bash
sudo vi /etc/ssh/sshd_config
```

Find and modify (uncomment) these lines:
```plaintext
Port 4242
PermitRootLogin no
```

Save and exit, then restart the service:
```bash
sudo systemctl restart sshd
```

> **[Insert Screenshot: The modified sshd_config file]**

### 4. Test Your Connection
Open a terminal on your Host Machine:
```bash
ssh maaugust@localhost -p 4242
```

If you connect successfully, your Firewalld and SELinux port context configurations are perfect!

---

## 🔐 Phase 5: Password Policy & User Management

The subject requires a highly strict password policy: passwords must expire every 30 days, have a minimum of 2 days between changes, send a 7-day warning, and require at least 10 characters with specific complexity (uppercase, lowercase, numeric, max 3 identical consecutive characters, no usernames, and 7 characters different from the previous password).

### 1. Configure Password Expiration (Aging)
First, we modify the default expiration rules for all *newly created* users.
Open the login definitions file:
```bash
sudo vi /etc/login.defs
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
sudo chage -m 2 -M 30 -W 7 root

# Apply to your user
sudo chage -m 2 -M 30 -W 7 maaugust

# Verify the changes for your user
sudo chage -l maaugust
```

> **[Insert Screenshot: Output of `chage -l maaugust` showing the 30-day expiration policy]**

### 2. Configure Password Complexity
On Rocky Linux, we use the `libpwquality` library. It reads from a dedicated configuration file, making it much easier to manage than Debian's PAM files.
```bash
sudo dnf install libpwquality -y
```

Now, edit the password quality configuration file:
```bash
sudo vi /etc/security/pwquality.conf
```

Uncomment and modify the following lines to match the subject's strict rules exactly:
```plaintext
difok = 7
minlen = 10
dcredit = -1
ucredit = -1
lcredit = -1
maxrepeat = 3
usercheck = 1
enforce_for_root
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
The bash script to scrape system information relies entirely on standard Linux commands, so the script we wrote for Debian will work flawlessly on Rocky Linux without any changes!

### 1. Create the Script
Create the script in the `/usr/local/bin` directory:
```bash
sudo vi /usr/local/bin/monitoring.sh
```

Paste your optimized bash script (Press `i` to enter insert mode):
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

Save and exit (Press `Esc`, then `:wq`). Now, make the script executable:
```bash
sudo chmod +x /usr/local/bin/monitoring.sh
```

### 2. Schedule the Script with Cron
We will use `cron` to execute this script. Just like in Debian, we will use an advanced configuration to ensure it triggers at **startup** and exactly every 10 minutes **from the boot time**.

Rocky minimal might require installing the cron daemon manually:
```bash
sudo dnf install cronie -y
sudo systemctl enable --now crond
```

Now, open the root crontab:
```bash
sudo crontab -e
```

Add the following rules:
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
To ensure it works without waiting 10 minutes, run it manually:
```bash
/usr/local/bin/monitoring.sh
```

You should see the wall broadcast pop up on your terminal instantly.

> **[Insert Screenshot: The output of the monitoring script perfectly matching the subject's example format]**

---

## 🌟 Phase 7: Bonus Services (WordPress & FTP)

To achieve the bonus, we must set up a functional WordPress website using Lighttpd, MariaDB, and PHP (a LEMP stack) . We also need to configure an FTP service (vsftpd) and a security service (Fail2ban) to protect them.

### 🧠 Evaluation Prep: Defending Your Bonus Choices
During the defense, the evaluator will ask you to explain exactly what these services do and **why you chose them** (especially your "free-choice" service). Here is how you answer:

* **Lighttpd (Web Server):** The subject strictly forbids using the industry standards, Apache2 and NGINX. Lighttpd is the optimal alternative because it is exceptionally fast, uses a tiny memory footprint, and seamlessly handles PHP via FastCGI.
* **MariaDB (Database):** A fully open-source, highly secure, drop-in replacement for MySQL. It is required to store all of WordPress's dynamic data, user accounts, and settings.
* **PHP:** A server-side scripting language. Since the core of WordPress is written in PHP, this processor is mandatory to dynamically generate the HTML web pages and communicate with the MariaDB database.
* **vsftpd (File Transfer):** Stands for "Very Secure FTP Daemon". I chose this because of its incredibly strict security defaults. It allows us to easily "jail" (chroot) our FTP user, guaranteeing they can only upload files to the `/srv/wordpress` directory.
* **Fail2ban (The "Free-Choice" Service):** An active intrusion prevention framework . I chose this as my extra service because it perfectly aligns with the project's core theme of extreme server security. By opening new ports (80 and 21), we increased our attack surface. Fail2ban monitors our service logs in real-time and automatically bans the IP addresses of attackers trying to brute-force our SSH or FTP passwords.

### 1. Update the Firewall
Our new services need specific ports open to communicate with the outside world.
```bash
# Allow HTTP (Web Server) and FTP
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=21/tcp
sudo firewall-cmd --reload

# Verify the new rules
sudo firewall-cmd --list-all
```

### 2. Install the LEMP Stack (Lighttpd, MariaDB, PHP)
On Rocky Linux, Lighttpd and Fail2ban are housed in the EPEL (Extra Packages for Enterprise Linux) repository. We must install that first:
```bash
sudo dnf install epel-release -y
sudo dnf update -y
```

Now, install the core packages:
```bash
sudo dnf install lighttpd lighttpd-fastcgi mariadb-server php php-fpm php-mysqlnd wget -y
```

**⚠️ Link Lighttpd to PHP:**

Rocky does not auto-configure PHP for Lighttpd. We must do it manually.
```bash
sudo vi /etc/lighttpd/modules.conf
```

Find the line `#include "conf.d/fastcgi.conf"` and **uncomment it** (remove the `#`). Save and exit.

Next, configure the FastCGI module to use PHP-FPM:
```bash
sudo vi /etc/lighttpd/conf.d/fastcgi.conf
```

Add the following block at the bottom of the file to map PHP requests to the PHP-FPM processor:
```plaintext
fastcgi.server += ( ".php" =>
        ((
                "host" => "127.0.0.1",
                "port" => "9000",
                "broken-scriptfilename" => "enable"
        ))
)
```

Save and exit. Now, enable and start all the services:
```bash
sudo systemctl enable --now lighttpd mariadb php-fpm
```

### 3. Configure the MariaDB Database
Secure the database installation:
```bash
sudo mysql_secure_installation
```

*(Press `Enter` for current password, then answer `Y` to set a root password and `Y` to all subsequent security questions).*

Next, log into the MySQL console to create the WordPress database and user:
```bash
mysql -u root -p
```

Run the following SQL commands exactly as written:
```sql
CREATE DATABASE wordpress;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'YourStrongPassword123!';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

> **[Insert Screenshot: The MariaDB console showing the successful creation of the database and user]**

### 4. Install WordPress & Configure SELinux (CRITICAL)
Download WordPress and place it inside the `/srv` partition we created during Phase 2.
```bash
wget https://wordpress.org/latest.tar.gz
sudo tar -xzvf latest.tar.gz -C /srv/
rm latest.tar.gz
```

Change Lighttpd's document root to point to our bonus partition:
```bash
sudo vi /etc/lighttpd/lighttpd.conf
```

Find `server.document-root = "/var/www/lighttpd"` and change it to:
```plaintext
server.document-root        = "/srv/wordpress"
```

Save and exit, then restart the web server:
```bash
sudo systemctl restart lighttpd
```

**⚠️ The SELinux Web Configuration:**

If you try to load the website right now, SELinux will block it. We must explicitly tell SELinux that the web server is allowed to read the `/srv/wordpress` directory AND connect to the MariaDB database.
```bash
# Allow the web server to connect to the database
sudo setsebool -P httpd_can_network_connect_db 1

# Change the SELinux security context of the WordPress folder so Lighttpd can read/write to it
sudo semanage fcontext -a -t httpd_sys_rw_content_t "/srv/wordpress(/.*)?"
sudo restorecon -Rv /srv/wordpress

# Give the web server standard ownership of the files
sudo chown -R lighttpd:lighttpd /srv/wordpress
```

Finally, configure the WordPress connection:
```bash
sudo cp /srv/wordpress/wp-config-sample.php /srv/wordpress/wp-config.php
sudo vi /srv/wordpress/wp-config.php
```

Update these three specific lines with your database info:
```php
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'wp_user' );
define( 'DB_PASSWORD', 'YourStrongPassword123!' );
```

Save and exit. Test it on your Host Machine browser at `http://localhost:8080`!

> **[Insert Screenshot: The WordPress welcome screen in your browser]**

### 5. Set up the FTP Server (vsftpd)
```bash
sudo dnf install vsftpd -y
```

Configure the FTP daemon:
```bash
sudo vi /etc/vsftpd/vsftpd.conf
```

Modify these specific lines to lock the FTP user in securely:
```plaintext
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
userlist_enable=YES
userlist_file=/etc/vsftpd/user_list
userlist_deny=NO
```

Save and exit.

**⚠️ The SELinux FTP Configuration:**

SELinux will block FTP users from reading or writing files outside of their standard home directories by default. We must allow it.
```bash
sudo setsebool -P ftpd_full_access 1
```

Create the FTP user and assign ownership:
```bash
# Create the user (it will prompt you to set a password)
sudo adduser ftpuser
sudo passwd ftpuser

# Add the user to the allowed FTP list
echo "ftpuser" | sudo tee -a /etc/vsftpd/user_list

# Set the user's home directory to our WordPress folder
sudo usermod -d /srv/wordpress ftpuser

# Restart and enable the service
sudo systemctl enable --now vsftpd
```

> **[Insert Screenshot: Using FileZilla to successfully log into the VM as 'ftpuser' on port 21]**

### 6. Set up Fail2ban (Extra Security Bonus)
```bash
sudo dnf install fail2ban -y
```

Copy the jail configuration and edit it:
```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo vi /etc/fail2ban/jail.local
```

Scroll down to the `[sshd]` section and make sure it is enabled on our custom port:
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

Save and exit. Restart the service:
```bash
sudo systemctl enable --now fail2ban
sudo fail2ban-client status
```

> **[Insert Screenshot: Output of `fail2ban-client status` showing the active jails]**

### 7. Evaluation Prep: Live Testing the Bonus Services
Follow these exact steps during your defense to prove your services work:

**Test 1: The WordPress Site**
1. On your **Host Machine**, navigate to `http://localhost:8080`.
2. Show the evaluator the functioning WordPress site. Create a test post to prove the database is actively writing data!

> **[Insert Screenshot: A published WordPress test post]**

**Test 2: vsftpd (File Transfer)**
1. On your **Host Machine**, open an FTP client (like FileZilla) or terminal: `ftp localhost 2121`.
2. Log in with the `ftpuser` credentials. Upload a text file (e.g., `test_upload.txt`).
3. On your **Virtual Machine**, type `ls -l /srv/wordpress` to prove the file successfully arrived!

> **[Insert Screenshot: Terminal showing the newly uploaded file in /srv/wordpress]**

**Test 3: Fail2ban (The Security Service)**
1. On your **Host Machine**, try to SSH into your server: `ssh maaugust@localhost -p 4242`.
2. Intentionally type the **WRONG password** 3 to 5 times.
3. On your **Virtual Machine**, check the Fail2ban status:
```bash
sudo fail2ban-client status sshd
```
4. Point out your Host's gateway IP in the **Banned IP list**.
5. **To unban yourself:**
```bash
sudo fail2ban-client set sshd unbanip 10.0.2.2
```

> **[Insert Screenshot: fail2ban-client showing the banned IP address]**

---

**🎉 Congratulations!**

If you have followed this guide, you have successfully conquered the notorious SELinux and built a completely fortified, enterprise-grade Rocky Linux server. You are ready to ace the Born2beroot evaluation!
