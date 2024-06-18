#!/bin/bash

# Recoge información del equipo
systemInfo=$(cat <<EOF
{
  "computerName": "$(hostname)",
  "operatingSystem": "$(uname -o)",
  "osVersion": "$(uname -r)",

  "processorModel": "$(cat /proc/cpuinfo | grep 'model name' | uniq | cut -d ':' -f 2 | sed -e 's/^[[:space:]]*//')",
  "processorArchitecture": $(getconf LONG_BIT),
  "processorCores": $(cat /proc/cpuinfo | grep -c 'processor'),
  "processorThreads": $(nproc),
  "processorClockSpeedGHz": $(echo $(lscpu | grep 'CPU max MHz:' | awk -F: '{print $2/1000}' | tr -d ' ') | xargs printf "%.2f" | tr ',' '.'),

  "totalPhysicalMemoryGB": $(free -h | awk '/Mem/{print $2}' | tr -d [A-Za-z] | tr ',' '.'),

  "diskModel": "$(lsblk -o MODEL | grep -v '^$' | head -n 1)",
  "totalDiskSpaceGB": $(df -h --output=size / | awk 'NR==2{print substr($0, 1, length($0)-1)}' | tr ',' '.'),
  "freeDiskSpaceGB": $(df -h --output=avail / | awk 'NR==2{print substr($0, 1, length($0)-1)}' | tr ',' '.'),
  "usedDiskSpaceGB": $(df -h --output=used / | awk 'NR==2{print substr($0, 1, length($0)-1)}' | tr ',' '.'),

  "macAddress": "$(ls /sys/class/net | head -n1 | xargs ip addr show | grep -o 'link/ether .*' | awk '{print $2}')",
  "ipAddress": "$(hostname -I)"
}
EOF
)

# URL de la API REST en NestJS (ajusta la URL según tu entorno)
apiUrl="http://api.formateya.es/api/inventory"

# Utilizando curl para enviar la solicitud POST a la API REST
curl -s -X POST -H "Content-Type: application/json" -d "$systemInfo" "$apiUrl"