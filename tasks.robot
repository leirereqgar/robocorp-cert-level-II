*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.RobotLogListener
Library    RPA.Archive

*** Variables ***
${orders_file}=    orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot orders web...
    ${orders}=    Get Orders

    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Download and store the result    ${row}[Order number]
    END
    
    Archive output PDFs

    [Teardown]    Log out and close the browser

*** Keywords ***
Open the robot orders web...
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get Orders 
    Download    https://robotsparebinindustries.com/orders.csv    target_file=${orders_file}    overwrite=True
    ${data}=    Read table from CSV    path=${orders_file}
    [Return]    ${data}

Close the annoying modal
    Wait and Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the form
    [Arguments]    ${order}
    Wait Until Element Is Enabled    id:head
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    Mute Run On Failure    Page Should Contain Element
    Click Button    id:order
    Page Should Contain Element    id:receipt

Store the receipt as a PDF file 
    [Arguments]    ${id}

    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Set Local Variable    ${pdf_path}    ${OUTPUT_DIR}${/}${id}.pdf
    Html To Pdf    ${receipt}    ${pdf_path}

    [Return]    ${pdf_path}

Take screenshot of the robot
    [Arguments]    ${id}
    Wait Until Element Is Visible    id:robot-preview-image
    Set Local Variable    ${img_path}    ${OUTPUT_DIR}${/}${id}.png
    Screenshot    id:robot-preview-image    ${img_path}

    [Return]    ${img_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open PDF    ${pdf}
    Log To Console    Añadiendo al recibo ${pdf}

    ${files}=    Create List    ${screenshot}:x=0,y=0
    Add Files To Pdf    ${files}    ${pdf}    ${True}
    Close Pdf    ${pdf}

Go to order another robot
    Wait and Click Button    id:order-another

Download and store the result
    [Arguments]    ${order_id}
    Wait Until Keyword Succeeds    3x    0.5sec    Preview the robot
    Wait Until Keyword Succeeds    10x    1sec    Submit the order
    ${pdf}=    Store the receipt as a PDF file    ${order_id}
    ${screenshot}=    Take screenshot of the robot    ${order_id}
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    Go to order another robot

Archive output PDFs
    Archive Folder With Zip    ${OUTPUT_DIR}    pdfReceipts.zip    recursive=True    include=*.pdf

Log out and close the browser 
    Close Browser
