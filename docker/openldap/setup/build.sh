#!/bin/bash

# Cargar variables de entorno
set -e

# Proceso de compilación de software
# Se situa en el directorio de inicio y se crea el directorio con el resultado final de la compilación
# Se descomprime el archivo con los ficheros del software a compilar y se situa sobre ellos
cd /setup && mkdir /openldap && tar -xzf $openldap_version.tgz && cd $openldap_version

# Se ejecuta el script de compilación del software con las siguientes opciones
./configure -q --prefix=/openldap --enable-dynamic --enable-crypt --enable-spasswd --enable-modules \
--with-cyrus-sasl --with-tls --with-systemd

# Proceso de compilación del software
make depend && make && make test && make install
