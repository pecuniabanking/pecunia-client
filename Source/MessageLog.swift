/**
* Copyright (c) 2014, Pecunia Project. All rights reserved.
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

// Based largely on y Gist created by Ullrich Schäfer.

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
    private struct Static {
        // Class variables are not yet supported in Swift. So temporarly use static vars instead.
        static var logLevel : DDLogLevel?
        static var logAsync : Bool?
    }

    class var logLevel: DDLogLevel {
        get {
            return Static.logLevel ?? DDLogLevel.Error
        }
        set(logLevel) {
            Static.logLevel = logLevel
        }
    }

    class var logAsync: Bool {
        get {
            return (self.logLevel != DDLogLevel.Error) && (Static.logAsync ?? true)
        }
        set(logAsync) {
            Static.logAsync = logAsync
        }
    }

    class func doLog(flag: DDLogFlag, message: String, function: String?, file: String?, line: Int32, arguments: [CVarArgType])
    {
        let level: DDLogLevel = DDLog.logLevel
        let async: Bool = (level != DDLogLevel.Error) && DDLog.logAsync

        if (flag.rawValue & level.rawValue) != 0 {

            let fileName : UnsafePointer<Int8> = (file != nil) ? UnsafePointer(file!.dataUsingEncoding(NSUTF8StringEncoding)!.bytes) : nil
            let functionName : UnsafePointer<Int8> = (function != nil) ? UnsafePointer(function!.dataUsingEncoding(NSUTF8StringEncoding)!.bytes) : nil

            var format : String;
            switch (flag) {
            case DDLogFlag.Error:
                format = "[Error] " + message;
                break;

            case DDLogFlag.Warning:
                format = "[Warning] " + message;
                break;

            case DDLogFlag.Info:
                format = "[Info] " + message;
                break;

            case DDLogFlag.Debug:
                format = "[Debug] " + message;
                break;

            case DDLogFlag.Verbose:
                format = "[Verbose] " + message;
                break;

            default:
                format = message;
                break;
            }

            DDLog.log(async,
                level: level,
                flag: flag,
                context: 0,
                file: fileName,
                function: functionName,
                line: line,
                tag:  nil,
                format: format,
                args: getVaList(arguments));
        }
    }
}

func logError(message: String, _ function: String = __FUNCTION__, _ file: String = __FILE__, _ line: Int32 = __LINE__, #arguments: CVarArgType ...) {
    DDLog.doLog(DDLogFlag.Error, message: message, function: function, file: file, line: line, arguments: arguments)
}

func logWarning(message: String, _ function: String = __FUNCTION__, _ file: String = __FILE__, _ line: Int32 = __LINE__, #arguments: CVarArgType ...) {
    DDLog.doLog(DDLogFlag.Warning, message: message, function: function, file: file, line: line, arguments: arguments)
}

func logInfo(message: String, _ function: String = __FUNCTION__, _ file: String = __FILE__, _ line: Int32 = __LINE__, #arguments: CVarArgType ...) {
    DDLog.doLog(DDLogFlag.Info, message: message, function: function, file: file, line: line, arguments: arguments)
}

func logDebug(message: String, _ function: String = __FUNCTION__, _ file: String = __FILE__, _ line: Int32 = __LINE__, #arguments: CVarArgType ...) {
    DDLog.doLog(DDLogFlag.Debug, message: message, function: function, file: file, line: line, arguments: arguments)
}

func logVerbose(message: String, _ function: String = __FUNCTION__, _ file: String = __FILE__, _ line: Int32 = __LINE__, #arguments: CVarArgType ...) {
    DDLog.doLog(DDLogFlag.Verbose, message: message, function: function, file: file, line: line, arguments: arguments)
}

func logEnter(f: String = __FUNCTION__) {
    DDLog.doLog(DDLogFlag.Debug, message: "Entering \(f)", function: nil, file: nil, line: -1, arguments: [])
}

func logLeave(f: String = __FUNCTION__ ) {
    DDLog.doLog(DDLogFlag.Debug, message: "Leaving \(f)", function: nil, file: nil, line: -1, arguments: [])
}
