*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}       172.30.100.120
${USER}       tultefc
${PASS}       *eksvkxQkd#!
${ROOT_PASS}  *Tkfrnrtn#!
${PORT}       22
${TIMEOUT}    15s

*** Test Cases ***
SSH Then Run Commands (with sleep)
    Open Connection    ${HOST}    port=${PORT}    timeout=${TIMEOUT}
    Login              ${USER}    ${PASS}
    Sleep              3s

    Write              echo __READY__
    Read Until         __READY__    ${TIMEOUT}

    Write              su -
    Read Until         assword:    ${TIMEOUT}
    Write              ${ROOT_PASS}
    Sleep              3s

    Write              echo __ROOT__
    Read Until         __ROOT__     ${TIMEOUT}

    Write              idm oam; echo __DONE1__
    Read Until         __DONE1__    ${TIMEOUT}

    Write              status; echo __DONE2__
    Read Until         __DONE2__    ${TIMEOUT}

    Close All Connections
