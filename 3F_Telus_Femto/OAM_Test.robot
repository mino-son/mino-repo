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

#Cell Reboot And Reconnect
#   Open Connection And Log In LTE
#	Write    reboot
#	Sleep  300s
#   Close all connections
#	Open Connection And Log In LTE

Check OAM Status In CLI (Robust)
    Open Connection And Log In LTE
    ${_}=    Read
    Write    idm oam
    Write    status
    ${output}=    Read Until Prompt
    Log    ${output}

    # 콘솔에 그대로 출력 (Jenkins console)
    Log To Console    ===== output BEGIN OUTPUT =====
    Log To Console    ${output}
    Log To Console    ===== output END OUTPUT =====

    Should Contain    ${output}    *StackRunning: 1*
    Should Contain    ${output}    *RFTxStatus: 1*
    Should Contain    ${output}    *Number of Active MMEs: 1*