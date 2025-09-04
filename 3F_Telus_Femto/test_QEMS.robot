*** Settings ***
Library                SSHLibrary
Library                SCPLibrary
Library                String
Library                DateTime
Library                Browser
Suite Setup       Open Browser And Context
Suite Teardown    Close Browser
Test Teardown     Take Screenshot On Failure

*** Variables ***
${cell_ssh_connection_ip}   172.30.100.120
${DruidCore_ssh_connection_ip}   10.253.3.107
${segw_ssh_connection_ip}   10.253.3.66
${pkg_lte_name}             ifq-LGU-LTEAO-4.4.1-rc0.tar.gz
${remote_working_path}      /tmp
${user_id}                  tultefc
${user_pass}                *eksvkxQkd#!
${root_pass}                *Tkfrnrtn#!
${HEADLESS}       True
${TIMEOUT}        10s

${QEMS_URL}     http://10.253.3.83:9080/login.html
${QEMS_USERNAME}       admin
${QEMS_PASSWORD}       admin
${MENU_A_TEXT}    A            # ← 여기에 실제 A 문구
${MENU_B_TEXT}    B            # ← 여기에 실제 B 문구 (A 클릭 후 보이는 항목)
${MENU_C_TEXT}    C            # ← (옵션) C 문구 (B 클릭 후 보이는 항목이면)



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

### QEMS 설정을 위한 추가 code 입니다.
Open Browser And Page
    New Browser    chromium    headless=False
    New Context
    New Page
Open Browser And Context
    New Browser    chromium    headless=True
    New Context    viewport={'width':1366,'height':768}
    New Page    
Take Screenshot On Failure
    Run Keyword If Test Failed    Take Screenshot    fullPage=True    

Reboot Femto From QEMS
    [Arguments]    ${A}    ${B}    ${C}    ${D}
    Wait For Load State    networkidle    10s

    Wait For Elements State    text="${A}"    visible    10s
    Click    text="${A}"
    Sleep    3s

    Wait For Elements State    text="${B}"    visible    10s
    Click    text="${B}"
    Sleep    3s

    Wait For Elements State    text="${C}"    visible    10s
    Click    text="${C}"
    Sleep    3s

    Wait For Elements State    text="${D}"    visible    10s
    Click    text="${D}"
    Sleep    3s


*** Test Cases ***
Telus QEMS Login TakeScreenShot
    # 전반 타임아웃을 넉넉히
    Set Browser Timeout    20s

    Go To    ${QEMS_URL}
    Wait For Elements State    input[type="text"]    visible    15s
    Fill Text    input[type="text"]    ${QEMS_USERNAME}
    Fill Text    input[type="password"]    ${QEMS_PASSWORD}
    Click        text="Sign In"

    # 네트워크 안정화
    Wait For Load State    networkidle    20s

    # 1) 로그인 버튼이 사라졌는지(화면 전환 확인)
    Wait For Elements State    text="Sign In"    hidden    20s

    # 2) 로그인 페이지에서 벗어났는지(URL 확인)
    ${cur_url}=    Get Url
    Should Not Contain    ${cur_url}    login.html

    # 3) (대안) 타이틀로 2차 검증
    ${title}=    Get Title
    Log    TITLE=${title}
    #필요시 아래 라인을 너희 시스템 타이틀 키워드로 바꿔서 엄격 검증 가능:
    Should Contain    ${title}    QEMS
    
    ${ts}=    Get Current Date    result_format=%Y%m%d-%H%M%S
    Take Screenshot    ${OUTPUT DIR}/qems_after_login_${ts}.png    fullPage=True
    Log    <a href="${QEMS_URL}">Open QEMS login.html</a>    html=True

Reboot Femto From QEMS
    Reboot Femto From QEMS    Configuration    Device Monitoring (LTE)    민호_SN19_101.116_6984    
    Take Screenshot    ${OUTPUT DIR}/QEMS_reboot${ts}.png    fullPage=True
