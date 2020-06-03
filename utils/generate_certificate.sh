#!/bin/bash

function edit_cnf_files() {
    local sed_flags=()
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        sed_flags+=("-i" "-e")
        elif [[ "$OSTYPE" == "darwin"* ]]; then
        sed_flags+=("-i" "\"\"" "-e")
    fi
    echo FLAGS $sed_flags
    cp -r $PWD/utils/core/* $PWD/core-node/config/certs
    sed ${sed_flags[@]} "s#dir=#dir = $PWD/core-node/config/certs#" $PWD/core-node/config/certs/ca.cnf
}

function gen_cert() {
    mkdir new_certs && chmod 700 new_certs
    touch index.txt
    # create CA key
    openssl genpkey -out ca.key.pem -outform PEM -algorithm ed25519
    openssl pkey -inform pem -in ca.key.pem -text -noout
    openssl pkey -in ca.key.pem -pubout -out ca.pubkey.pem
    # create CA cert and self-sign it
    openssl req -config ca.cnf -keyform PEM -key ca.key.pem -new -x509 -days 7300 -out ca.cert.pem
    openssl x509 -in ca.cert.pem  -text -noout
    # create node key
    openssl genpkey -out node.key.pem -outform PEM -algorithm ed25519
    openssl pkey -inform pem -in node.key.pem -text -noout
    # create request
    openssl req -config node.cnf -key node.key.pem -new -out node.csr.pem
    openssl req  -text -noout -verify -in node.csr.pem
    ### below is done after files are written
    # CA side
    # create serial
    openssl rand -hex 19 > ./serial.dat
    # sign cert for 375 days
    openssl ca -config ca.cnf -days 375 -notext -in node.csr.pem -out node.crt.pem
    openssl verify -CAfile ca.cert.pem node.crt.pem
    # finally create full crt
    cat node.crt.pem ca.cert.pem > node.full.crt.pem
}
mkdir $PWD/core-node/config/certs
edit_cnf_files
cd $PWD/core-node/config/certs
gen_cert
