*This project has been created as part of the 42 curriculum by maaugust.*

<div align="center">
  <img src="assets/cover-born2beroot-bonus.png" alt="Born2beroot Cover" width="100%" />
</div>

<div align="center">
  <h1>🖥️ Born2beroot: A System Administration Masterclass</h1>
  <img src="https://img.shields.io/badge/System-Linux-blue" />
  <img src="https://img.shields.io/badge/Grade-125%2F100-success" />
  <img src="https://img.shields.io/badge/Bonus-Included-success" />
</div>

---

## 💡 Description
**Born2beroot** is a System Administration project in the 42 curriculum designed to introduce the fundamentals of virtualization, server configuration, and strict security policies.

The goal of this project is to build a secure, headless virtual machine from scratch using either Debian or Rocky Linux. This repository serves as a comprehensive theoretical index and provides complete, step-by-step installation guides to achieve a perfect mandatory and bonus score.

### 🏗️ Main Design Choices
* **Partitioning:** Encrypted Logical Volume Management (LVM) was utilized to create flexible, secure partitions separating critical system directories (e.g., `/var`, `/home`, `/srv`).
* **Security Policies:** The system strictly enforces a 30-day password expiration policy, complex character requirements, and UFW/firewalld constraints. SSH is restricted to port 4242 with root login disabled.
* **User Management:** Standard operations are segregated from root privileges via the `user42` and `sudo` groups, with sudo actions strictly logged and path-restricted.
* **Bonus Services:** Includes a full LEMP/LAMP stack (Lighttpd, MariaDB, PHP) for a functional WordPress site, plus an additional FTP service secured by Fail2ban.

---

## ⚖️ Theoretical Comparisons (Mandatory)
*As required by the subject, below are the theoretical breakdowns of the core technologies utilized and evaluated in this project.*

### 💡 Pre-requisite: The Benefits of Virtual Machines
Before diving into the operating systems, it is crucial to understand why we use Virtual Machines (VMs) for system administration. A VM is a software emulation of a physical computer. 
* **Isolation & Security (Sandboxing):** A VM runs in an isolated environment. If you accidentally execute malware or destroy the operating system inside the VM, your host computer remains completely unaffected.
* **Hardware Abstraction:** VMs use virtualized hardware. You can easily allocate or remove RAM, CPU cores, or storage space without touching physical components.
* **Snapshots & Rollbacks:** VMs allow you to save the exact state of the machine at a specific point in time (a snapshot). If an update or configuration breaks the system, you can instantly revert to the working snapshot.
* **Portability:** A VM is essentially just a set of files. You can copy a VM from a Windows machine and run it flawlessly on a macOS or Linux machine.

### 1. Debian vs. Rocky Linux
The subject requires choosing between Debian and Rocky Linux. While this repository provides guides for both, understanding their fundamental differences is required for the defense.

| Feature | Debian | Rocky Linux |
| :--- | :--- | :--- |
| **Family** | Debian-based (Independent) | RHEL-based (Red Hat Enterprise Linux) |
| **Focus** | Extreme stability, open-source community | Enterprise-level production, corporate servers |
| **Package Format** | `.deb` | `.rpm` |
| **Primary Package Manager**| `apt` / `aptitude` | `dnf` |
| **Security Module** | AppArmor (Mandatory per subject) | SELinux (Mandatory per subject) |
| **Release Cycle** | Slow and highly tested | Bug-for-bug compatible with RHEL releases |

**Why choose Debian? (Pros & Cons)**
* **Advantages:** Debian is widely considered one of the most stable operating systems in existence. It has a massive community, extensive documentation, and is highly recommended for beginners. It uses less memory out-of-the-box compared to Rocky.
* **Disadvantages:** Because its priority is stability, Debian's software packages are often older. It sacrifices cutting-edge features for reliability.
* **Evaluation Prep - `apt` vs. `aptitude`:** * **`apt` (Advanced Package Tool):** The standard, lower-level command-line tool used to handle packages. It is straightforward and handles most installations and updates smoothly.
  * **`aptitude`:** A high-level, interactive front-end package manager. While `apt` might simply fail or give up when encountering a complex dependency conflict, `aptitude` uses a more aggressive search algorithm to suggest multiple potential resolutions to the user. 

**Why choose Rocky Linux? (Pros & Cons)**
* **Advantages:** Rocky Linux is a downstream, completely free, and bug-for-bug compatible clone of Red Hat Enterprise Linux (RHEL). If you want to train for a corporate IT environment that relies on Red Hat, Rocky is the perfect choice. 
* **Disadvantages:** It is significantly more complex to set up and maintain than Debian, largely due to the strictness of its default security module (SELinux).
* **Evaluation Prep - What is DNF?** * **`dnf` (Dandified YUM):** It is the next-generation package manager for RPM-based Linux distributions. It replaced the older `yum` package manager because `dnf` performs much faster, uses significantly less memory, and features a completely rewritten algorithm for resolving complex software dependencies.

### 2. AppArmor vs. SELinux
Both AppArmor and SELinux are **Mandatory Access Control (MAC)** systems. In a standard Linux environment (which uses Discretionary Access Control or DAC), a user can do whatever they want with a file if they own it. A MAC system overrides this: it restricts the actions of specific *programs* and *services*, regardless of which user is running them. If a service is compromised, the MAC system prevents it from accessing files outside of its strict permissions.

| Feature | AppArmor | SELinux |
| :--- | :--- | :--- |
| **Default OS** | Debian, Ubuntu | Rocky Linux, RHEL, CentOS |
| **Control Method** | **Path-based:** Restricts access based on file paths (e.g., `/etc/passwd`). | **Label-based:** Restricts access based on inodes/labels attached to files. |
| **Complexity** | Easier to learn, uses human-readable profiles. | Highly complex, uses deep system-wide policies and contexts. |
| **Operational Modes** | Enforce, Complain | Enforcing, Permissive, Disabled |

**Evaluation Prep - AppArmor (If you chose Debian)**
* **What is it?** AppArmor (Application Armor) is a kernel security module that restricts programs' capabilities with per-program profiles. It is heavily utilized in Debian to contain malicious behavior.
* **How it works:** You grant a program (like a web server) a specific "profile." If the web server tries to read a file that isn't explicitly allowed by its profile, AppArmor blocks it.
* **Useful Command:** `aa-status` displays the current state of AppArmor, showing exactly which profiles are loaded and actively enforcing rules.

**Evaluation Prep - SELinux (If you chose Rocky Linux)**
* **What is it?** SELinux (Security-Enhanced Linux) is a highly robust security architecture built into the Linux kernel, originally developed by the NSA. It is mandatory for the Rocky Linux setup.
* **How it works:** Every single file, process, and port on the system is assigned a special security label (a context). A process can only interact with a file if a strict SELinux policy explicitly allows their specific labels to communicate. If you move a file to a web directory without updating its label, the web server cannot read it, even if the file has 777 permissions!
* **Useful Command:** `sestatus` displays the current status of SELinux and confirms if it is running in "enforcing" mode.

### 3. UFW vs. firewalld
A firewall is a network security system that monitors and controls incoming and outgoing network traffic based on predetermined security rules. Both UFW and firewalld are essentially user-friendly front-end management tools that interact with the Linux kernel's underlying packet filtering system (like `iptables` or `nftables`). 

| Feature | UFW (Uncomplicated Firewall) | firewalld |
| :--- | :--- | :--- |
| **Default OS** | Debian, Ubuntu | Rocky Linux, RHEL, CentOS |
| **Design Philosophy** | Simplicity and ease of use for standalone servers. | Flexibility and dynamic management for complex networks. |
| **Rule Management** | Rule-based (allows or denies traffic on specific ports/IPs). | Zone-based (assigns network interfaces to trust zones like "public" or "home"). |
| **Updates** | Requires reloading the firewall to apply new rules (drops active connections). | Dynamic updates (applies new rules instantly without dropping active connections). |

**Evaluation Prep - UFW (If you chose Debian)**
* **What is it?** UFW was designed to make configuring `iptables` easier for system administrators. Instead of writing complex chains, you simply declare what ports to open. 
* **Project Context:** You are required to strictly limit access to the VM to SSH via port 4242.
* **Useful Command:** `sudo ufw status numbered` displays whether the firewall is active and lists all currently enforced rules (you should only see port 4242 allowed).

**Evaluation Prep - firewalld (If you chose Rocky Linux)**
* **What is it?** firewalld is a firewall manager that uses "zones" to define the trust level of network connections or interfaces. It is the default for Rocky Linux.
* **Project Context:** Just like UFW, it is used here to lock down the server, allowing only port 4242.
* **Useful Commands:** * `sudo firewall-cmd --state` checks if firewalld is running.
  * `sudo firewall-cmd --list-ports` shows the actively opened ports (should display `4242/tcp`).

### 4. VirtualBox vs. UTM
To run a virtual machine, you need a piece of software called a **Hypervisor** (also known as a Virtual Machine Monitor). Both VirtualBox and UTM act as Type 2 Hypervisors, meaning they run as applications on top of your existing host Operating System (Windows, macOS, or Linux). 

| Feature | VirtualBox | UTM |
| :--- | :--- | :--- |
| **Developer** | Oracle | UTM (Open Source Community) |
| **Underlying Tech** | Custom VirtualBox Engine | QEMU (an open-source machine emulator) |
| **Target Host OS** | Windows, Linux, older Intel Macs | macOS (specifically Apple Silicon / M-series chips), iOS |
| **Architecture** | Virtualizes x86/amd64 architectures perfectly. | Emulates x86/amd64 and virtualizes ARM64 architectures natively. |

**Evaluation Prep - VirtualBox**
* **What is it?** A powerful, free, and cross-platform virtualization product for enterprise as well as home use. It is the primary mandatory hypervisor for the Born2beroot project.
* **Project Context:** If you are using a Windows PC, a Linux machine, or an older Mac with an Intel processor, you must use VirtualBox. It directly virtualizes the x86/amd64 instructions of the Debian/Rocky ISOs.

**Evaluation Prep - UTM**
* **What is it?** UTM is a full-featured system emulator and virtual machine host for iOS and macOS. It is explicitly allowed by the subject *only* if you cannot use VirtualBox.
* **Why would you need it?** VirtualBox does not support Apple's new ARM-based Silicon processors (M1, M2, M3, etc.). If you have a newer Mac, you physically cannot run the x86 versions of Debian or Rocky natively through VirtualBox. UTM solves this by utilizing **QEMU** under the hood to fully *emulate* the required architecture, allowing M-series Macs to complete the project.

---

## 🛠️ Instructions & Guides

Because the setup process differs significantly depending on the chosen operating system, the step-by-step tutorials have been separated into dedicated guides. Click the guide for your chosen OS below:

### 📖 Step-by-Step Installation Guides
* [**👉 CLICK HERE for the Debian Setup Guide (Recommended)**](./guides/1_debian_setup.md)
* [**👉 CLICK HERE for the Rocky Linux Setup Guide**](./guides/2_rocky_setup.md)

### 🔑 Validating the Machine Signature
At the root of this repository is a `signature.txt` file containing the SHA1 hash of the virtual machine's `.vdi` disk. To extract and verify your own signature for evaluation, use the following commands based on your host OS:

**Linux / MacOS:**
```bash
shasum /path/to/your/VirtualBox\ VMs/machine_name/machine_disk.vdi
```

**Windows:**
```DOS
certUtil -hashfile "C:\path\to\VirtualBox VMs\machine_name\machine_disk.vdi" sha1
```

*(Note: Booting the virtual machine alters the signature. Ensure you take a snapshot immediately after extracting your signature!)*

---

## 📚 Resources & References
* `man sudoers`
* `man ufw` / `man firewalld`
* `man cron`
* [Debian Official Documentation](https://www.debian.org/doc/)
* [Rocky Linux Official Documentation](https://docs.rockylinux.org/)

### 🤖 AI Usage Guidelines
*Per the subject requirements:*
* **Tasks:** AI tools were utilized to structure this README, generate the theoretical comparison tables required by the subject, and to brainstorm the bash syntax for the complex awk/grep text scraping in the `monitoring.sh` script.
* **Execution:** All virtual machine configurations, LVM partitioning, service installations, and security policy enforcements were manually executed, tested, and documented via screenshots.
