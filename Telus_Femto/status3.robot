*** Settings ***
Library    SSHLibrary
Library    String

*** Variables ***
${HOST}       172.30.100.120
${USER}       tultefc
${PASS}       *eksvkxQkd#!
${ROOT_PASS}  *Tkfrnrtn#!
${PORT}       22
${TIMEOUT}    30s

*** Test Cases ***
SSH Then Run Commands (with validation)
    Open Connection    ${HOST}    port=${PORT}    timeout=${TIMEOUT}
    Login              ${USER}    ${PASS}
    Set Client Configuration    timeout=${TIMEOUT}
    Sleep    3s

    Write    echo __READY__
    Read Until    __READY__

    Write    su -
    Read Until    assword:
    Write    ${ROOT_PASS}
    Sleep    3s
    Write    echo __ROOT__
    Read Until    __ROOT__

    # OAM 진입
    Write    idm oam; echo __OAM__
    Read Until    __OAM__

    # status 실행 → 출력 캡처(마커까지)
    Write    status; echo __STAT_END__
    ${output}=    Read Until    __STAT_END__
    Log To Console    ${output}

    # 방어적 체크(선택)
    Should Not Contain    ${output}    not found
    Should Not Contain    ${output}    error
    Should Not Contain    ${output}    failed

    # === 모두 1이어야 PASS ===
    Should Match Regexp   ${output}    (?m)^\\s*Started:\\s*1\\b
    Should Match Regexp   ${output}    (?m)^\\s*StackRunning:\\s*1\\b
    Should Match Regexp   ${output}    (?m)^\\s*Availability:\\s*1\\b
    Should Match Regexp   ${output}    (?m)^\\s*OpState:\\s*1\\b
    Should Match Regexp   ${output}    (?m)^\\s*AdminState:\\s*1\\b
    Should Match Regexp   ${output}    (?m)^\\s*RFTxStatus:\\s*1\\b
    Should Match Regexp   ${output}    (?m)^\\s*Number of Active MMEs:\\s*1\\b

    Close All Connections
