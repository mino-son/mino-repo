*** Settings ***
Library           Process

*** Test Cases ***
Run My Commands
    [Documentation]    순서대로 명령어 실행
    Run Process    idm    oam
    Run Process    status
