#!/bin/bash

# Comandos/utilidades utilizados
# cat
# debconf-set-selections
# apt
# sed
# service
# tail
# cp
# chgrp
# chmod
# ln
# set
# certtool
# ldapmodify

# Variables
# ${dc1} - Dominio parte 1
# ${dc2} - Dominio parte 2
# $ca_cert - Certificado de autoridad
# $ca_key - Clave privada del certificado de autoridad
# $ca_info - Información del certificado de autridad
# $server_cert - Certificado del servidor openldap
# $server_key - Clave privada del servidor openldap
# $server_info - Información del servidor
# $certinfo_ldif -Archivo para establecer los archivos para tls (Necesario si no tienes certificado)
# ${DIR_SETUP} - Directorio donde se ubican los certificados y archivos de configuración

# Cargar variables de entorno
set -e

install_slapd(){
  # Se predefinen las configuraciones para la instalación silenciosa del paquete
  cat ${DIR_SETUP}/slapd.config | debconf-set-selections

  # Instalación de los paquetes
  apt install -yq slapd ldap-utils
}

config_slapd(){
  # /etc/ldap/ldap.conf
  # LDAP BASE
  sed -i "s/#BASE	dc=example,dc=com/BASE	dc=${dc1},dc=${dc2}/" /etc/ldap/ldap.conf
  # LDAP URI
  sed -i "s/#URI	ldap:\/\/ldap.example.com ldap:\/\/ldap-provider.example.com:666/URI	ldap:\/\/${HOSTNAME}/" \
  /etc/ldap/ldap.conf
}

selfsigned_certificate(){
  # Se instalan los paquetes necesarios para la creación de certificado autofirmado
  apt install -yq gnutls-bin ssl-cert

  # Se genera la clave privada para la solicitud del certificado
  certtool --generate-privkey --bits 4096 --outfile /etc/ssl/private/$ca_key

  # Se genera el certificado de autoridad autofirmado
  certtool --generate-self-signed \
  --load-privkey /etc/ssl/private/$ca_key \
  --template ${DIR_SETUP}/$ca_info \
  --outfile /etc/ssl/certs/$ca_cert

  # Se genera la clave privada del certificado
  certtool --generate-privkey \
  --bits 2048 \
  --outfile /etc/ldap/$server_key

  # Se genera el certificado del servidor
  certtool --generate-certificate \
  --load-privkey /etc/ldap/$server_key \
  --load-ca-certificate /etc/ssl/certs/$ca_cert \
  --load-ca-privkey /etc/ssl/private/$ca_key \
  --template ${DIR_SETUP}/$server_info \
  --outfile /etc/ldap/$server_cert
}

config_certificate(){
  # Darle la propiedad de la clave privada del servidor al usuario del servicio
  chgrp openldap /etc/ldap/$server_key
  chmod 0640 /etc/ldap/$server_key

  # /etc/default/slapd
  # Habilitar servicio ldap seguro (ldaps)
  sed -i "s/SLAPD_SERVICES=\"ldap:\/\/\/ ldapi:\/\/\/\"/SLAPD_SERVICES=\"ldap:\/\/\/ ldapi:\/\/\/ ldaps:\/\/\/\"/" \
  /etc/default/slapd

  # Establecer el certificado de autoridad en el archivo de configuración ldap.conf
  sed -i "s/TLS_CACERT	\/etc\/ssl\/certs\/ca-certificates.crt/TLS_CACERT	\/etc\/ssl\/certs\/$ca_cert/" \
  /etc/ldap/ldap.conf

  # Se inicia el servicio slapd
  service slapd start
  
  # Se introducen las ubicaciones de los certificados y claves privadas necesarias parala conexión segura
  ldapmodify -Y EXTERNAL -H ldapi:/// -f ${DIR_SETUP}/$certinfo_ldif
}

# Función principal
main(){
  
  # ¿Está slapd instalado?
  if [ ! -f /etc/ldap/ldap.conf ]; then
    echo 'slapd no está instalado, se instalará'
    install_slapd
    echo 'slapd instalado'
  fi

  # ¿Se tiene certificado? si no se tiene se utiliza certificado autofirmado
  # Se comprueba si en el directorio de setup tenemos el certificado o si no se crea
  if [[ -f "${DIR_SETUP}/$ca_cert" && -f "${DIR_SETUP}/$server_key" && -f "${DIR_SETUP}/$server_cert"  ]]
  then
    echo "Hay certificado, se utilizará"
    
    # Copiar el certificado y clave privada proporionados en sus respectivas rutas
    cp ${DIR_SETUP}/$server_key /etc/ldap/ && cp ${DIR_SETUP}/$ca_cert /etc/ssl/certs && \
    cp ${DIR_SETUP}/$server_cert /etc/ldap/
  else
    echo 'NO hay certificado, se procede a crear uno autofirmado'
    selfsigned_certificate
    echo "Certificado creado"
  fi

  # ¿Está /etc/ldap/ldap.conf configurado?
  if [ $(grep -c '^#BASE' /etc/ldap/ldap.conf) -eq 1 ]; then
    echo '/etc/ldap/ldap.conf no está configurado, se configurará'
    config_slapd
  fi

  # Se comprueba de que el certificado y claves privadas ya sean autofirmados o proporcionadas
  # están sus ubicaciones 
  if [[ -f "/etc/ssl/certs/$ca_cert" && -f "/etc/ldap/$server_key" && -f "/etc/ldap/$server_cert" ]]
  then
    config_certificate
    echo 'slapd instalado y configurado con ssl/tls con éxito'

    # Mantener contenedor en ejecución
    tail -f /dev/null
  else
    echo 'NO se encuentra el certificado de autoridad o la clave privada del certificado o la información del certificado'
  fi
}

main
