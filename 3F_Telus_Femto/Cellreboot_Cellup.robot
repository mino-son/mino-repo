*** Settings ***
Library                SSHLibrary
Library                SCPLibrary
Library                String
Library                DateTime
Library                Browser

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

    Set Client Configuration    timeout=3 s    strip_prompt=True
    Write    idm oam -x status
    ${output_status}=    Read Until Prompt
    log     Read Until Prompt
    Should Contain    ${output_status}    StackRunning: 1
    Should Contain    ${output_status}    RFTxStatus: 1
    Should Contain    ${output_status}    Number of Active MMEs: 1
    Close all connections
    

Sync Source NTP status
    Open Connection And Log In LTE
    
    Set Client Configuration    timeout=3 s    strip_prompt=True
    Write    idm oam -x syncmgrstate
    ${output_ntp_sync}=    Read Until Prompt
    log     Read Until Prompt
    Should Contain    ${output_ntp_sync}    NTP Sync State
    Should Contain    ${output_ntp_sync}    LOCKED
    Close all connections


IPSEC Down
    Open Connection SSH Druid Core
    Open Connection SecGW Core
    
    Set Client Configuration    timeout=3 s    strip_prompt=True
    Write   iptables -A OUTPUT -s ${cell_ssh_connection_ip} -j DROP
    Write   iptables -A INPUT -s ${cell_ssh_connection_ip} -j DROP
    ${block_ip}=    Read Until Prompt
    Log     ${block_ip}
    Log to console    ${block_ip} 
    Close all connections
    Sleep  600s

    Open Connection And Log In LTE  
    Set Client Configuration    timeout=3 s    strip_prompt=True
    Write    idm oam -x status
    ${output_mme_status}=    Read Until Prompt
    Log      ${output_mme_status}
    Log to console    ${output_mme_status}
    Should Contain    ${output_mme_status}     Number of Active MMEs: 0
    Should Contain    ${output_mme_status}     Virtual IP: down
    Close all connections
    Sleep  2s

IPSEC Up & Cell up Checking
    #여기부터 문제가 된 것 같은데.. 
    Open Connection SecGW Core   
    Write   iptables -D INPUT 1
    Write   iptables -D OUTPUT 1
    Sleep  60s
    Close all connections

    Open Connection And Log In LTE 
    Set Client Configuration    timeout=3 s    strip_prompt=True
    Write    idm oam -x status
    ${output_status}=    Read Until Prompt
    log     Read Until Prompt
    Should Contain    ${output_status}    StackRunning: 1
    Should Contain    ${output_status}    RFTxStatus: 1
    Should Contain    ${output_status}    Number of Active MMEs: 1
    Close all connections  