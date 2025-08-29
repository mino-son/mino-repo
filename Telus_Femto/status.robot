*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}       172.30.100.120
${USER}       tultefc
${PASS}       *eksvkxQkd#!
${ROOT_PASS}  *Tkfrnrtn#!
${PORT}       22
${TIMEOUT}    30s

*** Test Cases ***
SSH Then Run Commands (with sleep)
    # 1) SSH 로그인
    Open Connection    ${HOST}    port=${PORT}    timeout=${TIMEOUT}
    Sleep              3s
    Login              ${USER}    ${PASS}
    Sleep              3s

    Write              echo __READY__
    Read Until         __READY__    timeout=${TIMEOUT}

    # 2) su로 루트 전환
    Write              su -
    3s
    Read Until         assword:     timeout=${TIMEOUT}
    Write              ${ROOT_PASS}
    Sleep              3s

    Write              echo __ROOT__
    Read Until         __ROOT__     timeout=${TIMEOUT}

    # 3) idm oam 실행
    Write              idm oam; echo __DONE1__
    Read Until         __DONE1__    timeout=${TIMEOUT}

    # 4) status 실행
    Write              status; echo __DONE2__
    Read Until         __DONE2__    timeout=${TIMEOUT}

    Close All Connections
