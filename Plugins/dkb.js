// JS banking plugin for Pecunia
// Author: Mike Lischke
//
// Plugin to read DKB credit card statements from the DKB website (www.dkb.de).

function logIn(user, password) {
	if (user == "") {
		logError("Login: user name empty");
		return false;
	}
	
	logInfo("Logging in user: " + user);
	
	var	formLogin = document.forms["login"];
	logDebug("Login form: " + formLogin);

	document.getElementsByName("j_username")[0].value = user;
	document.getElementsByName("j_password")[0].value = password;
	//var submitLogin = document.evaluate("//input[@id='buttonlogin']", formLogin, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
	var submitLogin = document.getElementById("buttonlogin");
	logDebug(submitLogin);

	logDebug("Sending login form...");
	try {
		submitLogin.click();
	} catch(err) {
		throw "Problems while logging in:\n" + err;
	};
	
	return true;
}

function getStatements(from, to) { // Parameters are dates.
	logDebug(from.toString());
	logDebug(to.toString());
	
	var result = [];
	return result;
}

/* Works but not sure we need jQuery at all.
(function() {
	logDebug("Loading jQuery...");
	
    var startingTime = new Date().getTime();
    // Load the script
    var script = document.createElement("SCRIPT");
    script.src = 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js';
    script.type = 'text/javascript';
    document.getElementsByTagName("head")[0].appendChild(script);

    // Poll for jQuery to come into existance
    var checkReady = function(callback) {
        if (window.jQuery) {
            callback(jQuery);
        }
        else {
            window.setTimeout(function() { checkReady(callback); }, 20);
        }
    };

    // Start polling...
    checkReady(function($) {
        $(function() {
            var endingTime = new Date().getTime();
            var tookTime = endingTime - startingTime;
            logDebug("jQuery is loaded, after " + tookTime + " milliseconds!");
        });
    });
})();
*/

true; // Return flag to indicate if parsing the file was successfull.
