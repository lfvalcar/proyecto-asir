#!/bin/bash

# Problemas
# Este script solo tiene en cuenta la máscara de red /24 a la hoara de crear la zona inversa

# Variables externas obligatorias provenientes del dockerfile o del docker-compose
# $ipv4_container - ip asignada al contenedor
# $ipv4_anfitrion - ip asignada al anfitrion
# $dir_zones - ruta donde se encuentran los archivos de zonas
# $domain - nombre de dominio completo
# $forwarders - servidores reenviadores para el servicio DNS

# Comandos/utilidades utilizados
# hostname
# awk
# echo
# sed
# grep
# cp
# mkdir

# Cargar variables de entorno
set -e

# Establecer el servidor de nombres en /etc/resolv.conf
# Establecemos la ip actual del contenedor
if [ $(hostname -I | grep -c "$ipv4_container") -eq 0 ]; then
  echo 'La ipv4 asignada al contenedor no concuerda con la variable ipv4_container'
  ipv4_container=$(hostname -I | awk '{print $1}')
  echo "Se establecerá esta ipv4 $ipv4_container como zona inversa del contenedor"
fi # [ $(hostname -I | grep -q "$ipv4_container" ) -eq 0 ]

# Variables que contienen las zonas inversas
rev_zone_container="$(echo $ipv4_container | awk -F . '{print $3"."$2"."$1}').in-addr.arpa"
rev_zone_anfitrion="$(echo $ipv4_anfitrion | awk -F . '{print $3"."$2"."$1}').in-addr.arpa"

# Creamos el directorio de las zonas y sus archivos de zonas
mkdir $dir_zones && cp /etc/bind/db.empty ${dir_zones}/db.${rev_zone_anfitrion} && \
      cp /etc/bind/db.empty ${dir_zones}/db.${rev_zone_container} &&  \
      cp /etc/bind/db.empty ${dir_zones}/db.${domain}

# Comprobar de que no existe rastro de las zonas en el archivo /etc/bind/named.conf.local
if [ $(grep -cE "$domain|$ipv4_container|$ipv4_anfitrion" /etc/bind/named.conf.local) -eq 0 ]; then
  echo 'Se establece la zona directa y inversa del servicio DNS en el archivo /etc/bind/named.conf.local'
  # Establecer la zona directa del dominio en /etc/bind/named.conf.local
  # zone "$domain" {
  #    type master;
  #    file "${dir_zonas}/db.${domain}";
  # };
  echo -e "//\nzone \"$domain\" {\n\ttype master;\n\tfile \"${dir_zones}/db.${domain}\";\n};" >> /etc/bind/named.conf.local

  # Establecer la zona inversa (contenedor) del dominio en /etc/bind/named.conf.local
  # zone "$ipv4_container reverse" {
  #    type master;
  #    file "${dir_zonas}/db.${ipv4_container}";
  # };
  echo -e "//\nzone \"${rev_zone_container}\" {\n\ttype master;\n\tfile \"${dir_zones}/db.${rev_zone_container}\";\n};" >> /etc/bind/named.conf.local

  # Establecer la zona inversa (anfitrion) del dominio en /etc/bind/named.conf.local
  # zone "$ipv4_anfitrion reverse" {
  #    type master;
  #    file "${dir_zonas}/db.${ipv4_anfitrion}";
  # };
  echo -e "//\nzone \"${rev_zone_anfitrion}\" {\n\ttype master;\n\tfile \"${dir_zones}/db.${rev_zone_anfitrion}\";\n};" >> /etc/bind/named.conf.local

else
  echo 'Ya existen las zonas en el archivo /etc/bind/named.conf.local'
fi # [ $(grep -cE "$domain|$ipv4_container|$ipv4_anfitrion" /etc/bind/named.conf.local) -eq 0 ]

if [ $(grep -cE "^[^/]*forwarders" /etc/bind/named.conf.options) -eq 0 ]; then
  echo 'Se establece los reenviadores del servicio DNS en el archivo /etc/bind/named.conf.options'
  # Establecer los servidores reenviadores en /etc/bind/named.conf.options
  #  forwarders {
  #	    0.0.0.0; ...
  #	 };
  sed -i 	"/options {/ a\ \t`echo "forwarders {$forwarders };"`\n" /etc/bind/named.conf.options
else
  echo 'Ya hay establecidos forwarders en el archivo /etc/bind/named.conf.options'
fi # [ $(grep -cE "^[^/]*forwarders" /etc/bind/named.conf.options) -eq 0 ]
