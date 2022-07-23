/**
* Copyright (c) 2014, 2015, Pecunia Project. All rights reserved.
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation; version 2 of the
* License.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
* 02110-1301  USA
*/

// Based largely on a Gist created by Ullrich Schäfer.

// Bitmasks are a bit tricky in swift
// See http://natecook.com/blog/2014/07/swift-options-bitmask-generator/

//enum LogFlag: Int32 {
//    case Error   = 0b1
//    case Warn    = 0b10
//    case Info    = 0b100
//    case Debug   = 0b1000
//    case Verbose = 0b10000
//}

import Foundation

// Use those class properties insted of `#define LOG_LEVEL_DEF` and `LOG_ASYNC_ENABLED`
extension DDLog {
    fileprivate struct Static {
        // Class variables are not yet supported in Swift. So temporarly use static vars instead.
        static var logLevel : DDLogLevel?
        static var logAsync : Bool?
    }

    @objc class var logLevel: DDLogLevel {
        get {
            return Static.logLevel ?? DDLogLevel.error
        }
        set(logLevel) {
            Static.logLevel = logLevel
        }
    }

    class var logAsync: Bool {
        get {
            return (self.logLevel != DDLogLevel.error) && (Static.logAsync ?? true)
        }
        set(logAsync) {
            Static.logAsync = logAsync
        }
    }

    class func doLog(_ flag: DDLogFlag, message: String, function: String?, file: String?, line: Int32, arguments: [CVarArg]) {
        let level: DDLogLevel = DDLog.logLevel
        let async: Bool = (level != DDLogLevel.error) && DDLog.logAsync

        if (flag.rawValue & level.rawValue) != 0 {
            
            var format : String;
            switch (flag) {
            case DDLogFlag.error:
                format = "[Error] " + message;
                break;

            case DDLogFlag.warning:
                format = "[Warning] " + message;
                break;

            case DDLogFlag.info:
                format = "[Info] " + message;
                break;

            case DDLogFlag.debug:
                format = "[Debug] " + message;
                break;

            case DDLogFlag.verbose:
                format = "[Verbose] " + message;
                break;

            default:
                format = message;
                break;
            }

            DDLog.log(asynchronous: async,
                      level: level,
                      flag: flag,
                      context: 0,
                      file: file ?? "<unknown>",
                      function: function ?? "<unknown>",
                      line: UInt(line),
                      tag:  nil,
                      format: format,
                      arguments: getVaList(arguments));
        }
    }
}

func logError(_ message: String, _ function: String = #function, _ file: String = #file, _ line: Int32 = #line, arguments: CVarArg ...) {
    //DDLog.doLog(DDLogFlag.error, message: message, function: function, file: file, line: line, arguments: arguments)
    return withVaList(arguments, { va_list in
        MessageLog.getLog().logError1(message, file: (file as NSString).utf8String!, function: (function as NSString).utf8String, line: line, arguments: va_list);
    })
    
}

func logWarning(_ message: String, _ function: String = #function, _ file: String = #file, _ line: Int32 = #line, arguments: CVarArg ...) {
    DDLog.doLog(DDLogFlag.warning, message: message, function: function, file: file, line: line, arguments: arguments)
}

func logInfo(_ message: String, _ function: String = #function, _ file: String = #file, _ line: Int32 = #line, arguments: CVarArg ...) {
    DDLog.doLog(DDLogFlag.info, message: message, function: function, file: file, line: line, arguments: arguments)
}

func logDebug(_ message: String, _ function: String = #function, _ file: String = #file, _ line: Int32 = #line, arguments: CVarArg ...) {
    DDLog.doLog(DDLogFlag.debug, message: message, function: function, file: file, line: line, arguments: arguments)
}

func logVerbose(_ message: String, _ function: String = #function, _ file: String = #file, _ line: Int32 = #line, arguments: CVarArg ...) {
    DDLog.doLog(DDLogFlag.verbose, message: message, function: function, file: file, line: line, arguments: arguments)
}

func logEnter(_ f: String = #function) {
    DDLog.doLog(DDLogFlag.debug, message: "Entering \(f)", function: nil, file: nil, line: 0, arguments: [])
}

func logLeave(_ f: String = #function ) {
    DDLog.doLog(DDLogFlag.debug, message: "Leaving \(f)", function: nil, file: nil, line: 0, arguments: [])
}
