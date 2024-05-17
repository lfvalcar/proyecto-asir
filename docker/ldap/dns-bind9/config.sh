#!/bin/bash

# Variables utilizadas
# $ip - ip asignada al contenedor (en caso de tener varias utiliza la primera)
# $dir_zonas - ruta donde se encuentran los archivos de zonas
# $domain - nombre de dominio completo
# $forwarders - servidores reenviadores para el servicio DNS

# Comandos/utilidades utilizados
# hostname
# awk
# wc
# echo
# sed
# rev
# grep

# Cargar variables de entorno
set -e

# Creamos el directorio de las zonas
mkdir $dir_zonas

# Establecer el servidor de nombres en /etc/resolv.conf
# Establecemos la ip actual del contenedor, en el caso de que tenga varias se informa y se establece la primera
if [ $(echo hostname -I | wc -w) > 1 ]; then
  echo 'El contenedor tiene asignada más de una ip, se establecerá como servidor de nombres la primera'
  ip=$(hostname -I | awk '{print $1}')
  sed -i "s/nameserver 192.168.1.1/nameserver $ip" /etc/resolv.conf
else
  echo 'El contenedor tiene asignada una ip, se establecerá la misma como servidor de nombres'
  ip=$(hostname -I)
  sed -i "s/nameserver 192.168.1.1/nameserver $ip" /etc/resolv.conf
fi # [ $(echo hostname -I | wc -w) > 1 ]

# Comprobar de que no existe rastro de las zonas en el archivo /etc/bind/named.conf.local
if [ $(grep -cE "$domain|$ip" /etc/bind/named.conf.local) -eq 0 ]; then
  echo 'Se establece la zona directa y inversa del servicio DNS en el archivo /etc/bind/named.conf.local'
  # Establecer la zona directa de dominio en /etc/bind/named.conf.local
  # zone "$domain" {
  #    type master;
  #    file "${dir_zonas}/db.${domain}";
  # };
  echo -e "//\nzone "$domain" {\n\ttype master;\n\tfile "${dir_zonas}/db.${domain}";\n};" >> /etc/bind/named.conf.local

  # Establecer la zona inversa de dominio en /etc/bind/named.conf.local
  # zone "$ip reverse" {
  #    type master;
  #    file "${dir_zonas}/db.${ip}";
  # };
  echo -e "//\nzone "$($ip | rev)" {\n\ttype master;\n\tfile "${dir_zonas}/db.${ip}";\n};" >> /etc/bind/named.conf.local

else
  echo 'Ya existen las zonas en el archivo /etc/bind/named.conf.local'
fi # [ $(grep -cE "$domain|$ip" /etc/bind/named.conf.local) -eq 0 ]

if [ $(grep -cE "^[^/]*forwarders" /etc/bind/named.conf.options) -eq 0 ]; then
  echo 'Se establece los reenviadores del servicio DNS en el archivo /etc/bind/named.conf.options'
  # Establecer los servidores reenviadores en /etc/bind/named.conf.options
  #  forwarders {
  #	    0.0.0.0;
  #     ...
  #	 };
  sed -i 	"/options {/a\\tforwarders {\n\t\t$(echo -e $forwarders)\n\t};" /etc/bind/named.conf.options
else
  echo 'Ya hay establecidos forwarders en el archivo /etc/bind/named.conf.options'
fi # [ $(grep -cE "^[^/]*forwarders" /etc/bind/named.conf.options) -eq 0 ]

# Limpiado del script de configuración
rm /root/config.sh
