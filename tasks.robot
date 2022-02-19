*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=false
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.FileSystem
Library           RPA.RobotLogListener
Library           RPA.Robocorp.Vault
Library           RPA.Dialogs

*** Variables ***
${url}            https://robotsparebinindustries.com/#/robot-order
${csv_url}        https://robotsparebinindustries.com
${orders_file}    ${CURDIR}${/}orders.csv
${pdf_folder}     ${CURDIR}${/}receipts
${img_folder}     ${CURDIR}${/}images

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Cleanup
    Get The Program Author Name From Vault
    ${csvFilename}=    Get The CSV Name
    Open the robot order website
    ${orders}=    Get orders    ${csvFilename}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit The Order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Cleanup
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}
    Empty Directory    ${pdf_folder}
    Empty Directory    ${img_folder}

Open the robot order website
    Open Available Browser    ${url}

Get orders
    [Arguments]    ${filename}
    Download    url=${csv_url}${/}${filename}    target_file=${orders_file}    overwrite=True
    ${table}=    Read table from CSV    path=${orders_file}
    [Return]    ${table}

Close the annoying modal
    Wait And Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill the form
    [Arguments]    ${myrow}
    Select From List By Value    head    ${myrow}[Head]
    Select Radio Button    body    ${myrow}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${myrow}[Legs]
    Input Text    address    ${myrow}[Address]

Preview the robot
    Click Button    preview
    Wait Until Element Is Visible    robot-preview-image

Submit the order
    Click Button    order
    Mute Run On Failure    Page Should Contain Element
    Page Should Contain Element    receipt

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    Log    Store receipt for ${orderNumber}
    Wait Until Element Is Visible    receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Set Local Variable    ${pdfName}    ${pdf_folder}${/}${orderNumber}.pdf
    Html To Pdf    ${receipt_html}    ${pdfName}
    [Return]    ${pdfName}

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    Set Local Variable    ${imgName}    ${img_folder}${/}${orderNumber}.png
    Sleep    1sec
    Capture Element Screenshot    robot-preview-image    ${imgName}
    [Return]    ${imgName}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${image}    ${pdf}
    Open Pdf    ${pdf}
    @{filesToAdd}=    Create List    ${image}:x=0,y=0
    Add Files To Pdf    ${filesToAdd}    ${pdf}    ${True}
    Close Pdf    ${pdf}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}receipts    receipts.zip

Get The Program Author Name From Vault
    Log To Console    Getting Secret from our Vault
    ${secret}=    Get Secret    secrets
    Log    ${secret}[author] wrote this program for you    console=yes

Get The CSV Name
    Add heading    I am your RoboCorp Order Assistant
    Add text input    filename    label=What is the name of the csv file?    placeholder=orders.csv
    ${result}=    Run dialog
    [Return]    ${result.filename}
