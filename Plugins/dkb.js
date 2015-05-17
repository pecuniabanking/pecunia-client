// JS banking plugin for Pecunia
// Author: Mike Lischke
//
// Plugin to read DKB credit card statements from the DKB website (www.dkb.de).

var name = "pecunia.plugin.dkbvisa";
var author = "Mike Lischke";
var description = "DKB Kreditkartenkonto"; // Short string for plugin selection.
var homePage = "http://pecuniabanking.de";
var license = "CC BY-NC-ND 4.0 - http://creativecommons.org/licenses/by-nc-nd/4.0/deed.de";
var version = "1.0";

var currentState = 0; // Used in the callback to determine what to do next (state machine).
var userName = "";
var thePassword = "";

function logIn(user, password) {
	if (user == "") {
		Logger.logError("Login: user name empty");
		return false;
	}
	
	Logger.logInfo("Logging in user: " + user);
	userName = user;
	thePassword = password;
	currentState = 1;
	webClient.callback = navigationCallback;
	webClient.navigateTo("https://banking.dkb.de");
	
	return true;
}

function logOut() {
	Logger.logInfo("Starting log out...");
	currentState = 99;
	userName = "";
	thePassword = "";
	webClient.navigateTo("https://banking.dkb.de/dkb/-?$part=DkbTransactionBanking.infobar.logout-button&$event=logout");
	
	return true;
}

// Cache variables to allow for async loading.
var numbers;
var startFrom;
var endAt;

function getStatements(from, to, creditCardNumbers) { // 2 dates and an array of strings.
	numbers = creditCardNumbers;
	startFrom = from;
	endAt = to;
	
	Logger.logDebug(from.toString());
	Logger.logDebug(to.toString());
	
	var result = [];
	return result;
}

// Called when a new page is loaded in the webclient.
function navigationCallback() {
	switch (currentState) {
		case 1:
		try {
			var LoginURL = webClient.URL;
			Logger.logDebug("At URL: " + LoginURL + ", triggering login process");
			if (LoginURL.indexOf("/portal") !== -1) {
				Logger.debug("Running new portal login");
				/*
				var formLogin = pageLogin.getFirstByXPath("//form[@class='anmeldung']");
				Logger.logDebug("formLogin: " + formLogin + ", name: " + formLogin.name);
				formLogin.getFirstByXPath("//input[@maxlength='16']").setValueAttribute(ResponseLogin);
				formLogin.getFirstByXPath("//input[@type='password']").setValueAttribute(ResponsePasswort);
				var submitLogin = formLogin.getInputByValue("Anmelden");
				*/

			} else if (LoginURL.indexOf("/dkb") !== -1) {
				Logger.logDebug("Running old standard login");
				var formLogin = webClient.getFormByName("login");

				Logger.logDebug("formLogin: " + formLogin + ", name: " + formLogin.name);
				formLogin.getInputByName("j_username").valueAttribute = userName;
				formLogin.getInputByName("j_password").valueAttribute = thePassword;
				var submitLogin = formLogin.getElementById("buttonlogin");
				Logger.logDebug("submit button: " + submitLogin + ", id: " + submitLogin.id);

			} else if (LoginURL.indexOf("wartung") !== -1) {
				HibiscusScripting_DKBVisa_checkResponse(pageLoginXML, pageLogin, "Login", monitor);

			} else {
				throw "Invalid login URL. Please inform the developers.";
			};

			currentState = 2;
			submitLogin.click();
			Logger.logInfo("Login process triggered");

		} catch (err) {
			throw "An error occured while setting up login form (see log). \nThe error is: " + err;

		};
		break; // End of state 1.
		
		case 2: // Logged in, now collect statements.
			collectStatements();
			break;
			
		case 99:
			Logger.logInfo("Log out done");
			// Fall through;
		default:
			currentState = 0;
			webClient.callback = null; // Unregister ourselve. We are done.
	}	
}

// Collects
function collectStatements() {
	
}

true; // Return flag to indicate if parsing the file was successfull.
