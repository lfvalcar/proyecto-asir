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
  "processorClockSpeedGHz": $(echo $(lscpu | grep 'CPU max MHz:' | awk -F: '{print $2/1000}' | tr -d ' ') | xargs printf "%.2f"),

  "totalPhysicalMemoryGB": $(free -h | awk '/Mem/{print $2}' | tr -d [A-Za-z]),

  "diskModel": "$(lsblk -o MODEL | grep -v '^$' | head -n 1)",
  "totalDiskSpaceGB": $(df -h --output=size / | awk 'NR==2{print substr($0, 1, length($0)-1)}'),
  "freeDiskSpaceGB": $(df -h --output=avail / | awk 'NR==2{print substr($0, 1, length($0)-1)}'),
  "usedDiskSpaceGB": $(df -h --output=used / | awk 'NR==2{print substr($0, 1, length($0)-1)}'),

  "macAddress": "$(ls /sys/class/net | head -n1 | xargs ip addr show | grep -o 'link/ether .*' | awk '{print $2}')",
  "ipAddress": "$(hostname -I)"
}
EOF
)

# URL de la API REST en NestJS (ajusta la URL según tu entorno)
apiUrl="http://192.168.56.1:3001/api/inventory"

# Envia la información a la API REST
echo "Enviando datos al servidor..."

# Utilizando curl para enviar la solicitud POST a la API REST
response=$(curl -s -X POST -H "Content-Type: application/json" -d "$systemInfo" "$apiUrl")

# Verificar la respuesta de la API
echo "Respuesta de la API:"
echo "$response"
