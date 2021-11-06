*** Settings ***
Documentation   This automation orders robots, 
...             saves order HTML receipts as PDFs 
...             and saves the screenshot of the ordered robot to the PDF.
Library    RPA.Browser.Selenium
Library    RPA.Tables
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem
Library    RPA.Robocorp.Vault
Library    RPA.Dialogs

*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=    ${CURDIR}${/}output${/}temp
${OUTPUT_DIRECTORY}=    ${CURDIR}${/}output

*** Keywords ***
Get order website from dialogue
    Add heading    Please give URL address
    Add text input    URL    label=URL address
    ${result}=    Run dialog
    [Return]    ${result}

*** Keywords ***
Open the robot order website
    [Arguments]    ${result}
    Open Available Browser    ${result}[URL]

*** Keywords ***
Get orders
    ${secret}=    Get Secret    URLs
    Download    ${secret}[download-url]    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

*** Keywords ***
Close the annoying modal
    Wait Until Keyword Succeeds    3x    1s    Click Button    OK

*** Keywords ***
Fill the form
    Wait Until Element Is Visible    id:address 
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath: //*[contains(@id, '1636')]    ${row}[Legs]
    Input Text    address    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button    id:preview

*** Keywords ***
Submit the order
    FOR    ${i}    IN RANGE    9999999
        Click Button    id:order    
        ${visible}=    Is Element Visible    class:alert-danger
        Exit For Loop If    ${visible} == False
    END

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    class:alert-success
    ${order_receipt_html}=    Get Element Attribute    class:alert-success    outerHTML
    Html To Pdf    ${order_receipt_html}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt_${row}.pdf
 
*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${row}
    Screenshot    id:robot-preview-image    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}picture_${row}.png
    

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${row}
    ${files}=    Create List
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}receipt_${row}.pdf
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}picture_${row}.png:align=center
    Add Files To Pdf    ${files}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}embedded_${row}.pdf    

*** Keywords ***
Go to order another robot
    Wait Until Keyword Succeeds    3x    1s    Click Button    id:order-another

*** Keywords ***
Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIRECTORY}${/}PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}
    Remove Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}    True

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${result}=    Get order website from dialogue
    Open the robot order website    ${result}
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts