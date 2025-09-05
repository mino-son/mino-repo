*** Settings ***
Library                SSHLibrary
Library                SCPLibrary
Library                String
Library                DateTime
Library                Browser
Library                Process

*** Variables ***
${cell_ssh_connection_ip}               172.30.100.120
${DruidCore_ssh_connection_ip}          10.253.3.107
${segw_ssh_connection_ip}               10.253.3.66
${pkg_lte_name}                         ifq-LGU-LTEAO-4.4.1-rc0.tar.gz
${remote_working_path}                  /tmp
${user_id}                              tultefc
${user_pass}                            *eksvkxQkd#!
${root_pass}                            *Tkfrnrtn#!
${TM_connection_ip}                     10.253.3.199

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
Get Autocall & Check the 200OK
    ${result}=    Run Process    curl -i -H "Content-Type: application/json" -X GET "http://${TM_connection_ip}:8082/mts/mobile/autocall"    shell=True    stdout=PIPE    stderr=PIPE
    Log    ${result.stdout}
    Should Contain    ${result.stdout}    HTTP/1.1 200 OK    
    Sleep   5s

Start(POST) Autocall
    ${cmd}=    Set Variable    curl -i -H "Content-Type: application/json" -X POST "http://${TM_connection_ip}:8082/mts/mobile/autocall" -d '{"command":"start", "logging option":"all scenario"}'
    ${result}=    Run Process    ${cmd}    shell=True    stdout=PIPE    stderr=PIPE    timeout=120s
    Log    ${result.stdout}
    Should Contain    ${result.stdout}    HTTP/1.1 200 OK 
    Sleep   5s

Stop(POST) Autocall
    ${cmd}=    Set Variable    curl -i -H "Content-Type: application/json" -X POST "http://${TM_connection_ip}:8082/mts/mobile/autocall" -d '{"command":"stop", "logging option":"all scenario"}'
    ${result}=    Run Process    ${cmd}    shell=True    stdout=PIPE    stderr=PIPE    timeout=120s
    Log    ${result.stdout}
    Should Contain    ${result.stdout}    HTTP/1.1 200 OK 
    Sleep   5s


#curl -i -H "Content-Type: application/json" -X POST "http://${TM_connection_ip}:8082/automation" -d "{\"Automationscenario\":\"test_automation_automation\",\"Command\":\"start\"}"
#curl -i -H "Content-Type: application/json" -X POST "http://${TM_connection_ip}:8082/automation" -d "{\"Automationscenario\":\"test_automation_automation\",\"Command\":\"stop\"}"