/**
 * Copyright (c) 2015, Pecunia Project. All rights reserved.
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

// Helper script with various functions to aid plugin debugging.

// Returns all elements in the current context up to the given nesting level.
function getElementNames(maxRecursion) { // Max recursion depth.
  var result = [];

  function enumerate(name, o, depth) {
    result.push(name + " type: '" + typeof o + "' value: " + o);

    if (depth >= maxRecursion)
      return;

    for (var c in o) {
      enumerate(name + "." + c, o[c], depth + 1);
    }
  }

  var doc = webView.document;
  for (var element in doc) {
    enumerate(element, doc[element], 0);
  }

  return result;
}

// Returns all "top level" function names in the current context.
// Functions defined with no explicit owner (like this one here) are considered top level
// functions and can be found on the defaultView object.
function getFunctionNames() {
	return [];
  var result = [];

  var view = document["defaultView"];
  if (view == null)
    return result;

  for (var element in view) {
    if (typeof view[element] == 'function') {
      Logger.logVerbose(name);
      result.push(element);
    }
  }

  return result;
}
