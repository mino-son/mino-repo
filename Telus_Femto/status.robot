*** Settings ***
Library    SSHLibrary

*** Variables ***
${HOST}     172.30.100.120
${USER}     tultefc
${PASS}     *eksvkxQkd#!
${PORT}     22
${TIMEOUT}  15s

*** Test Cases ***
SSH Then Run Commands
    [Documentation]    원격에 SSH 접속 후 'idm oam' → 'status' 순차 실행
    Open Connection    ${HOST}    port=${PORT}    timeout=${TIMEOUT}
    Login              ${USER}    ${PASS}

    # 안정성을 위해 대기
    Sleep              3s

    ${out1}    ${rc1}=    Execute Command    idm oam    return_stdout=True    return_rc=True
    Log    ${out1}
    Should Be Equal As Integers    ${rc1}    0
    Should Not Contain Any    ${out1}    error    not found    failed

    Sleep              3s

    ${out2}    ${rc2}=    Execute Command    status    return_stdout=True    return_rc=True
    Log    ${out2}
    Should Be Equal As Integers    ${rc2}    0
    Should Not Contain Any    ${out2}    error    not found    failed

    Close All Connections

*** Keywords ***
Should Not Contain Any
    [Arguments]    ${text}    @{needles}
    FOR    ${n}    IN    @{needles}
        Should Not Contain    ${text}    ${n}
    END
