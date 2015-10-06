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

// Contains JS exports for most of the WebKit classes to allow using them in Javascript.
// For now no CSS rule or style sheet declaration is exported.

import WebKit

@objc protocol DOMNodeListJSExport: JSExport {
    var length: UInt32 { get };
    func item(index: UInt32) -> DOMNode!;
}

extension DOMNodeList: DOMNodeListJSExport {
}

// For now we don't export CSS rules + stylesheets. Hence there are no declarations for DOMCSSRule
// and DOMCSSValue.
//
// Keep in mind that JS doesn't have named parameters hence calls to WebKit methods with more than one
// parameter have to include the parameter names in camel-case form in the function call name.
// Example:
//     func createNodeIterator(root: DOMNode!, whatToShow: UInt32, filter: DOMNodeFilter!, expandEntityReferences: Bool)...
// Javascript name
//      createNodeIteratorRootWhatToShowFilterExpandEntityReferences(...);
@objc protocol DOMCSSStyleDeclarationJSExport : JSExport {
    var cssText: String! { get set };
    var length: UInt32 { get };
    var parentRule: DOMCSSRule! { get };

    func getPropertyValue(propertyName: String!) -> String!;
    func getPropertyCSSValue(propertyName: String!) -> DOMCSSValue!;
    func removeProperty(propertyName: String!) -> String!;
    func getPropertyPriority(propertyName: String!) -> String!;
    func setProperty(propertyName: String!, value: String!, priority: String!);
    func item(index: UInt32) -> String!;

    func isPropertyImplicit(propertyName: String!) -> Bool;
}

extension DOMCSSStyleDeclaration : DOMCSSStyleDeclarationJSExport {
}

@objc protocol DOMCSSRuleListJSExport : JSExport {
    var length: UInt32 { get };

    func item(index: UInt32) -> DOMCSSRule!;
}

extension DOMCSSRuleList : DOMCSSRuleListJSExport {
}

@objc protocol DOMNamedNodeMapJSExport : JSExport {
    var length: UInt32 { get };

    func getNamedItem(name: String!) -> DOMNode!;
    func setNamedItem(node: DOMNode!) -> DOMNode!;
    func removeNamedItem(name: String!) -> DOMNode!;
    func item(index: UInt32) -> DOMNode!;
    func getNamedItemNS(namespaceURI: String!, localName: String!) -> DOMNode!;
    func setNamedItemNS(node: DOMNode!) -> DOMNode!;
    func removeNamedItemNS(namespaceURI: String!, localName: String!) -> DOMNode!;
}

extension DOMNamedNodeMap : DOMNamedNodeMapJSExport {
}

@objc protocol DOMNodeJSExport : JSExport {
    var nodeName: String! { get };
    var nodeValue: String! { get set };
    var nodeType: UInt16 { get };
    var parentNode: DOMNode! { get };
    var childNodes: DOMNodeList! { get };
    var firstChild: DOMNode! { get };
    var lastChild: DOMNode! { get };
    var previousSibling: DOMNode! { get };
    var nextSibling: DOMNode! { get };
    var ownerDocument: DOMDocument! { get };
    var namespaceURI: String! { get };
    var prefix: String! { get set };
    var localName: String! { get };
    var attributes: DOMNamedNodeMap! { get };
    var baseURI: String! { get };
    var textContent: String! { get set };
    var parentElement: DOMElement! { get };
    var isContentEditable: Bool { get };

    func insertBefore(newChild: DOMNode!, refChild: DOMNode!) -> DOMNode!;
    func replaceChild(newChild: DOMNode!, oldChild: DOMNode!) -> DOMNode!;
    func removeChild(oldChild: DOMNode!) -> DOMNode!;
    func appendChild(newChild: DOMNode!) -> DOMNode!;
    func hasChildNodes() -> Bool;
    func cloneNode(deep: Bool) -> DOMNode!;
    func normalize();
    func isSupported(feature: String!, version: String!) -> Bool;
    func hasAttributes() -> Bool;
    func isSameNode(other: DOMNode!) -> Bool;
    func isEqualNode(other: DOMNode!) -> Bool;
    func lookupPrefix(namespaceURI: String!) -> String!;
    func isDefaultNamespace(namespaceURI: String!) -> Bool;
    func lookupNamespaceURI(prefix: String!) -> String!;
    func compareDocumentPosition(other: DOMNode!) -> UInt16;
    func contains(other: DOMNode!) -> Bool;
}

extension DOMNode: DOMNodeJSExport {
}

@objc protocol DOMAttrJSExport : JSExport {
    var name: String! { get };
    var specified: Bool { get };

    var ownerElement: DOMElement! { get };
    var style: DOMCSSStyleDeclaration! { get };
    var value: String! { get };
}

extension DOMAttr : DOMAttrJSExport {
}

@objc protocol DOMElementJSExport : JSExport {
    var tagName: String! { get };
    var style: DOMCSSStyleDeclaration! { get };
    var offsetLeft: Int32 { get };
    var offsetTop: Int32 { get };
    var offsetWidth: Int32 { get };
    var offsetHeight: Int32 { get };
    var clientLeft: Int32 { get };
    var clientTop: Int32 { get };
    var clientWidth: Int32 { get };
    var clientHeight: Int32 { get };
    var scrollLeft: Int32 { get set };
    var scrollTop: Int32 { get set };
    var scrollWidth: Int32 { get };
    var scrollHeight: Int32 { get };
    var offsetParent: DOMElement! { get };
    var className: String! { get set };
    var firstElementChild: DOMElement! { get };
    var lastElementChild: DOMElement! { get };
    var previousElementSibling: DOMElement! { get };
    var nextElementSibling: DOMElement! { get };
    var childElementCount: UInt32 { get };
    var innerText: String! { get };

    func getAttribute(name: String!) -> String!;
    func setAttribute(name: String!, value: String!);
    func removeAttribute(name: String!);
    func getAttributeNode(name: String!) -> DOMAttr!;
    func setAttributeNode(newAttr: DOMAttr!) -> DOMAttr!;
    func removeAttributeNode(oldAttr: DOMAttr!) -> DOMAttr!;
    func getElementsByTagName(name: String!) -> DOMNodeList!;
    func getAttributeNS(namespaceURI: String!, localName: String!) -> String!;
    func setAttributeNS(namespaceURI: String!, qualifiedName: String!, value: String!);
    func removeAttributeNS(namespaceURI: String!, localName: String!);
    func getElementsByTagNameNS(namespaceURI: String!, localName: String!) -> DOMNodeList!;
    func getAttributeNodeNS(namespaceURI: String!, localName: String!) -> DOMAttr!;
    func setAttributeNodeNS(newAttr: DOMAttr!) -> DOMAttr!;
    func hasAttribute(name: String!) -> Bool;
    func hasAttributeNS(namespaceURI: String!, localName: String!) -> Bool;
    func focus();
    func blur();
    func scrollIntoView(alignWithTop: Bool);
    func scrollIntoViewIfNeeded(centerIfNeeded: Bool);
    func scrollByLines(lines: Int32);
    func scrollByPages(pages: Int32);
    func getElementsByClassName(name: String!) -> DOMNodeList!;
    func querySelector(selectors: String!) -> DOMElement!;
    func querySelectorAll(selectors: String!) -> DOMNodeList!;
    func webkitRequestFullScreen(flags: UInt16);
}

extension DOMElement : DOMElementJSExport {
}

@objc protocol DOMHTMLCollectionJSExport : JSExport {
    var length: UInt32 { get };

    func item(index: UInt32) -> DOMNode!;
    func namedItem(name: String!) -> DOMNode!;
    func tags(name: String!) -> DOMNodeList!;
}

extension DOMHTMLCollection : DOMHTMLCollectionJSExport {
}

@objc protocol DOMHTMLElementJExport : JSExport {
    var idName: String! { get set };
    var title: String! { get set };
    var lang: String! { get set };
    var dir: String! { get set };
    var tabIndex: Int32 { get set };
    var accessKey: String! { get set };
    var innerHTML: String! { get set };
    var innerText: String! { get set };
    var outerHTML: String! { get set };
    var outerText: String! { get set };
    var children: DOMHTMLCollection! { get };
    var contentEditable: String! { get set };
    var isContentEditable: Bool { get };
    var titleDisplayString: String! { get };

    func click();
}

extension DOMHTMLElement : DOMHTMLElementJExport {
}

@objc protocol DOMHTMLInputElementJSExport : JSExport {
    var accept: String! { get set };
    var alt: String! { get set };
    var autofocus: Bool { get set };
    var defaultChecked: Bool { get set };
    var checked: Bool { get set };
    var disabled: Bool { get set };
    var form: DOMHTMLFormElement! { get };
    var files: DOMFileList! { get set };
    var indeterminate: Bool { get set };
    var maxLength: Int32 { get set };
    var multiple: Bool { get set };
    var name: String! { get set };
    var readOnly: Bool { get set };
    var size: String! { get set };
    var src: String! { get set };
    var type: String! { get set };
    var defaultValue: String! { get set };

    var willValidate: Bool { get };
    var selectionStart: Int32 { get set };
    var selectionEnd: Int32 { get set };
    var align: String! { get set };
    var useMap: String! { get set };

    var altDisplayString: String! { get };
    var absoluteImageURL: NSURL! { get };

    func select();
    func setSelectionRange(start: Int32, end: Int32);
    func click();
    var value: String! { get set };
}

extension DOMHTMLInputElement : DOMHTMLInputElementJSExport {
}

@objc protocol DOMHTMLButtonElementJSExport : JSExport {
    var autofocus: Bool { get set };
    var disabled: Bool { get set };
    var form: DOMHTMLFormElement! { get };
    var name: String! { get set };
    var type: String! { get set };

    var willValidate: Bool { get };

    func click();
    var value: String! { get set };
}

extension DOMHTMLButtonElement : DOMHTMLButtonElementJSExport {
}

@objc protocol DOMHTMLAnchorElementJSExport : JSExport {
    var charset: String! { get set };
    var coords: String! { get set };
    var href: String! { get set };
    var hreflang: String! { get set };
    var name: String! { get set };
    var rel: String! { get set };
    var rev: String! { get set };
    var shape: String! { get set };
    var target: String! { get set };
    var type: String! { get set };

    var hashName: String! { get };
    var host: String! { get };
    var hostname: String! { get };
    var pathname: String! { get };
    var port: String! { get };
    var `protocol`: String! { get };
    var search: String! { get };
    var text: String! { get };
    var absoluteLinkURL: NSURL! { get };
}

extension DOMHTMLAnchorElement : DOMHTMLAnchorElementJSExport {
}

@objc protocol DOMHTMLOptionElementJSExport : JSExport {
    var disabled: Bool { get set };
    var form: DOMHTMLFormElement! { get }
    var label: String! { get set };
    var defaultSelected: Bool { get set };
    var selected: Bool { get set };

    var text: String! { get };
    var index: Int32 { get };

    var value: String! { get set };
}

extension DOMHTMLOptionElement : DOMHTMLOptionElementJSExport {
}

@objc protocol DOMHTMLOptionsCollectionJSExport : JSExport {
    var selectedIndex: Int32 { get set };
    var length: UInt32 { get set };

    func namedItem(name: String!) -> DOMNode!;
    func add(option: DOMHTMLOptionElement!, index: UInt32);
    func remove(index: UInt32);
    func item(index: UInt32) -> DOMNode!;
}

extension DOMHTMLOptionsCollection : DOMHTMLOptionsCollectionJSExport {
}

@objc protocol DOMHTMLSelectElementJSExport : JSExport {
    var autofocus: Bool { get set };
    var disabled: Bool { get set };
    var form: DOMHTMLFormElement! { get };
    var multiple: Bool { get set };
    var name: String! { get set };
    var size: Int32 { get set };
    var type: String! { get };
    var options: DOMHTMLOptionsCollection! { get };
    var length: Int32 { get };
    var selectedIndex: Int32 { get set };

    var willValidate: Bool { get };

    func item(index: UInt32) -> DOMNode!;
    func namedItem(name: String!) -> DOMNode!;
    func add(element: DOMHTMLElement!, before: DOMHTMLElement!);
    func remove(index: Int32);
    var value: String! { get set };
}

extension DOMHTMLSelectElement : DOMHTMLSelectElementJSExport {

}

@objc protocol DOMHTMLFormElementJSExport : JSExport {
    var acceptCharset: String! { get set };
    var action: String! { get set };
    var enctype: String! { get set };
    var encoding: String! { get set };
    var method: String! { get set };
    var name: String! { get set };
    var target: String! { get set };
    var elements: DOMHTMLCollection! { get };
    var length: Int32 { get };

    func submit();
    func reset();
}

extension DOMHTMLFormElement : DOMHTMLFormElementJSExport {
}

@objc protocol DOMDocumentTypeJSExport : JSExport {
    var name: String! { get };
    var entities: DOMNamedNodeMap! { get };
    var notations: DOMNamedNodeMap! { get };
    var publicId: String! { get };
    var systemId: String! { get };
    var internalSubset: String! { get };
}

extension DOMDocumentType : DOMDocumentTypeJSExport {
}

@objc protocol DOMImplementationJSExport : JSExport {
    func hasFeature(feature: String!, version: String!) -> Bool;
    func createDocumentType(qualifiedName: String!, publicId: String!, systemId: String!) -> DOMDocumentType!;
    func createDocument(namespaceURI: String!, qualifiedName: String!, doctype: DOMDocumentType!) -> DOMDocument!;
    func createCSSStyleSheet(title: String!, media: String!) -> DOMCSSStyleSheet!;
    func createHTMLDocument(title: String!) -> DOMHTMLDocument!;
}

extension DOMImplementation : DOMImplementationJSExport {
}

@objc protocol DOMStyleSheetListJSExport : JSExport {
    var length: UInt32 { get };

    func item(index: UInt32) -> DOMStyleSheet!;
}

extension DOMStyleSheetList : DOMStyleSheetListJSExport {
}

@objc protocol DOMDocumentFragmentJSExport : JSExport {
}

extension DOMDocumentFragment : DOMDocumentFragmentJSExport {
}

@objc protocol DOMCharacterDataJSExport : JSExport {
    var data: String! { get };
    var length: UInt32 { get };

    func substringData(offset: UInt32, length: UInt32) -> String!;
    func appendData(data: String!);
    func insertData(offset: UInt32, data: String!);
    func deleteData(offset: UInt32, length: UInt32);
    func replaceData(offset: UInt32, length: UInt32, data: String!);
}

extension DOMCharacterData : DOMCharacterDataJSExport {
}

@objc protocol DOMTextJSExport : JSExport {
    var wholeText: String! { get };

    func splitText(offset: UInt32) -> DOMText!;
    func replaceWholeText(content: String!) -> DOMText!;
}

extension DOMText : DOMTextJSExport {
}

@objc protocol DOMCommentJSExport : JSExport {
}

extension DOMComment : DOMCommentJSExport {
}

@objc protocol DOMCDATASectionJSExport : JSExport {
}

extension DOMCDATASection : DOMCDATASectionJSExport {
}

@objc protocol DOMProcessingInstructionJSExport : JSExport {
    var target: String! { get };
    var sheet: DOMStyleSheet! { get };
}

extension DOMProcessingInstruction : DOMProcessingInstructionJSExport {
}

@objc protocol DOMEntityReferenceJSExport : JSExport {
}

extension DOMEntityReference : DOMEntityReferenceJSExport {
}

/* Gives linker errors atm. Looks like the XPath classes are not available in Swift.
@objc protocol DOMXPathExpressionJSExport : JSExport {
    func evaluate(contextNode: DOMNode!, type: UInt16, inResult: DOMXPathResult!) -> DOMXPathResult!;
}

extension DOMXPathExpression : DOMXPathExpressionJSExport {
}

@objc protocol DOMXPathResultJSExport : JSExport {
    var resultType: UInt16 { get };
    var numberValue: Double { get };
    var stringValue: String! { get };
    var booleanValue: Bool { get };
    var singleNodeValue: DOMNode! { get };
    var invalidIteratorState: Bool { get };
    var snapshotLength: UInt32 { get };

    func iterateNext() -> DOMNode!;
    func snapshotItem(index: UInt32) -> DOMNode!;
}

extension DOMXPathResult : DOMXPathResultJSExport {
}
*/

@objc protocol DOMDocumentJSExport : JSExport {
    var doctype: DOMDocumentType! { get };
    var implementation: DOMImplementation! { get };
    var documentElement: DOMElement! { get };
    var inputEncoding: String! { get };
    var xmlEncoding: String! { get };
    var xmlVersion: String! { get set };
    var xmlStandalone: Bool { get set };
    var documentURI: String! { get set };
    var defaultView: DOMAbstractView! { get };
    var styleSheets: DOMStyleSheetList! { get };
    var title: String! { get set };
    var referrer: String! { get };
    var domain: String! { get };
    var URL: String! { get };
    var cookie: String! { get set };
    var body: DOMHTMLElement! { get set };
    var images: DOMHTMLCollection! { get };
    var applets: DOMHTMLCollection! { get };
    var links: DOMHTMLCollection! { get };
    var forms: DOMHTMLCollection! { get };
    var anchors: DOMHTMLCollection! { get };
    var lastModified: String! { get };
    var charset: String! { get set };
    var defaultCharset: String! { get };
    var readyState: String! { get };
    var characterSet: String! { get };
    var preferredStylesheetSet: String! { get };
    var selectedStylesheetSet: String! { get };
    var activeElement: DOMElement! { get };

    func createElement(tagName: String!) -> DOMElement!;
    func createDocumentFragment() -> DOMDocumentFragment!;
    func createTextNode(data: String!) -> DOMText!;
    func createComment(data: String!) -> DOMComment!;
    func createCDATASection(data: String!) -> DOMCDATASection!;
    func createProcessingInstruction(target: String!, data: String!) -> DOMProcessingInstruction!;
    func createAttribute(name: String!) -> DOMAttr!;
    func createEntityReference(name: String!) -> DOMEntityReference!;
    func getElementsByTagName(tagname: String!) -> DOMNodeList!;
    func importNode(importedNode: DOMNode!, deep: Bool) -> DOMNode!;
    func createElementNS(namespaceURI: String!, qualifiedName: String!) -> DOMElement!;
    func createAttributeNS(namespaceURI: String!, qualifiedName: String!) -> DOMAttr!;
    func getElementsByTagNameNS(namespaceURI: String!, localName: String!) -> DOMNodeList!;
    func getElementById(elementId: String!) -> DOMElement!;
    func adoptNode(source: DOMNode!) -> DOMNode!;
    func createEvent(eventType: String!) -> DOMEvent!;
    func createRange() -> DOMRange!;
    func createNodeIterator(root: DOMNode!, whatToShow: UInt32, filter: DOMNodeFilter!, expandEntityReferences: Bool) -> DOMNodeIterator!;
    func createTreeWalker(root: DOMNode!, whatToShow: UInt32, filter: DOMNodeFilter!, expandEntityReferences: Bool) -> DOMTreeWalker!;
    func getOverrideStyle(element: DOMElement!, pseudoElement: String!) -> DOMCSSStyleDeclaration!;
    func createExpression(expression: String!, resolver: DOMXPathNSResolver!) -> DOMXPathExpression!;
    func createNSResolver(nodeResolver: DOMNode!) -> DOMXPathNSResolver!;
    func evaluate(expression: String!, contextNode: DOMNode!, resolver: DOMXPathNSResolver!, type: UInt16, inResult: DOMXPathResult!) -> DOMXPathResult!;
    func getElementsByName(elementName: String!) -> DOMNodeList!;
    func createCSSStyleDeclaration() -> DOMCSSStyleDeclaration!;
    func getComputedStyle(element: DOMElement!, pseudoElement: String!) -> DOMCSSStyleDeclaration!;
    func getMatchedCSSRules(element: DOMElement!, pseudoElement: String!) -> DOMCSSRuleList!;
    func getMatchedCSSRules(element: DOMElement!, pseudoElement: String!, authorOnly: Bool) -> DOMCSSRuleList!;
    func getElementsByClassName(tagname: String!) -> DOMNodeList!;
    func querySelector(selectors: String!) -> DOMElement!;
    func querySelectorAll(selectors: String!) -> DOMNodeList!;
}

extension DOMDocument : DOMDocumentJSExport {
}

@objc protocol WebFrameJSExport : JSExport {
    var name: String! { get };
    var webView: WebView! { get };
    var document: WebKit.DOMDocument! { get }; // Qualification needed here, as DOMDocument is both the var name and its type.
    var frameElement: DOMHTMLElement! { get };
    func stopLoading();
    func reload();
    func reloadFromOrigin();
    func findFrameNamed(name: String!) -> WebFrame!;
    var parentFrame: WebFrame! { get };
    var childFrames: [AnyObject]! { get };
}

extension WebFrame: WebFrameJSExport {
    var document: WebKit.DOMDocument! {
        get {
            return DOMDocument;
        }
    }
}

@objc protocol WebViewJSExport : JSExport {

    var URL: String { get set }; // Same as mainFrameURL below, just a nicer name.
    var callback: JSValue { get set };

    func resultsArrived(results: JSValue) -> Void;
    func reportError(account: String, _ message: String) -> Void;

    // for handling HTTP requests
    var httpRequestCallback: JSValue { get set };
    func fireRequest(request: JSValue) ->  Void;
    
    // WebView exports.
    static func canShowMIMEType(MIMEType: String!) -> Bool;
    static func canShowMIMETypeAsHTML(MIMEType: String!) -> Bool;
    static func MIMETypesShownAsHTML() -> [AnyObject]!;
    static func setMIMETypesShownAsHTML(MIMETypes: [AnyObject]!);
    static func URLFromPasteboard(pasteboard: NSPasteboard!) -> NSURL!;
    static func URLTitleFromPasteboard(pasteboard: NSPasteboard!) -> String!;
    static func registerURLSchemeAsLocal(scheme: String!);

    func close()

    var shouldCloseWithWindow: Bool { get set };
    var mainFrame: WebFrame! { get };
    var selectedFrame: WebFrame! { get };
    var backForwardList: WebBackForwardList! { get };

    func setMaintainsBackForwardList(flag: Bool);
    func goBack() -> Bool;
    func goForward() -> Bool;
    func goToBackForwardItem(item: WebHistoryItem!) -> Bool;

    var textSizeMultiplier: Float { get set };
    var applicationNameForUserAgent: String! { get set };
    var customUserAgent: String! { get set };
    
    func userAgentForURL(URL: NSURL!) -> String!;
    
    var supportsTextEncoding: Bool { get }
    var customTextEncodingName: String! { get set };
    var mediaStyle: String! { get set };
    
    func stringByEvaluatingJavaScriptFromString(script: String!) -> String!;
    func searchFor(string: String!, direction forward: Bool, caseSensitive caseFlag: Bool, wrap wrapFlag: Bool) -> Bool
    
    var groupName: String! { get set };
    var estimatedProgress: Double { get };
    var loading: Bool { @objc(isLoading) get }
    
    func elementAtPoint(point: NSPoint) -> [NSObject : AnyObject]!;
    
    var mainFrameURL: String! { get set };
    var mainFrameDocument: DOMDocument! { get };
    var mainFrameTitle: String! { get };
    var mainFrameIcon: NSImage! { get };
}

