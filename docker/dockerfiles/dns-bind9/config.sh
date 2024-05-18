#!/bin/bash

# Variables utilizadas y obligatorias especificadas en el dockerfile o en el docker-compose
# $ipv4_conatiner - ip asignada al contenedor
# $ipv4_anfitrion - ip asignada al anfitrion
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

# Creamos el directorio de las zonas y sus archivos de zonas
mkdir $dir_zonas && cp /etc/bind/db.empty ${dir_zonas}/db.${ipv4_anfitrion} && \
      cp /etc/bind/db.empty ${dir_zonas}/db.${ipv4_container} &&  \
      cp /etc/bind/db.empty ${dir_zonas}/db.${domain}

# Establecer el servidor de nombres en /etc/resolv.conf
# Establecemos la ip actual del contenedor
if [ $(hostname -I | grep -q "$ipv4_container" ) -eq 0 ]; then
  echo 'La ipv4 asignada al contenedor no concuerda con la variable ipv4_container'
  ipv4_container=$(hostname -I | awk '{print $1}')
  echo "Se establecerá esta ipv4 $(hostname -I | awk '{print $1}') en el /etc/resolv.conf"
  sed -i "s/nameserver 192.168.1.1/nameserver $ipv4_container" /etc/resolv.conf
else
  sed -i "s/nameserver 192.168.1.1/nameserver $ipv4_container" /etc/resolv.conf
fi # [ $(hostname -I | grep -q "$ipv4_container" ) -eq 0 ]

# Comprobar de que no existe rastro de las zonas en el archivo /etc/bind/named.conf.local
if [ $(grep -cE "$domain|$ipv4_container|$ipv4_anfitrion" /etc/bind/named.conf.local) -eq 0 ]; then
  echo 'Se establece la zona directa y inversa del servicio DNS en el archivo /etc/bind/named.conf.local'
  # Establecer la zona directa del dominio en /etc/bind/named.conf.local
  # zone "$domain" {
  #    type master;
  #    file "${dir_zonas}/db.${domain}";
  # };
  echo -e "//\nzone "$domain" {\n\ttype master;\n\tfile "${dir_zonas}/db.${domain}";\n};" >> /etc/bind/named.conf.local

  # Establecer la zona inversa (contenedor) del dominio en /etc/bind/named.conf.local
  # zone "$ipv4_container reverse" {
  #    type master;
  #    file "${dir_zonas}/db.${ipv4_container}";
  # };
  echo -e "//\nzone "$($ipv4_container | rev)" {\n\ttype master;\n\tfile "${dir_zonas}/db.${ipv4_container}";\n};" >> /etc/bind/named.conf.local

  # Establecer la zona inversa (anfitrion) del dominio en /etc/bind/named.conf.local
  # zone "$ipv4_anfitrion reverse" {
  #    type master;
  #    file "${dir_zonas}/db.${ipv4_anfitrion}";
  # };
  echo -e "//\nzone "$($ipv4_anfitrion | rev)" {\n\ttype master;\n\tfile "${dir_zonas}/db.${ipv4_anfitrion}";\n};" >> /etc/bind/named.conf.local

else
  echo 'Ya existen las zonas en el archivo /etc/bind/named.conf.local'
fi # [ $(grep -cE "$domain|$ipv4_container|$ipv4_anfitrion" /etc/bind/named.conf.local) -eq 0 ]

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
