#!/bin/bash

# Problemas
# Este script solo tiene en cuenta la máscara de red /24 a la hoara de crear la zona inversa

# Variables externas obligatorias provenientes del dockerfile o del docker-compose
# $ipv4_anfitrion - ip asignada al anfitrion
# $dir_zones - ruta donde se encuentran los archivos de zonas
# $domain - nombre de dominio completo
# $forwarders - servidores reenviadores para el servicio DNS

# Comandos/utilidades utilizados
# awk
# echo
# sed
# grep
# cp
# mkdir
# tail
# service

# Cargar variables de entorno
set -e

checks(){
  # Comprobar de que el directorio de las zonas existe y si no crearlo
  if ! [ -d $dir_zones ]; then
    mkdir $dir_zones
  fi # ! [ -d $dir_zones ]

  # Variables que contienen los nombres de las zonas inversas
  rev_zone_anfitrion="$(echo $ipv4_anfitrion | awk -F . '{print $3"."$2"."$1}').in-addr.arpa"

  # Se comprueba si existen ya ficheros de zonas, en caso de que no se crean nuevos mediante plantilla
  if ! [ -f ${dir_zones}/db.${rev_zone_anfitrion} ]; then
    cp /etc/bind/db.empty ${dir_zones}/db.${rev_zone_anfitrion}
  fi # ! [ -f ${dir_zones}/db.${rev_zone_anfitrion} ]
  if ! [ -f ${dir_zones}/db.${domain} ]; then
    cp /etc/bind/db.empty ${dir_zones}/db.${domain}
  fi # ! [ -f ${dir_zones}/db.${domain} ]
}

zones(){
  # Comprobar de que no existe rastro de las zonas en el archivo /etc/bind/named.conf.local
  if [ $(grep -cE "$domain|$ipv4_anfitrion" /etc/bind/named.conf.local) -eq 0 ]; then
    echo 'Se establece la zona directa y inversa del servicio DNS en el archivo /etc/bind/named.conf.local'
    # Establecer la zona directa del dominio en /etc/bind/named.conf.local
    # zone "$domain" {
    #    type master;
    #    file "${dir_zonas}/db.${domain}";
    # };
    echo -e "//\nzone \"$domain\" {\n\ttype master;\n\tfile \"${dir_zones}/db.${domain}\";\n};" >> /etc/bind/named.conf.local

    # Establecer la zona inversa (anfitrion) del dominio en /etc/bind/named.conf.local
    # zone "$ipv4_anfitrion reverse" {
    #    type master;
    #    file "${dir_zonas}/db.${ipv4_anfitrion}";
    # };
    echo -e "//\nzone \"${rev_zone_anfitrion}\" {\n\ttype master;\n\tfile \"${dir_zones}/db.${rev_zone_anfitrion}\";\n};" >> /etc/bind/named.conf.local

  else
    echo 'Ya existen las zonas en el archivo /etc/bind/named.conf.local'
  fi # [ $(grep -cE "$domain|$ipv4_container|$ipv4_anfitrion" /etc/bind/named.conf.local) -eq 0 ]

  # Asegurar de que el directorio de las zonas pueda ser accesible por bind9
  chown bind $dir_zones -R && chmod 744 $dir_zones -R
}

forwarders(){
  if [ $(grep -cE "^[^/]*forwarders" /etc/bind/named.conf.options) -eq 0 ]; then
    echo 'Se establece los reenviadores del servicio DNS en el archivo /etc/bind/named.conf.options'
    # Establecer los servidores reenviadores en /etc/bind/named.conf.options
    #  forwarders {
    #	    0.0.0.0; ...
    #	 };
    sed -i 	"/options {/ a\ \t`echo "forwarders { $forwarders };"`\n" /etc/bind/named.conf.options
  else
    echo 'Ya hay establecidos forwarders en el archivo /etc/bind/named.conf.options'
  fi # [ $(grep -cE "^[^/]*forwarders" /etc/bind/named.conf.options) -eq 0 ]
}

# Función principal
main(){
  checks
  zones
  forwarders
  # Lanzar servicio named
  service named start

  # Mantener contenedor en ejecución
  tail -f /dev/null
}

# Ejecución de la función principal
main
