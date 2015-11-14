// JS banking plugin for Pecunia
// Author: Marc Szymamski, with help from the BoS script in Hibiscus (http://www.willuhn.de/products/hibiscus/)
//
// Plugin to read BoS account statements from the BoS website (www.bankofscotland.de).

// Plugin details used to manage usage. Name and description are mandatory.
var name = "pecunia.plugin.bostag";
var author = "Marc Szymanski";
var description = "BoS Tagesgeldkonto"; // Short string for plugin selection.
var homePage = "http://pecuniabanking.de";
var license = "CC BY-NC-ND 4.0 - http://creativecommons.org/licenses/by-nc-nd/4.0/deed.de";
var version = "1.0";

// --- Internal variables.

// Base URL for the bos banking site.
var bosBaseURL = "https://banking.bankofscotland.de/netbanking/RetailLoginHome.html";


/**********************************
 * Check and initialize functions *
 **********************************/

// Optionial function to support auto account type determination.
// Is called by pecunia.
function canHandle(account, bankCode) {
    if (bankCode != "50220500")
        return false;

    // bos accounts have 8 digits
    if (account.length != 8)
        return false;

    return true;
}

// Initializes the account data.
// It's called by pecunia.
function getStatements(user, bankCode, _passwords, from, to, _accountNumbers) {
    arguments.callee.userName       = user;
    arguments.callee.accountNumbers = _accountNumbers;
    arguments.callee.startFrom      = from;
    arguments.callee.endAt          = to;
    arguments.callee.thePassword    = _passwords.split("|||");
    
    //logger.logDebug(arguments.callee.thePassword[0] + " : " + arguments.callee.thePassword[1]);
    if (user == "") {
        logger.logError("Login: user name empty");
        return false;
    }

    logger.logDebug("Statements for user : " + arguments.callee.userName);
    logger.logDebug("From : "                + arguments.callee.startFrom);
    logger.logDebug("To : "                  + arguments.callee.endAt);
    logger.logDebug("Accounts : "            + arguments.callee.accountNumbers);

    setState(states.LOGIN_STATEMENT);
    navigationCallback.singleStep   = false;
    webClient.callback              = navigationCallback;
    webClient.URL                   = bosBaseURL;

    return true;
}


/******************************************************
 * Core state machine for async web scraping handling *
 ******************************************************/

// define the states of the statemachine
var states = {
    UNREGISTER          : 'unregister',
    LOGIN               : 'login',
    LOGIN_STATEMENT     : 'login with statement',
    SUBMIT_BUTTON       : 'submit button click',
    SECURITY_QUESTION   : 'security question',
    CHECK_USER          : 'check username',
    NAVIGATE_ACC        : 'navigate to account',
    READ_ACC            : 'read account',
    LOGOUT              : 'logout',
    RESULTS_ARRIVED     : 'send results to pecunia',
    REQUEST             : 'request data',
    LOGIN_ERROR         : 'error during login',
    IDLE                : 'idle state'
};

// setting states
function setState(newState) {
    navigationCallback.oldState = navigationCallback.currentState;
    navigationCallback.currentState = newState;
    return;
}

// Called from the plugin worker, e.g. after navigating to a new page or when executing a single step.
// Implements our state machine.
// Is called by pecunia.
function navigationCallback(doStep) {
    // for debugging purpose (I guess)
    arguments.callee.singleStep = arguments.callee.singleStep || false;
    
    // Used in the callback to determine what to do next (state machine).
    arguments.callee.currentState = arguments.callee.currentState || states.LOGIN_STATEMENT;
    // Used in the callback to determine what was the last state (state machine).
    arguments.callee.oldState =  arguments.callee.oldState || states.UNREGISTER;
    
    if (arguments.callee.singleStep) {
        // We executed a step and hold the state machine here.
        arguments.callee.singleStep = false;
        return;
    }

    if (doStep) {
        // Got the command to run only one step. Continue with the current state
        // but stop the state machine when this is finished.
        arguments.callee.singleStep = true;
    }
    
    logger.logDebug("State machine at: " + arguments.callee.currentState);
    try {
        switch (arguments.callee.currentState) {
            case states.LOGIN, states.LOGIN_STATEMENT: // 1 for pure login, 11 for login + statements.
                if ( startLogin(webClient) ) {
                    setState(states.SUBMIT_BUTTON);
                    return;
                }
                break;
                
            case states.SUBMIT_BUTTON:
                if ( submitButton(webClient) ) {
                    setState(states.CHECK_USER);
                } else {
                }
                break;
                
            case states.CHECK_USER: //check if user name was correct
                if ( checkUserName(webClient) ) {
                    setState(states.SECURITY_QUESTION);
                    navigationCallback(false, "");
                    return;
                } else {
                    // TODO: localization support.
                    logger.logError("authentification failed with wrong user name");
                    webClient.reportError("Die Anmeldung ist fehlgeschlagen.\n\nEs wurde der falsche Benutzername verwendet oder das Konto wurde gesperrt!");
                    setState(states.LOGIN_ERROR);
                    navigationCallback(false, "");
                    return;
                }
                break;
                
            case states.SECURITY_QUESTION:
                
                if (answerSecurityQuestion(webClient)) {
                    setState(states.NAVIGATE_ACC);
                    navigationCallback(false, "");
                    return;
                } else {
                    setState(states.SUBMIT_BUTTON);
                    navigationCallback(false, "");
                    return;
                }
                break;
            
            case states.NAVIGATE_ACC:
                //getting the first account page
                if ( checkSecurityQuestion(webClient) ) {
                    if (navigateToAccountPage(webClient)) {
                        
                        setState(states.REQUEST);
                        getAccountData.currentPageNum         = 1;
                        getAccountData.currentAccountIndex    = 0;
                        getAccountData.currentAccountInfo     = [];
                        getAccountData.Statements             = [];
                        getAccountData.results                = [];
                        
                        checkSecurityQuestion.secCheckCounter = 0;
                        

                        navigationCallback(false, "");
                        return;
                    } else {
                        //wait for page load
                    }
                } else {
                    // TODO: localization support.
                    logger.logError("authentification failed with wrong passwords");
                    webClient.reportError("Die Anmeldung ist fehlgeschlagen.\nDie Sicherheitsabfragen schlugen fehl!");
                    setState(states.LOGIN_ERROR);
                    navigationCallback(false, "");
                    return;
                }
                setState(states.NAVIGATE_ACC);
                break;
                
            case states.REQUEST:
                if (getStatements.accountNumbers[getAccountData.currentAccountIndex] === undefined) {
                    setState(states.RESULTS_ARRIVED); // we read all accounts
                    navigationCallback(false, "");
                    return;
                }
                
                setState(states.IDLE); //make sure that we really wait for a response that we are not triggered by a frame load
                requestAccountPage(navigateToAccountPage.sessionID, getAccountData.currentPageNum, getStatements.accountNumbers[getAccountData.currentAccountIndex].trim());
                //wait for async answer
                return;
            
            case states.IDLE:
                break;
                
            case states.READ_ACC:
                //parse account data
                logger.logInfo("parsed account " + getStatements.accountNumbers[getAccountData.currentAccountIndex].trim() +
                               " (" + (getAccountData.currentAccountIndex+1) + "/" + getStatements.accountNumbers.length + ") at " +
                               "page " + getAccountData.currentPageNum);
                
                var data = webClient.mainFrameDocument.documentElement.innerHTML;
                //logger.logDebug(data);
                
                if (getAccountData(data,getStatements.accountNumbers) == false) { //last page for account
                    // try next account
                    logger.logDebug("next account");
                } else {
                }
                
                setState(states.REQUEST);
                navigationCallback(false, "");
                return;
 
            case states.RESULTS_ARRIVED:
                // We are done.
                webClient.resultsArrived(getAccountData.results);
                logOut();
                return;
            
            case states.LOGIN_ERROR:
                webClient.resultsArrived([], "", "");
                
            case states.LOGOUT:
                logger.logInfo("Log out done");
                // Fall through;
            default:
                setState(states.UNREGISTER);
                webClient.callback = null; // Unregister ourselve. We are done.
                logger.logInfo("Plugin invocation done");
        }
    } catch (err) {
        if (arguments.callee.currentState != states.LOGOUT) // If exception not triggered by logout
            logOut();
        throw err;
    }
}

/****************************
 * State handling functions *
 ****************************/
function startLogin(webClient) {

    try {
        var formLogin = webClient.mainFrame.childFrames[3].document.forms.item(0);
        
        formLogin.elements.namedItem("fldLoginUserId").value = getStatements.userName;
        formLogin.elements.namedItem("fldPassword").value = getStatements.thePassword[0];
        
        logger.logInfo("running login");
        logger.logDebug("formLogin: " + formLogin + ", name: " + formLogin.name + ", action: " + formLogin.action);
    } catch (err) {
        logger.logVerbose("startLogin: " + err);
        return false;
    }

    return true;
}

function submitButton(webClient) {
    try {
        var formLogin = webClient.mainFrame.childFrames[3].document.forms.item(0);
        var submitLogin = formLogin.elements.namedItem("btnContinue");
        
        logger.logVerbose("submitButton: " + submitLogin + ", text: " + submitLogin.alt);
        
        var buttonClick = submitLogin.click();//press the button
        logger.logDebug("login process triggered");
        sleepFor(1000);
    } catch (err) {
        logger.logVerbose("submitButton: " + err);
        return false;
    }
    
    return true;
}

function checkUserName(webClient) {
    
    var formLogin = webClient.mainFrame.childFrames[3];
    
    if (formLogin !== undefined ) {
        logger.logInfo("user name accepted")
        return true
    } else {
        logger.logError("user name NOT accepted")
        return false;
    }
    
}

function answerSecurityQuestion(webClient) {
    try {
        var formLogin = webClient.mainFrame.childFrames[3].document.forms.item(0);
        
        var answerElement = formLogin.elements.namedItem("fldanswer1");
        
        answerElement.value = getStatements.thePassword[1];
        
        logger.logDebug("question: " + formLogin.elements.namedItem("fldquestion1").defaultValue);
        
        var submitLogin = formLogin.elements.namedItem("fldGO");
        logger.logDebug("submit button: " + submitLogin + ", text: " + submitLogin.alt);

        logger.logInfo("answering security question");
        logger.logDebug("formLogin: " + formLogin + ", name: " + formLogin.name + ", action: " + formLogin.action);
        
        sleepFor(1000); // that's not cool but it seems that we do have timing issues if we the click event comes to early
        
        submitLogin.click();//press the button
        logger.logDebug("security question process triggered ");
        
        //TODO: LOGIN_ERRO if security question or password was wrong!
        
    } catch (err) {
        logger.logVerbose("answerSecurityQuestion: " + err);
        return false;
    }
    return true;
    
}

function checkSecurityQuestion(webClient) {
    arguments.callee.secCheckCounter = arguments.callee.secCheckCounter || 0;
    
    // I am sorry for this kind of check, but it was the only way I could descriminate between a successful and an unsuccessful answer.
    try {
        
        var messageFrame = webClient.mainFrame.childFrames[2].frameElement;
        
        if (arguments.callee.secCheckCounter > 0 &&
            messageFrame.outerHTML.indexOf('<frame src="display_message.htm"') !== -1) {
            
            logger.logInfo("Security question failed ");
            logger.logDebug("secCheckCounter : " + arguments.callee.secCheckCounter + "\n" + messageFrame.outerHTML);
            
            arguments.callee.secCheckCounter = 0;
            return false;
        } else if (arguments.callee.secCheckCounter == 3) {
            logger.logInfo("answer to security question is correct");
        }
        arguments.callee.secCheckCounter++;
        
    } catch (err) {
        logger.logVerbose("checkSecurityQuestion: " + err);
        return true;
    }

    return true;
}

function navigateToAccountPage(webClient) {
    arguments.callee.sessionID = arguments.callee.sessionID || "";
    
    try {
        var domDoc = webClient.mainFrame.childFrames[1].document;
        
        // this is what we need! the session ID
        arguments.callee.sessionID = domDoc.forms.item(0).elements.namedItem("fldSessionId").value;
        logger.logDebug("getting session ID: " + arguments.callee.sessionID);
        
    } catch (err) {
        logger.logVerbose("navigateToAccountPage: " + err);
        return false;
    }
    return true;
}

function logOut() {
    logger.logDebug("starting log out");
    setState(states.LOGOUT);
    getStatements.userName = "";
    getStatements.thePassword = "";
    
    var logOutRequest = [{
                         "method" : "POST",
                         "action" : "https://banking.bankofscotland.de/netbanking/internet"
                         }, {
                         "TabTitle"     : "+",
                         "fldRequestId" : "RRLGF02",
                         "fldSessionId" : navigateToAccountPage.sessionID,
                         "fldGroup"     : "01AC",
                         "fldDefTxnId"  : "ASM",
                         "fldSectionId" : "RRLGN08",
                         "fldDataId"    : navigateToAccountPage.sessionID,
                         }];
    
    
    //send request
    setState(states.LOGOUT);
    logger.logInfo("logout request sent");
    fireRequest(logOutRequest);
}

/***********************************
 * Functions handling account data *
 ***********************************/

function getAccountData(data, accounts) {
    arguments.callee.accountInfo        = arguments.callee.accountInfo || [];
    arguments.callee.statements         = arguments.callee.statements || [];
    arguments.callee.results            = arguments.callee.results || [];
    arguments.callee.currentPageNum     = arguments.callee.currentPageNum || 1;
    arguments.callee.currentAccountIndex= arguments.callee.currentAccountIndex || 0;
    
    //what happens if the requested account number is faulty and does not exist
    if ( data.indexOf('<tr class="AlterRow2">') == -1) {
        logger.logError("Couldn't find credit card in list (" + accounts[arguments.callee.currentAccountIndex] + ")");
        //try next account
        arguments.callee.currentAccountIndex++;
        arguments.callee.currentPageNum = 1; //reset page counter
        return false;
    }
    
    logger.logDebug("parsing page: " + arguments.callee.currentPageNum);
    
    //page exists
    if (arguments.callee.currentPageNum == 1) {
        arguments.callee.accountInfo = parseAccountData(data);
        logger.logVerbose(JSON.stringify(arguments.callee.accountInfo));
        //logger.logDebug("---------------------------\n"+                        JSON.stringify(accountInfo));
    }
    
    if (parseDataForTransactions(data)) {
        arguments.callee.currentPageNum++;
        return true; // there is still a page to be read
    } else {
        // page does not exist
        // lets push everthing we have to results
        // should be done for last page
        var result = {
            "isCreditCard" : false,
            //"isBankStatement" : true,
            "account": arguments.callee.accountInfo["account"],
            "balance": arguments.callee.accountInfo["balance"],
            "statements": arguments.callee.statements,
            "lastSettleDate": arguments.callee.statements[0]["date"],
            "bankCode" : arguments.callee.accountInfo["bankCode"]
        };
        arguments.callee.statements = [];
        arguments.callee.results.push(result);
        logger.logDebug(JSON.stringify(result));
        
    }
    arguments.callee.currentAccountIndex++;
    arguments.callee.currentPageNum = 1; //reset page counter
    logger.logDebug("no more page left for this account");
    return false; // there is no page to be read for this account
}

/* parses general account information
 */
function parseAccountData(data) {

    var sub = data.substring(data.indexOf('<tr class="AlterRow2">'),data.indexOf('<table class="TableNoBorder"'));
    sub = removeTags(sub);
    
    var acInfo = sub.split('|');
    
    //logger.logDebug(JSON.stringify(acInfo));
    return {
        "account"       : acInfo[2],
        "bankCode"      : acInfo[4],
        "IBAN"          : acInfo[6],
        "BIC"           : acInfo[8],
        "type"          : acInfo[10],
        "balance"       : acInfo[12] + " EUR"
    };
}

/* parses the transactions from the received html-page
 */
function parseDataForTransactions(data) {
    var testString = '<tr class="AlterRow2">'
    
    // scip the useless headers
    var sub = data.substring(data.indexOf(testString) + testString.length , data.length);
    sub = sub.substring(sub.indexOf(testString) + testString.length ,data.length);
    
    // parse transactions
    while ( sub.indexOf('<tr class="AlterRow2">') !== -1 ) {
        var workSub = sub.substring(0, sub.indexOf('<tr class="AlterRow2">'));
        var statement = removeTags(workSub).split('|');
        sub = sub.substring(sub.indexOf(testString) + testString.length ,data.length);
        getAccountData.statements.push(newTransactionEntry(statement));
    }
    //do not forget the last entry
    var workSub = sub.substring(0, sub.indexOf('</table>'));
    var statement = removeTags(workSub).split('|');
    
    //logger.logDebug(statement.length + " ::: " + removeTags(workSub));
    
    if (statement.length == 17) { //if statement length is 17 it is valide!
        getAccountData.statements.push(newTransactionEntry(statement));
        return true; // we need to check the next page
    }
    return false; // we parsed the wrong data page seems to end
}

/* parses a single transaction and returns a statement map
 */
function newTransactionEntry(statement) {
    
    //0:, 1: Buchung, 2: , 3: Wertstellung, 4:, 5: name, 6:, 7:Verwendungszweck,8: ,9:,10:,11:Soll,12:,13:Haben,14:,15:
    var value = "";
    if (statement[11] != "") {
        value = "-" + statement[11] + " EUR";
    } else {
        value = statement[13] + " EUR";
    }
    var transaction = {
        "final"         : true, //(false für vorgemerkte Umsätze)
        "valutaDate"    : trimDateString(statement[3]), //(Wertstellungsdatum)
        "date"          : trimDateString(statement[1]), //(Buchungsdatum)
        "transactionText" : statement[7], //(Verwendungszweck)
        "value"         : value , //(Umsatz als String, korrekte Konvertierung erfolgt in Pecunia)
        "originalValue" : value,//dito wie "value" (für Umsätze die von anderen Währungen stammen)
        "customerReference" : statement[5]
    }
    
    logger.logVerbose(JSON.stringify(transaction));
    
    return transaction;
}

/*************************************
 * HTTP request and response handler *
 *************************************/


//prepare request for account page and submit
function requestAccountPage(sessionID, pageNum, accountNum) {
    
    var bos_getAccNumber    = accountNum + "~C~001";
    var dateFrom            = getStatements.startFrom.format("dd.mm.yyyy");
    var dateFrom1           = getStatements.startFrom.format("dd-mm-yyyy");
    var dateTo              = getStatements.endAt.format("dd.mm.yyyy");
    var dateTo1             = getStatements.endAt.format("dd-mm-yyyy");
                    
    var accountPageRequest = [
                   {
                   "method" : "POST",
                   "action" : "https://banking.bankofscotland.de/netbanking/internet"
                   },
                   {
                   "fldacctno"     : bos_getAccNumber,
                   "fldsearch1"    : "3",
                   "fldtranstype"  : "0",
                   
                   "fldfromdate"   : dateFrom,
                   "fldtodate"     : dateTo,
                   "fldfromdate1"  : dateFrom1,
                   "fldtodate1"    : dateTo1,
                   
                   "fldfromamount" : "",
                   "fldfromamount1" : "",
                   "fldtoamount1"  : "",
                   "fldtoamount"   : "",
                   
                   "fldsortby"      : "2",
                   "fldsortorder"   : "0",
                   
                   "fldfday"         : "",
                   "fldfmth"        : "",
                   "fldfyear"        : "",
                   "fldtday"         : "",
                   "fldtmth"        : "",
                   "fldtyear"        : "",
                   
                   "fldignoredate" : "0",
                   "fldPageNo"     : ""+pageNum+"",
                   "fldaccttype"   : "C",
                   "fldRequestId"  : "RRAAC02",
                   "fldSessionId"  : sessionID,
                   "fldServiceType" : "AAC",
                   "fldacctactinquireflg" : "testflag",

                   "fldsearch"     : "3",
                   "fldidlang"     : "ger",
                   "fldcurr1"      : "EUR"
                   }
                   ];
    
    logger.logVerbose("request: \n" + JSON.stringify(accountPageRequest));

    setState(states.READ_ACC);
    logger.logDebug("fired account data request");
    fireRequest(accountPageRequest);
}

function fireRequest(queries) {
    var requestURL = queries[0]["action"]+"?";
    
    for (var key in queries[1]) {
        requestURL += key + "=" + queries[1][key] + "&";
    }
    webClient.postURL = requestURL.slice(0,-1);
}

/*********************
 * Utility functions *
 *********************/
/* Removes all http tags < ... >, </ ... > or < ... /> from a string and leaves only the text inbetween seperated by a '|'.
 * returns the trimmed string
 */
function removeTags(sub) {
    while (sub.indexOf('<') !== -1) {
        sub = sub.slice(0, sub.indexOf('<')).trim() + '|' + sub.slice(sub.indexOf('>')+1,sub.length).trim();
    }
    return sub;
}

function trimDateString(dateString) {
    var parts = dateString.split('.');
    return new Date(parts[2], parts[1] - 1, parts[0]);
}

function sleepFor(sleepDuration) { // Debugging helper.
    var now = new Date().getTime();
    while(new Date().getTime() < now + sleepDuration) { /* do nothing */ } 
}


/*****************************
 * External source libraries *
 *****************************/

/*
 * Date Format 1.2.3
 * (c) 2007-2009 Steven Levithan <stevenlevithan.com>
 * MIT license
 *
 * Includes enhancements by Scott Trenda <scott.trenda.net>
 * and Kris Kowal <cixar.com/~kris.kowal/>
 *
 * Accepts a date, a mask, or a date and a mask.
 * Returns a formatted version of the given date.
 * The date defaults to the current date/time.
 * The mask defaults to dateFormat.masks.default.
 */

var dateFormat = function () {
    var token = /d{1,4}|m{1,4}|yy(?:yy)?|([HhMsTt])\1?|[LloSZ]|"[^"]*"|'[^']*'/g,
    timezone = /\b(?:[PMCEA][SDP]T|(?:Pacific|Mountain|Central|Eastern|Atlantic) (?:Standard|Daylight|Prevailing) Time|(?:GMT|UTC)(?:[-+]\d{4})?)\b/g,
    timezoneClip = /[^-+\dA-Z]/g,
    pad = function (val, len) {
        val = String(val);
        len = len || 2;
        while (val.length < len) val = "0" + val;
        return val;
    };
    
    // Regexes and supporting functions are cached through closure
    return function (date, mask, utc) {
        var dF = dateFormat;
        
        // You can't provide utc if you skip other args (use the "UTC:" mask prefix)
        if (arguments.length == 1 && Object.prototype.toString.call(date) == "[object String]" && !/\d/.test(date)) {
            mask = date;
            date = undefined;
        }
        
        // Passing date through Date applies Date.parse, if necessary
        date = date ? new Date(date) : new Date;
        if (isNaN(date)) throw SyntaxError("invalid date");
        
        mask = String(dF.masks[mask] || mask || dF.masks["default"]);
        
        // Allow setting the utc argument via the mask
        if (mask.slice(0, 4) == "UTC:") {
            mask = mask.slice(4);
            utc = true;
        }
        
        var _ = utc ? "getUTC" : "get",
        d = date[_ + "Date"](),
        D = date[_ + "Day"](),
        m = date[_ + "Month"](),
        y = date[_ + "FullYear"](),
        H = date[_ + "Hours"](),
        M = date[_ + "Minutes"](),
        s = date[_ + "Seconds"](),
        L = date[_ + "Milliseconds"](),
        o = utc ? 0 : date.getTimezoneOffset(),
        flags = {
        d:    d,
        dd:   pad(d),
        ddd:  dF.i18n.dayNames[D],
        dddd: dF.i18n.dayNames[D + 7],
        m:    m + 1,
        mm:   pad(m + 1),
        mmm:  dF.i18n.monthNames[m],
        mmmm: dF.i18n.monthNames[m + 12],
        yy:   String(y).slice(2),
        yyyy: y,
        h:    H % 12 || 12,
        hh:   pad(H % 12 || 12),
        H:    H,
        HH:   pad(H),
        M:    M,
        MM:   pad(M),
        s:    s,
        ss:   pad(s),
        l:    pad(L, 3),
        L:    pad(L > 99 ? Math.round(L / 10) : L),
        t:    H < 12 ? "a"  : "p",
        tt:   H < 12 ? "am" : "pm",
        T:    H < 12 ? "A"  : "P",
        TT:   H < 12 ? "AM" : "PM",
        Z:    utc ? "UTC" : (String(date).match(timezone) || [""]).pop().replace(timezoneClip, ""),
        o:    (o > 0 ? "-" : "+") + pad(Math.floor(Math.abs(o) / 60) * 100 + Math.abs(o) % 60, 4),
        S:    ["th", "st", "nd", "rd"][d % 10 > 3 ? 0 : (d % 100 - d % 10 != 10) * d % 10]
        };
        
        return mask.replace(token, function ($0) {
                            return $0 in flags ? flags[$0] : $0.slice(1, $0.length - 1);
                            });
    };
}();

// Some common format strings
dateFormat.masks = {
    "default" :      "ddd mmm dd yyyy HH:MM:ss",
    shortDate :      "m/d/yy",
    mediumDate :     "mmm d, yyyy",
    longDate :       "mmmm d, yyyy",
    fullDate :       "dddd, mmmm d, yyyy",
    shortTime :      "h:MM TT",
    mediumTime :     "h:MM:ss TT",
    longTime :       "h:MM:ss TT Z",
    isoDate :        "yyyy-mm-dd",
    isoTime :        "HH:MM:ss",
    isoDateTime :    "yyyy-mm-dd'T'HH:MM:ss",
    isoUtcDateTime : "UTC:yyyy-mm-dd'T'HH:MM:ss'Z'"
};

// Internationalization strings
dateFormat.i18n = {
dayNames: [
           "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat",
           "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
           ],
monthNames: [
             "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
             "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
             ]
};

// For convenience...
Date.prototype.format = function (mask, utc) {
    return dateFormat(this, mask, utc);
};

true; // Return flag to indicate if parsing the file was successfull.
