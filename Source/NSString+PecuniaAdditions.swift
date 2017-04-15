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

import Foundation

extension NSString {
    /**
    * Processes the content of the receiver and creates a new string with a more natural appearance, if possible.
    * This mostly involves truecasing words.
    * This process depends on a large word library, so it's an optional feature. If the user decided
    * to disable it we do a simple capitalization.
    */
    public func stringWithNaturalText() -> NSString {
        if !WordMapping.wordMappingsAvailable {
            // While our word list is being loaded return a simple capitalized string.
            return self.capitalized as NSString;
        }

        let context = MOAssistant.shared().context;
        let request = NSFetchRequest<NSFetchRequestResult>();
        request.entity = NSEntityDescription.entity(forEntityName: "WordMapping", in: context!);

        let result = NSMutableString();
        let range = NSMakeRange(0, self.length);
        self.enumerateLinguisticTags(in: range, scheme: NSLinguisticTagSchemeLexicalClass,
            options: NSLinguisticTagger.Options(rawValue: 0), orthography: nil,  using:
            { (tag: String, tokenRange: NSRange, sentenceRange: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> () in
                let item : NSString = self.substring(with: tokenRange) as NSString;
                if tag == NSLinguisticTagOtherWhitespace {
                    // Copy over any whitespace.
                    if result.length > 0 {
                        result.append(item as String);
                    }
                } else {
                    // Not a whitespace. See if that is a known word.
                    // TODO: needs localization.
                    var key = item.stringWithNormalizedGermanChars().lowercased;
                    key = key.replacingOccurrences(of: "'", with: "");
                    let predicate = NSPredicate(format: "wordKey = '\(key)'");
                    request.predicate = predicate;
                    do {
                        let mappings = try context?.fetch(request);
                        if ((mappings?.count)! > 0) {
                            let mapping = mappings?[0] as! WordMapping;
                            let word: NSString = mapping.translated as NSString;

                            // If the original word contains lower case characters then it was probably
                            // already in true case. We only use the lookup then for replacing diacritics/sharp-s.
                            if item.rangeOfCharacter(from: CharacterSet.lowercaseLetters).length > 0 {
                                result.append(item.substring(to: 1));
                                result.append(word.substring(from: 1));
                            } else {
                                // Make the first letter upper case if it is the first entry.
                                // Don't touch the other letters, though!
                                if result.length == 0 {
                                    let firstLetter: NSString = word.substring(to: 1) as NSString;
                                    result.append(firstLetter.capitalized);
                                    result.append(word.substring(from: 1));
                                } else {
                                    result.append(word as String);
                                }
                            }
                        } else {
                            result.append(item as String);
                        }
                    }
                    catch {
                        // Do nothing in case of an error. Should never happen, but just in case.
                    }
                }
            }
        );
        return result;
    }

    /**
    * Converts umlauts and ß in the receiver to a decomposed form.
    */
    public func stringWithNormalizedGermanChars() -> NSString {
        var result = self.decomposedStringWithCanonicalMapping;
        result = result.replacingOccurrences(of: "ß", with: "ss");
        return result.replacingOccurrences(of: "\u{0308}", with: "e") as NSString; // Combining diaresis.
    }
}
