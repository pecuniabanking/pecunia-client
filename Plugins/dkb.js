// JS banking plugin for Pecunia
// Author: Mike Lischke, with help from the DKB script in Hibiscus (http://www.willuhn.de/products/hibiscus/)
//
// Plugin to read DKB credit card statements from the DKB website (www.dkb.de).


// Plugin details used to manage usage. Name and description are mandatory.
var name = "pecunia.plugin.dkbvisa";
var author = "Mike Lischke";
var description = "DKB Kreditkartenkonto"; // Short string for plugin selection.
var homePage = "http://pecuniabanking.de";
var license = "CC BY-NC-ND 4.0 - http://creativecommons.org/licenses/by-nc-nd/4.0/deed.de";
var version = "1.01";

// --- Internal variables.
var currentState = 0; // Used in the callback to determine what to do next (state machine).
var userName = "";
var thePassword = "";

// Various URLs for the DKB banking site.
var dkbBaseURL = "https://www.dkb.de/banking";
var dkbOldLoginURL = "https://www.dkb.de/banking";
var dkbNewLoginURL = "https://www.dkb.de/banking";
var dkbLogoutURL = "https://www.dkb.de/DkbTransactionBanking/banner.xhtml?$event=logout";

// Mailbox URLs
var dkbUnreadMailCheck = "https://banking.dkb.de/dkb/-?$part=DkbTransactionBanking.infobar.PostboxStatus&$event=updateNumberOfUnreadMessages";
var dkbMailBox = "https://banking.dkb.de/dkb/-?$part=DkbTransactionBanking.index.menu&node=3&tree=menu&treeAction=selectNode";

// Credit card URLs.
var dkbCardSelectionURL = "https://www.dkb.de/banking/finanzstatus/kreditkartenumsaetze?$event=init";
var dkbCsvURL = "https://www.dkb.de/banking/finanzstatus/kreditkartenumsaetze?$event=csvExport";

// Optionial function to support auto account type determination.
function canHandle(account, bankCode) {
    if (bankCode != "12030000")
        return false;
    
    // Credit cards are the only accounts with 16 digits.
    if (account.length != 16)
        return false;
    
    return true;
}

function logOut() {
    logger.logDebug("Starting log out...");
    currentState = 99;
    userName = "";
    thePassword = "";
    webClient.URL = dkbLogoutURL;
}

// Cache variables to allow for async loading.
var numbers;
var startFrom;
var endAt;

var results = [];

function getStatements(user, bankCode, password, from, to, creditCardNumbers) {
    numbers = creditCardNumbers;
    startFrom = from;
    endAt = to;
    results = [];
    singleStep = false;
    
    if (user == "") {
        logger.logError("Login: user name empty");
        return false;
    }
    
    logger.logDebug("Statements for user: " + user);
    logger.logDebug("From: " + from);
    logger.logDebug("To: " + to);
    logger.logDebug("Credit cards: " + creditCardNumbers);
    
    userName = user;
    thePassword = password;
    currentState = 11;
    webClient.callback = navigationCallback;
    webClient.URL = dkbBaseURL;
    
    return true;
}

// Called from the plugin worker, e.g. after navigating to a new page or when executing a single step.
// Implements our state machine.

var singleStep = false;

function navigationCallback(doStep) {
    // Check if we ended up on an unknown page (which indicates that our URLs might be wrong).
    var text = webClient.mainFrameDocument.body.innerText;
    if (text.indexOf("Fehler - Seite konnte nicht gefunden werden") >= 0) {
        errorExit("Das Plugin wurde auf eine Fehlerseite der Bank umgeleitet. Möglicherweise ist eine URL falsch.");
        return;
    }
    
    if (singleStep) {
        // We executed a step and hold the state machine here.
        singleStep = false;
        return;
    }
    
    if (doStep) {
        // Got the command to run only one step. Continue with the current state
        // but stop the state machine when this is finished.
        singleStep = true;
    }
    
    logger.logDebug("State machine at: " + currentState);
    try {
        switch (currentState) {
            case 1, 11: // 1 for pure login, 11 for login + statements.
                startLogin();
                break;
                
            case 12: // After log in state. If all is fine collect statements.
                logger.logDebug("URL after login: " + webClient.URL);
                
                // Check if we were sent back to the login form.
                var formLogin = webClient.mainFrame.document.forms.item(0);
                var submitLogin = formLogin.elements.namedItem("buttonlogin");
                if (submitLogin != null) {
                    // TODO: localization support.
                    errorExit("Die Anmeldung ist fehlgeschlagen. Falsche PIN verwendet?");
                    currentState = 0;
                    webClient.callback = null;
                    
                    return;
                }
                
                navigateToCreditCardPage();
                break;
                
            case 13:
                logger.logDebug("URL after credit card menu selection: " + webClient.URL);
                startCreditCardLoop();
                break;
                
            case 14: // Arrived at list of statements. Start CSV export and collect results.
                logger.logDebug("URL after retrieving statements: " + webClient.URL);
                currentState = 15;
                webClient.URL = dkbCsvURL;
                break;
                
            case 15:
                logger.logDebug("URL after loading csv data: " + webClient.URL);
                convertCsvToResult();
                break;
                
            case 16: // Continue credit card loop.
                readNextCreditCard();
                break;
                
            case 99:
                logger.logDebug("Log out done");
                // Fall through;
            default:
                currentState = 0;
                webClient.callback = null; // Unregister ourselve. We are done.
                logger.logDebug("Plugin invocation done");
        }
    } catch (err) {
        if (currentState != 99) // If exception not triggered by logout.
            errorExit("Bei der Ausführung des Scripts kam es zu einem unerwarteten Fehler. Ausführung wurde abgebrochen.");
        throw err;
    }
}

function startLogin() {
    var LoginURL = webClient.URL;
    logger.logDebug("At URL: " + LoginURL + ", triggering login process");
    if (LoginURL.indexOf("/portal") !== -1) {
        logger.debug("Running new portal login");
        /* TODO
         var formLogin = pageLogin.getFirstByXPath("//form[@class='anmeldung']");
         logger.logDebug("formLogin: " + formLogin + ", name: " + formLogin.name);
         formLogin.getFirstByXPath("//input[@maxlength='16']").setValueAttribute(ResponseLogin);
         formLogin.getFirstByXPath("//input[@type='password']").setValueAttribute(ResponsePasswort);
         var submitLogin = formLogin.getInputByValue("Anmelden");
         */
        
    } else if (LoginURL.indexOf("/banking") !== -1) {
        logger.logDebug("Running old standard login");
        var formLogin = webClient.mainFrame.document.forms.item(1);
        
        logger.logDebug("formLogin: " + formLogin + ", name: " + formLogin.name + ", action: " + formLogin.action);
        for (var i = 0; i < formLogin.elements.length; ++i) {
            var j_username = formLogin.elements.item(i);
            if (j_username.name == "j_username")
                break;
        }
        for (var i = 0; i < formLogin.elements.length; ++i) {
            var j_password = formLogin.elements.item(i);
            if (j_password.name == "j_password")
                break;
        }
        for (var i = 0; i < formLogin.elements.length; ++i) {
            var submitLogin = formLogin.elements.item(i);
            if (submitLogin.idName == "buttonlogin")
                break;
        }
        j_username.value = userName;
        j_password.value = thePassword;
        logger.logDebug("submit button: " + submitLogin + ", id: " + submitLogin.idName);
        
    } else if (LoginURL.indexOf("wartung") !== -1) {
        logger.logError("DKB site currently not available");
        currentState = 0;
        webClient.callback = null;
        return;
        
        // Might be good to use a similar response handling as is used in Hibiscus, e.g.
        //HibiscusScripting_DKBVisa_checkResponse(pageLoginXML, pageLogin, "Login", monitor);
    } else {
        throw "Invalid login URL. Please inform the developers.";
    };
    
    currentState = (currentState == 1) ? 2 : 12;
    submitLogin.click();
    logger.logInfo("Login process triggered");
}

function navigateToCreditCardPage() {
    logger.logDebug("Navigating to credit card page");
    
    var url = webClient.URL;
    if (url.indexOf("/portal") !== -1) {
        // todo: url = dkbBaseURL + ActiveContent.getAnchorByText("Kreditkartenums\u00E4tze").getHrefAttribute();
    } else if (url.indexOf("/banking") !== -1) {
        url = dkbCardSelectionURL;
    } else {
        throw "Unknown URL, couldn't get credit card overview";
    };
    
    currentState = 13;
    webClient.URL = url;
}

var currentCreditCardIndex;

function startCreditCardLoop() {
    currentCreditCardIndex = -1;
    readNextCreditCard();
}

function padDatePart(i) {
    return (i < 10) ? "0" + i : "" + i;
}

function readNextCreditCard() {
    if (++currentCreditCardIndex >= numbers.length) {
        // We are done.
        webClient.resultsArrived(results);
        logOut();
        return;
    };
    
    var url = webClient.URL;
    if (url.indexOf("/portal") !== -1) {
        // todo
    } else if (url.indexOf("/banking") !== -1) {
        for (var i = 0; i < webClient.mainFrameDocument.forms.length; ++i) {
            var form = webClient.mainFrameDocument.forms.item(i);
            if (form.name == "form1579108072_1")
                break;
        }
        //var form = webClient.mainFrameDocument.forms.namedItem("form1579108072_1"); namedItem doesn't work on forms it seems.
        for (var i = 0; i < form.elements.length; ++i) {
            var creditCardSelector = form.elements.item(i);
            if (creditCardSelector.name == "slAllAccounts")
                break;
        }
    } else {
        throw "Unknown URL, couldn't get credit card overview";
    };
    
    logger.logDebug("CC selector: " + creditCardSelector);
    var ccNumber = numbers[currentCreditCardIndex].substr(0, 4) + "********" + numbers[currentCreditCardIndex].substr(numbers[currentCreditCardIndex].length - 4, 4);
    logger.logDebug("Looking for credit card entry: " + ccNumber);
    
    var list = creditCardSelector.options;
    for (var i = 0; i < list.length; ++i) {
        var creditCardEntry = list.item(i);
        logger.logVerbose("CC item: " + creditCardEntry.text);
        if (creditCardEntry.text.substr(0, 16) == ccNumber) {
            creditCardEntry.selected = true;
            ccNumber = "***";
            break;
        };
    };
    
    if (ccNumber != "***") {
        // Credit card not found.
        logger.logError("Couldn't find credit card in list (" + ccNumber + ")");
        readNextCreditCard();
        return;
    };
    
    // Somehow I cannot get getElementsByName and getElementById to work as expected.
    // logger.logDebug("Search element: " + webClient.mainFrameDocument.getElementById("searchPeriod.0"));
    /*
     for (var i = 0; i < form.elements.length; ++i) {
     var element = form.elements.item(i);
     if (element.idName == "searchPeriod.0") {
     logger.logDebug("searchPeriod: " + element);
     element.checked = true; // Select date range input.
     break;
     }
     }
     */
    for (var i = 0; i < form.elements.length; ++i) {
        var periodSelector = form.elements.item(i);
        if (periodSelector.name == "slSearchPeriod")
            break;
    }
    logger.logDebug("Period selector: " + periodSelector);
    var periods = periodSelector.options;
    for (i = 0; i < periods.length; ++i) {
        var periodEntry = periods.item(i);
        logger.logVerbose("Period item: " + periodEntry.text);
        if (periodEntry.value == "3") {
            periodEntry.selected = true;
            break;
        };
    };
    
    for (var i = 0; i < form.elements.length; ++i) {
        var postingDate = form.elements.item(i);
        if (postingDate.name == "postingDate")
            break;
    }
    for (var i = 0; i < form.elements.length; ++i) {
        var toPostingDate = form.elements.item(i);
        if (toPostingDate.name == "toPostingDate")
            break;
    }
    logger.logDebug("From posting element: " + postingDate);
    logger.logDebug("To posting element: " + toPostingDate);
    
    postingDate.value = padDatePart(startFrom.getDate()) + "." + padDatePart(startFrom.getMonth() + 1) + "." + startFrom.getFullYear();
    toPostingDate.value = padDatePart(endAt.getDate()) + "." + padDatePart(endAt.getMonth() + 1) + "." + endAt.getFullYear();
    
    logger.logDebug("Date range: " + postingDate.value + " .. " + toPostingDate.value);
    
    currentState = 14;
    for (var i = 0; i < form.elements.length; ++i) {
        var button = form.elements.item(i);
        if (button.idName == "searchbutton")
            break;
    }
    logger.logDebug("Button: " + button + ", " + button.idName)
    button.click();
}

function convertCsvToResult() {
    
    logger.logDebug("Converting results");
    var lines = webClient.mainFrameDocument.body.innerText.split("\n");
    logger.logVerbose("CSV data: " + lines);
    
    var statements = [];
    var headers = ["final", "valutaDate", "date", "transactionText", "value", "originalValue"];
    
    // Balance value is in prefix lines.
    var balance = "0 EUR";
    var lastSettleDate = new Date();
    for (var i = 0; i < 7; ++i) {
        var currentLine = lines[i].split(";");
        logger.logVerbose("CSV line " + i + ", values: " + currentLine);
        
        if (currentLine.length > 0) {
            if (unquote(currentLine[0]) == "Saldo:") {
                balance = unquote(currentLine[1]);
                break;
            }
            if (unquote(currentLine[0]) == "Datum:") {
                var parts = unquote(currentLine[1]).split('.');
                lastSettleDate = new Date(parts[2], parts[1] - 1, parts[0]);
                break;
            }
        }
    }
    
    for (var i = 7; i < lines.length; ++i) {
        var statement = {};
        var currentLine = lines[i].split(";");
        
        // This field seems not what we understand from it. Even though it might say the value
        // is not yet processed it is actually already contained in the balance.
        statement["final"] = true; //unquote(currentLine[0]) == "Ja" ? true : false;
        
        var parts = unquote(currentLine[1]).split('.');
        if (parts.length == 3)
            statement["valutaDate"] = new Date(parts[2], parts[1] - 1, parts[0]);
        
        parts = unquote(currentLine[2]).split('.');
        if (parts.length == 3)
            statement["date"] = new Date(parts[2], parts[1] - 1, parts[0]);
        else
            statement["final"] = false; // DKB now marks preliminary statements by not specifying a transaction date.
        
        for (var j = 3; j < headers.length; ++j) {
            statement[headers[j]] = unquote(currentLine[j]);
        }
        
        statements.push(statement);
    }
    
    var result = {
        "isCreditCard": true,
        "account": numbers[currentCreditCardIndex],
        "balance": balance,
        "statements": statements,
        "lastSettleDate": lastSettleDate
    };
    results.push(result);
    
    logger.logDebug("Done converting a set of results");
    currentState = 16;
    webClient.goBack(); // Back to credit card selection.
}

function errorExit(message) {
    try
    {
        logger.logVerbose("Accounts: " + numbers);
        logger.logVerbose("currentCreditCardIndex: " + currentCreditCardIndex);
        
        var index = (currentCreditCardIndex == undefined) ? 0 : currentCreditCardIndex;
        webClient.reportError(numbers[index], message);
        webClient.resultsArrived(results);
    }
    finally {
        //logOut();
    }
}

function sleepFor(sleepDuration) { // Debugging helper.
    var now = new Date().getTime();
    while(new Date().getTime() < now + sleepDuration) { /* do nothing */ }
}

function unquote(text) {
    if (text == undefined)
        return "";
    
    if ((text[0] === "\"" && text[text.length - 1] === "\"") || (text[0] === "'" && text[text.length - 1] === "'")) {
        return text.slice(1, text.length - 1);
    };
    return text;
}

true; // Return flag to indicate if parsing the file was successfull.
