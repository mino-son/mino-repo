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
    Write    idm oam -x status
    ${output}=    Execute Command    idm oam -x status
    Log    ${output}
    Should Match Regexp    ${output}    (?m)^\s*Started:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*StackRunning:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*Availability:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*OpState:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*AdminState:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*RFTxStatus:\s*1\b
    Should Match Regexp    ${output}    (?m)^\s*Number of Active MMEs:\s*1\b