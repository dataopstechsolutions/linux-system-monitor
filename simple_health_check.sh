#!/bin/bash

################################################################################
# Simple Linux Server Health Check Script
# Easy to understand version - checks uptime, patches, CPU, and RAM
# Author: System Administrator
################################################################################

# Clear the screen to start fresh
clear

# Print a nice title
echo "================================"
echo "  Linux Server Health Check"
echo "================================"
echo ""

################################################################################
# 1. CHECK SERVER UPTIME
################################################################################
echo "--- SERVER UPTIME ---"
echo ""

# Get uptime using the uptime command
uptime_output=$(uptime)
echo "Uptime Status: $uptime_output"

# Get last boot time
echo ""
echo "Last Boot Time:"
who -b

echo ""
echo ""

################################################################################
# 2. CHECK LAST PATCH/UPDATE DATE
################################################################################
echo "--- LAST PATCH / UPDATE DATE ---"
echo ""

# Check if system uses apt (Debian/Ubuntu)
if [ -f /var/log/apt/history.log ]; then
    echo "System Type: Debian/Ubuntu (uses apt)"
    echo ""
    echo "Last Update Date:"
    grep "Start-Date:" /var/log/apt/history.log | tail -1
    echo ""
    
# Check if system uses yum (RHEL/CentOS)
elif [ -f /var/log/yum.log ]; then
    echo "System Type: RHEL/CentOS (uses yum)"
    echo ""
    echo "Last Update Date:"
    tail -1 /var/log/yum.log
    echo ""
    
# Check if system uses dnf (Fedora)
elif [ -f /var/log/dnf.rpm.log ]; then
    echo "System Type: Fedora (uses dnf)"
    echo ""
    echo "Last Update Date:"
    tail -1 /var/log/dnf.rpm.log
    echo ""
else
    echo "Could not find update logs on this system"
    echo ""
fi

echo ""

################################################################################
# 3. SYSTEM DETAILS/INFORMATION
################################################################################
echo "--- SYSTEM DETAILS ---"
echo ""

# Get hostname (server name)
echo "Hostname (Server Name):"
hostname
echo ""

# Get operating system name
echo "Operating System:"
cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"'
echo ""

# Get kernel version
echo "Kernel Version:"
uname -r
echo ""

# Get architecture (32-bit or 64-bit)
echo "Architecture:"
uname -m
echo ""

# Get system uptime in days, hours, minutes format
echo "System Uptime Details:"
uptime -p
echo ""

echo ""

################################################################################
# 4. CPU INFORMATION & USAGE
################################################################################
echo "--- CPU INFORMATION ---"
echo ""

# Get number of CPU cores
cpu_cores=$(nproc)
echo "Total CPU Cores: $cpu_cores"
echo ""

# Get CPU model name
echo "CPU Model Name:"
lscpu | grep "Model name" | cut -d':' -f2
echo ""

# Get CPU frequency
echo "CPU Maximum Frequency:"
lscpu | grep "CPU max MHz" | cut -d':' -f2
echo ""

# Get current CPU usage
echo "Current CPU Usage:"
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "CPU Usage: " (100 - $1) "%"}'
echo ""

# Get load average
echo "Load Average (1min, 5min, 15min):"
uptime | awk -F'load average:' '{print $2}'
echo ""

echo ""

################################################################################
# 5. MEMORY (RAM) USAGE
################################################################################
echo "--- MEMORY (RAM) USAGE ---"
echo ""

# Get total RAM
echo "Total Memory Available:"
free -h | grep Mem | awk '{print $2}'
echo ""

# Get used RAM
echo "Memory Currently Used:"
free -h | grep Mem | awk '{print $3}'
echo ""

# Get free RAM
echo "Memory Still Available (Free):"
free -h | grep Mem | awk '{print $4}'
echo ""

# Get memory usage percentage
echo "Memory Usage Percentage:"
free | grep Mem | awk '{printf "%.2f%%\n", ($3/$2) * 100}'
echo ""

# Get swap memory
echo "Swap Memory (Total):"
free -h | grep Swap | awk '{print $2}'
echo ""

# Get swap memory used
echo "Swap Memory (Used):"
free -h | grep Swap | awk '{print $3}'
echo ""

# Get cached memory
echo "Cached Memory (can be freed):"
free -h | grep Mem | awk '{print $6}'
echo ""

echo ""

################################################################################
# 6. DETAILED MEMORY BREAKDOWN
################################################################################
echo "--- DETAILED MEMORY INFORMATION ---"
echo ""
echo "Complete Memory Details:"
free -h
echo ""

echo ""

################################################################################
# 7. DISK USAGE
################################################################################
echo "--- DISK USAGE ---"
echo ""
echo "Disk Space on All Partitions:"
echo ""
df -h
echo ""

echo ""

################################################################################
# 8. TOP PROCESSES BY CPU USAGE
################################################################################
echo "--- TOP 5 PROCESSES USING MOST CPU ---"
echo ""
ps aux --sort=-%cpu | head -6 | awk '{printf "%-15s %8s %s\n", $1, $3"%", $11}'
echo ""

echo ""

################################################################################
# 9. TOP PROCESSES BY MEMORY USAGE
################################################################################
echo "--- TOP 5 PROCESSES USING MOST MEMORY ---"
echo ""
ps aux --sort=-%mem | head -6 | awk '{printf "%-15s %8s %s\n", $1, $4"%", $11}'
echo ""

echo ""

################################################################################
# 10. SUMMARY - IS THE SYSTEM HEALTHY?
################################################################################
echo "--- SYSTEM HEALTH SUMMARY ---"
echo ""

# Get memory usage percentage
mem_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}')
echo "Memory Usage: $mem_usage%"

# Get CPU usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')
echo "CPU Usage: $cpu_usage%"

echo ""
echo "Health Check Results:"
echo ""

# Check if memory usage is too high (above 80%)
if [ "$mem_usage" -gt 80 ]; then
    echo "⚠️  WARNING: High Memory Usage Detected! ($mem_usage%)"
else
    echo "✓ Memory Usage is Normal ($mem_usage%)"
fi

# Check if CPU usage is too high (above 80%)
if [ "$cpu_usage" -gt 80 ]; then
    echo "⚠️  WARNING: High CPU Usage Detected! ($cpu_usage%)"
else
    echo "✓ CPU Usage is Normal ($cpu_usage%)"
fi

echo ""
echo "================================"
echo "Health Check Complete!"
echo "Generated: $(date)"
echo "================================"
echo ""
