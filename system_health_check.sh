#!/bin/bash

################################################################################
# Linux Server Health Check Script
# Purpose: Check server uptime, patch date, system details, CPU and RAM usage
# Author: Bhagyesh Vanarse
# Date: 2026-09-01
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to print with color
print_info() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Main script starts here
clear
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════╗"
echo "║     Linux Server Health Check Report       ║"
echo "║          Generated: $(date)                ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================================
# 1. SYSTEM INFORMATION
# ============================================================================

print_header "SYSTEM INFORMATION"

HOSTNAME=$(hostnamectl 2>/dev/null | grep "Static hostname" | cut -d':' -f2 | xargs)
if [ -z "$HOSTNAME" ]; then
    HOSTNAME=$(hostname)
fi
print_info "Hostname: $HOSTNAME"

OS_NAME=$(hostnamectl 2>/dev/null | grep "Operating System" | cut -d':' -f2 | xargs)
if [ -z "$OS_NAME" ]; then
    OS_NAME=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"')
fi
print_info "OS: $OS_NAME"

KERNEL=$(uname -r)
print_info "Kernel Version: $KERNEL"

ARCH=$(uname -m)
print_info "Architecture: $ARCH"

UPTIME_SECONDS=$(awk '{print int($1)}' /proc/uptime)
UPTIME_DAYS=$((UPTIME_SECONDS / 86400))
UPTIME_HOURS=$(((UPTIME_SECONDS % 86400) / 3600))
UPTIME_MINUTES=$(((UPTIME_SECONDS % 3600) / 60))
print_info "Uptime: ${UPTIME_DAYS} days, ${UPTIME_HOURS} hours, ${UPTIME_MINUTES} minutes"

LAST_BOOT=$(who -b | awk '{print $3, $4, $5}')
print_info "Last Boot: $LAST_BOOT"

# ============================================================================
# 2. SYSTEM LAST PATCH/UPDATE DATE
# ============================================================================

print_header "SYSTEM UPDATES & PATCH INFORMATION"

if [ -f /var/log/apt/history.log ]; then
    # For Debian/Ubuntu systems
    LAST_UPDATE=$(grep "Start-Date:" /var/log/apt/history.log | tail -1 | cut -d' ' -f2,3)
    print_info "Last Update (Debian/Ubuntu): $LAST_UPDATE"
elif [ -f /var/log/yum.log ]; then
    # For RHEL/CentOS systems
    LAST_UPDATE=$(tail -1 /var/log/yum.log | awk '{print $1, $2}')
    print_info "Last Update (RHEL/CentOS): $LAST_UPDATE"
elif [ -f /var/log/dnf.rpm.log ]; then
    # For Fedora systems
    LAST_UPDATE=$(tail -1 /var/log/dnf.rpm.log | awk '{print $1, $2}')
    print_info "Last Update (Fedora): $LAST_UPDATE"
else
    print_warning "Update log not found"
fi

# Check for pending updates
if command -v apt-get &> /dev/null; then
    PENDING_UPDATES=$(apt-get upgrade -s 2>/dev/null | grep "upgraded," | awk '{print $1}')
    if [ -n "$PENDING_UPDATES" ]; then
        print_warning "Pending Updates: $PENDING_UPDATES packages available"
    else
        print_info "System is up to date"
    fi
elif command -v yum &> /dev/null; then
    PENDING_UPDATES=$(yum check-update 2>/dev/null | wc -l)
    if [ "$PENDING_UPDATES" -gt 1 ]; then
        print_warning "Pending Updates: $(($PENDING_UPDATES - 1)) packages available"
    else
        print_info "System is up to date"
    fi
fi

# ============================================================================
# 3. CPU INFORMATION & USAGE
# ============================================================================

print_header "CPU INFORMATION & USAGE"

CPU_CORES=$(nproc)
print_info "Total CPU Cores: $CPU_CORES"

CPU_MODEL=$(lscpu 2>/dev/null | grep "Model name" | cut -d':' -f2 | xargs)
print_info "CPU Model: $CPU_MODEL"

CPU_FREQ=$(lscpu 2>/dev/null | grep "CPU max MHz" | cut -d':' -f2 | xargs)
print_info "CPU Max Frequency: ${CPU_FREQ} MHz"

# Get CPU usage
print_info "\nCPU Usage (Current):"

# Method 1: Using top
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
print_info "  Overall CPU Usage: ${CPU_USAGE}%"

# Per-core usage
echo -e "\n${GREEN}Per-Core CPU Usage:${NC}"
mpstat 1 1 2>/dev/null | awk 'NR>3 {printf "  Core %s: %s%% idle\n", $2, $NF}' | head -$CPU_CORES
if [ $? -ne 0 ]; then
    # Fallback if mpstat not available
    for ((i=0; i<CPU_CORES; i++)); do
        IDLE=$(awk -v core=$i 'NR==i+1 {print $5}' /proc/stat 2>/dev/null)
        echo "  Core $i: (See top or iostat for detailed usage)"
    done
fi

# Load Average
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | xargs)
print_info "\nLoad Average: $LOAD_AVG"

# ============================================================================
# 4. MEMORY (RAM) INFORMATION & USAGE
# ============================================================================

print_header "MEMORY (RAM) INFORMATION & USAGE"

MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
print_info "Total Memory: $MEM_TOTAL"

MEM_USED=$(free -h | grep Mem | awk '{print $3}')
print_info "Used Memory: $MEM_USED"

MEM_FREE=$(free -h | grep Mem | awk '{print $4}')
print_info "Free Memory: $MEM_FREE"

MEM_AVAILABLE=$(free -h | grep Mem | awk '{print $7}')
print_info "Available Memory: $MEM_AVAILABLE"

# Memory usage percentage
MEM_PERCENT=$(free | grep Mem | awk '{printf("%.2f", ($3/$2) * 100)}')
print_info "Memory Usage Percentage: ${MEM_PERCENT}%"

# Swap memory
SWAP_TOTAL=$(free -h | grep Swap | awk '{print $2}')
print_info "Total Swap: $SWAP_TOTAL"

SWAP_USED=$(free -h | grep Swap | awk '{print $3}')
print_info "Used Swap: $SWAP_USED"

# Cached and Buffers
CACHED=$(free -h | grep Mem | awk '{print $6}')
print_info "Cached Memory: $CACHED"

BUFFERS=$(free -h | grep Mem | awk '{print $5}')
print_info "Buffers: $BUFFERS"

# ============================================================================
# 5. DISK USAGE
# ============================================================================

print_header "DISK USAGE"

df -h | grep -E '^/dev|Filesystem' | awk '{printf "%-25s %10s %10s %10s %5s\n", $1, $2, $3, $4, $5}'

# ============================================================================
# 6. PROCESS INFORMATION
# ============================================================================
print_header "TOP PROCESSES BY MEMORY USAGE"

echo -e "${GREEN}Top 5 Processes by Memory:${NC}"
ps aux --sort=-%mem | head -6 | awk '{printf "%-8s %8s %s\n", $1, $6, $11}'

echo -e "\n${GREEN}Top 5 Processes by CPU:${NC}"
ps aux --sort=-%cpu | head -6 | awk '{printf "%-8s %5s %s\n", $1, $3, $11}'

# ============================================================================
# 7. NETWORK INFORMATION
# ============================================================================
print_header "NETWORK INFORMATION"

echo -e "${GREEN}Network Interfaces:${NC}"
ip addr show 2>/dev/null | grep -E "^[0-9]+:|inet " | paste - - | sed 's/^/  /'

# ============================================================================
# 8. SUMMARY & ALERTS
# ============================================================================

print_header "SYSTEM HEALTH SUMMARY & ALERTS"

# Check for issues
ISSUES=0

if (( $(echo "$MEM_PERCENT > 80" | bc -l) )); then
    print_error "High Memory Usage Detected: ${MEM_PERCENT}%"
    ((ISSUES++))
fi

if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    print_warning "High CPU Usage Detected: ${CPU_USAGE}%"
    ((ISSUES++))
fi

# Check for pending security updates
if [ -n "$PENDING_UPDATES" ] && [ "$PENDING_UPDATES" != "0" ]; then
    print_warning "Pending Security Updates Available"
    ((ISSUES++))
fi

if [ "$ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✓ System appears to be healthy!${NC}"
else
    echo -e "\n${YELLOW}Issues detected: $ISSUES${NC}"
fi

# ============================================================================
# 9. FOOTER
# ============================================================================
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}Report Generated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${BLUE}========================================${NC}\n"

exit 0
