*** Settings ***
Library                SSHLibrary
Library                SCPLibrary
Library                String
Library                DateTime
#Suite Setup            Open Connection And Log In
Test Teardown         SSHLibrary.Close all connections

*** Variables ***
${cell_ssh_connection_ip}   172.30.100.120
${pkg_lte_name}             ifq-LGU-LTEAO-4.4.1-rc0.tar.gz
${remote_working_path}      /tmp
${user_id}                  tultefc
${user_pass}                *eksvkxQkd#!
${root_pass}                *Tkfrnrtn#!


*** Keywords ***
Check ps Utility
    ${ps_output}=    Execute Command    ps
    Should Contain    ${ps_output}    ps

Check ls Utility
    ${ls_output}=    Execute Command    ls

Open Connection And Log In LTE
    SSHLibrary.Open Connection    ${cell_ssh_connection_ip}
    SSHLibrary.Login    ${user_id}    ${user_pass}
    Write    su -
    Read Until Regexp    (?i)password:
    Write    ${root_pass}
    Set Client Configuration    prompt=#

*** Test Cases ***

Check OAM Status In CLI (Robust)
    Open Connection And Log In LTE
    ${_}=    Read
    Write    idm oam
    # 실제로 OAM 프롬프트가 뜨는 줄을 한 번 받아 동기화
    ${_}=    Read Until Regexp    (?m)^OAM .*?/>.*$
    # 이제 OAM용 프롬프트로 변경
    Set Client Configuration    prompt=(?m)^OAM .*?/>.*$
    
    Write    status
    ${status}=    Read Until Prompt
    [Return]    ${status}

    # 콘솔에 그대로 출력 (Jenkins console)
    Log To Console    ===== output BEGIN OUTPUT =====
    Log To Console    ${status}
    Log To Console    ===== output END OUTPUT =====

    Should Contain    ${status}    *StackRunning: 1*
    Should Contain    ${status}    *RFTxStatus: 1*
    Should Contain    ${status}    *Number of Active MMEs: 1*

# Cell Reboot And Reconnect
#   Open Connection And Log In LTE
#	Write    reboot
#	Sleep  300s
#   Close all connections
#	Open Connection And Log In LTE