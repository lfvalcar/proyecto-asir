#!/bin/bash

# Cargar variables de entorno
set -e

build_slapd(){
  # Se predefinen las configuraciones para la instalación silenciosa del paquete
  cat /root/setup/slapd.config | debconf-set-selections

  # Instalación del paquete
  apt install -yq slapd
}

config_slapd(){
  # LDAP BASE
  sed -i "s/#BASE	dc=example,dc=com/BASE	dc=${dc1},dc=${dc2}/" /etc/ldap/ldap.conf
  # LDAP URI
  sed -i "s/#URI	ldap://ldap.example.com ldap://ldap-provider.example.com:666/URI	ldap://ldap.${dc1}.${dc2} ldap://ldap.${dc1}.${dc2}:666/" /etc/ldap/ldap.conf
}

# Función principal
main(){
  build_slapd
  config_slapd

  # Se inicia el servicio
  service slapd start

  # Mantener contenedor en ejecución
  tail -f /dev/null
}

main
