#!/usr/bin/env sh

RootDir=$1


# bring in the color variables: `normal`, `info`, `warning`, `danger`, `reset`
cd $(dirname "$0");SCRIPT_DIR=`pwd -P`;cd $OLDPWD
. $SCRIPT_DIR/common.sh

config_file="$RootDir/data/conf/general.cfg"
certs_folder=$(get_config_value CERTS_FOLDER ${config_file})
ca_cert=$(get_config_value CA_CERT ${config_file})
ca_key=$(get_config_value CA_KEY ${config_file})
ca_pass_file=$(get_config_value CA_PASS_FILE ${config_file})
ca_key_pass=$($HEAD_CMD /dev/random -c16 | $OD_CMD -tx1 -w16 | $HEAD_CMD -n1 | cut -d' ' -f2- | tr -d ' ')

if [ ! -f ${ca_cert} ]; then

    # If ca.crt is absent then all the old signed certs have to be wiped clean first
    if [ -d ${certs_folder} ]; then
        rm -r ${certs_folder}
    fi
    mkdir -p ${certs_folder}

    # A file is created which consists of CA password
    if [ -f ${ca_pass_file} ]; then
        rm ${ca_pass_file}
    fi
    echo $ca_key_pass >> $ca_pass_file
    openssl genrsa -des3 -passout pass:${ca_key_pass} -out "$ca_key" 4096
    openssl req -new -x509 -days 3650 -subj "/C=US/ST=Pwnland/L=OWASP/O=OWTF/CN=MiTMProxy" -passin pass:${ca_key_pass} -key "$ca_key" -out "$ca_cert"
    echo "${warning}[!] Don't forget to add the $ca_cert as a trusted CA in your browser${reset}"
else
    echo "${info}[*] '${ca_cert}' already exists. Nothing done."
fi
