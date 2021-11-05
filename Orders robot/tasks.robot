*** Settings ***
Documentation   This automation orders robots, 
...             saves order HTML receipts as PDFs 
...             and saves the screenshot of the ordered robot to the PDF.
Library    RPA.Browser.Selenium
Library    RPA.Tables
Library    RPA.HTTP
Library    RPA.PDF

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Get orders   
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
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
    Html To Pdf    ${order_receipt_html}    ${CURDIR}${/}output${/}receipt_${row}.pdf
 
*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${row}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}picture_${row}.png
    

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}    ${row}
    ${files}=    Create List
    ...    ${CURDIR}${/}output${/}receipt_${row}.pdf
    ...    ${CURDIR}${/}output${/}picture_${row}.png:align=center
    Add Files To Pdf    ${files}    ${CURDIR}${/}output${/}embedded_${row}.pdf    

*** Keywords ***
Go to order another robot
    Wait Until Keyword Succeeds    3x    1s    Click Button    id:order-another

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
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
    #Create a ZIP file of the receipts