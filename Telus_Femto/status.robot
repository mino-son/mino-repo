*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}      172.30.100.120
${USER}      tultefc
${PASS}      *eksvkxQkd#!
${PORT}      22
${TIMEOUT}   15s
${SHELL}     /bin/bash
${PROFILE}   source /etc/profile; source ~/.bashrc    # 필요한 경우만 사용

*** Test Cases ***
SSH Then Run Commands (minimal)
    Open Connection    ${HOST}    port=${PORT}    timeout=${TIMEOUT}
    Login              ${USER}    ${PASS}

    Sleep    3s
    ${out1}    ${rc1}=    Execute Command    ${SHELL} -lc '${PROFILE}; idm oam'    return_stdout=True    return_rc=True
    Should Be Equal As Integers    ${rc1}    0

    Sleep    3s
    ${out2}    ${rc2}=    Execute Command    ${SHELL} -lc '${PROFILE}; status'     return_stdout=True    return_rc=True
    Should Be Equal As Integers    ${rc2}    0

    Close All Connections
