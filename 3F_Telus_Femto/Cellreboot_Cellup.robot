*** Settings ***
Library                SSHLibrary
Library                SCPLibrary
Library                String
Library                DateTime
#Suite Setup            Open Connection And Log In
Test Teardown         SSHLibrary.Close all connections

*** Variables ***
${cell_ssh_connection_ip}   172.30.100.120
${DruidCore_ssh_connection_ip}   10.253.3.107
${segw_ssh_connection_ip}   10.253.3.66
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

Open Connection SSH Druid Core
    SSHLibrary.Open Connection    ${DruidCore_ssh_connection_ip}
    SSHLibrary.Login    root    qucell12345
    Set Client Configuration    prompt=#

Open Connection SecGW Core
    SSHLibrary.Open Connection    ${segw_ssh_connection_ip}
    SSHLibrary.Login    secgw    qucell12345
    Write    su -
    Read Until Regexp    (?i)password:
    Write    qucell12345
    Set Client Configuration    prompt=#

Cell Reboot And Reconnect
    Open Connection And Log In LTE
	Write    reboot
	Sleep  300s
    Close all connections
	Open Connection And Log In LTE    

*** Test Cases ***
Check Cell Status In CLI
    Open Connection And Log In LTE
        
    Read Until Prompt
    Write    idm oam -x status
    ${output_status}=    Read Until Prompt
    Log      ${output_status}     
    Should Contain    ${output_status}    StackRunning: 1
    Should Contain    ${output_status}    RFTxStatus: 1
    Should Contain    ${output_status}    Number of Active MMEs: 1
    Close all connections
    

Sync Source NTP status
    Open Connection And Log In LTE
    
    Read Until Prompt
    Write    idm oam -x syncmgrstate
    ${output_ntp_sync}=    Read Until Prompt
    Log      ${output_ntp_sync}
    Should Contain    ${output_ntp_sync}    NTP Sync State
    Should Contain    ${output_ntp_sync}    LOCKED
    Close all connections


IPSEC DownUp
    Open Connection And Log In LTE

    # 프롬프트/타임아웃 설정 + 새 프롬프트를 강제로 찍게 만들기
    Set Client Configuration    prompt=(?m)^#.*$    timeout=30 seconds
    Write Bare    \n
    ${_}=    Read Until Prompt
    
    Read Until Prompt
    Write    idm oam -x status
    ${output_mme_status}=    Read Until Prompt
    Log     ${output_mme_status}
    Should Contain    ${output_mme_status}    Number of Active MMEs: 1
        
    Set Client Configuration    prompt=#
    Read Until Prompt
    Write    idm oam -x alarm
    ${output_connected}=    Read Until Prompt
    Log     ${output_connected}
    ${_}=    Read Until Prompt
     
    Close all connections

    Open Connection SSH Druid Core
    Open Connection SecGW Core
    
    Read Until Prompt
    Write iptables -L -n -v
    ${output_iptables}=    Read Until Prompt
    Log     ${output_iptables}
    ${_}=    Read Until Prompt

    Set Client Configuration    prompt=#
    Read Until Prompt
    Write   iptables -A OUTPUT -s ${cell_ssh_connection_ip} -j DROP
    Write   iptables -A INPUT -s ${cell_ssh_connection_ip} -j DROP
    ${block_iptables}=    Read Until Prompt
    Log     ${block_iptables}
    ${_}=    Read Until Prompt

    Sleep 630s
    
    Open Connection And Log In LTE
    
    Read Until Prompt
    Write    idm oam -x status
    ${output_mme_status}=    Read Until Prompt
    ${_}=    Read

    Set Client Configuration    prompt=#
    Read Until Prompt
    Write    idm oam -x alarm
    ${output_ip_blocked}=    Read Until Prompt
    
    Log      ${output_mme_status}     
    Log      ${output_ip_blocked}     
    Should Contain    ${output_mme_status}     Number of Active MMEs: 0
    Should Contain    ${output_ip_blockedoutput_status}    IPSec Tunnel Down
    
    