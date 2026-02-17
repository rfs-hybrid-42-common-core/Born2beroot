#!/bin/bash

# Architecture
arc=$(uname -a)

# Physical CPUs (Filters unique IDs to prevent overcounting on multi-core)
pcpu=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)

# Virtual CPUs
vcpu=$(grep "^processor" /proc/cpuinfo | wc -l)

# RAM (Calls free once, formats directly into "Used/TotalMB (Percent%)")
ram=$(free -m | awk '$1 == "Mem:" {printf "%d/%dMB (%.2f%%)", $3, $2, $3/$2*100}')

# Disk (Calls df once, skips /boot, sums data, formats Gb and Percent)
disk=$(df -m | grep "^/dev/" | grep -v "/boot$" | awk '{ut += $3; tt += $2} END {printf "%d/%dGb (%d%%)", ut, tt/1024, ut/tt*100}')

# CPU Load (Grabs the global Cpu line, subtracts the 8th column 'idle' from 100)
cpul=$(top -bn1 | grep '^%Cpu' | awk '{printf "%.1f%%", 100 - $8}')

# Last boot
lb=$(who -b | awk '$1 == "system" {print $3 " " $4}')

# LVM
lvmu=$(if [ $(lsblk | grep "lvm" | wc -l) -gt 0 ]; then echo yes; else echo no; fi)

# TCP Connections
tcpc=$(ss -ta | grep ESTAB | wc -l)

# Users
ulog=$(users | wc -w)

# IP and MAC address (Grabs only the first IP string to avoid trailing spaces)
ip=$(hostname -I | awk '{print $1}')
mac=$(ip link | grep "link/ether" | awk '{print $2}')

# Sudo
cmds=$(journalctl _COMM=sudo | grep COMMAND | wc -l)

# Broadcast
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
