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
    Click Button    OK

*** Keywords ***
Fill the form
    Wait Until Element Is Visible    id:address 
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath: //*[contains(@id, '16360')]    ${row}[Legs]
    Input Text    address    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button    id:preview

*** Keywords ***
Submit the order
    Click Button    id:order

*** Keywords ***
Store the receipt as a PDF file
    Wait Until Element Is Visible    class:alert-success
    ${order_receipt_html}=    Get Element Attribute    class:alert-success    outerHTML
     Html To Pdf    ${order_receipt_html}    ${CURDIR}${/}output${/}order_receipt.pdf

*** Keywords ***
Take a screenshot of the robot
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}robot-preview.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    2 sec    Submit the order
        Store the receipt as a PDF file
        Take a screenshot of the robot
        Embed the robot screenshot to the receipt PDF file
    #    ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
    #    ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
    #    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    #    Go to order another robot
    END
    #Create a ZIP file of the receipts