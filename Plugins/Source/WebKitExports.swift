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
    func item(_ index: UInt32) -> DOMNode!;
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

    func getPropertyValue(_ propertyName: String!) -> String!;
    func getPropertyCSSValue(_ propertyName: String!) -> DOMCSSValue!;
    func removeProperty(_ propertyName: String!) -> String!;
    func getPropertyPriority(_ propertyName: String!) -> String!;
    func setProperty(_ propertyName: String!, value: String!, priority: String!);
    func item(_ index: UInt32) -> String!;

    func isPropertyImplicit(_ propertyName: String!) -> Bool;
}

extension DOMCSSStyleDeclaration : DOMCSSStyleDeclarationJSExport {
}

@objc protocol DOMCSSRuleListJSExport : JSExport {
    var length: UInt32 { get };

    func item(_ index: UInt32) -> DOMCSSRule!;
}

extension DOMCSSRuleList : DOMCSSRuleListJSExport {
}

@objc protocol DOMNamedNodeMapJSExport : JSExport {
    var length: UInt32 { get };

    func getNamedItem(_ name: String!) -> DOMNode!;
    func setNamedItem(_ node: DOMNode!) -> DOMNode!;
    func removeNamedItem(_ name: String!) -> DOMNode!;
    func item(_ index: UInt32) -> DOMNode!;
    func getNamedItemNS(_ namespaceURI: String!, localName: String!) -> DOMNode!;
    func setNamedItemNS(_ node: DOMNode!) -> DOMNode!;
    func removeNamedItemNS(_ namespaceURI: String!, localName: String!) -> DOMNode!;
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

    func insertBefore(_ newChild: DOMNode!, refChild: DOMNode!) -> DOMNode!;
    func replaceChild(_ newChild: DOMNode!, oldChild: DOMNode!) -> DOMNode!;
    func removeChild(_ oldChild: DOMNode!) -> DOMNode!;
    func appendChild(_ newChild: DOMNode!) -> DOMNode!;
    func hasChildNodes() -> Bool;
    func cloneNode(_ deep: Bool) -> DOMNode!;
    func normalize();
    func isSupported(_ feature: String!, version: String!) -> Bool;
    func hasAttributes() -> Bool;
    func isSameNode(_ other: DOMNode!) -> Bool;
    func isEqualNode(_ other: DOMNode!) -> Bool;
    func lookupPrefix(_ namespaceURI: String!) -> String!;
    func isDefaultNamespace(_ namespaceURI: String!) -> Bool;
    func lookupNamespaceURI(_ prefix: String!) -> String!;
    func compareDocumentPosition(_ other: DOMNode!) -> UInt16;
    func contains(_ other: DOMNode!) -> Bool;
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

    func getAttribute(_ name: String!) -> String!;
    func setAttribute(_ name: String!, value: String!);
    func removeAttribute(_ name: String!);
    func getAttributeNode(_ name: String!) -> DOMAttr!;
    func setAttributeNode(_ newAttr: DOMAttr!) -> DOMAttr!;
    func removeAttributeNode(_ oldAttr: DOMAttr!) -> DOMAttr!;
    func getElementsByTagName(_ name: String!) -> DOMNodeList!;
    func getAttributeNS(_ namespaceURI: String!, localName: String!) -> String!;
    func setAttributeNS(_ namespaceURI: String!, qualifiedName: String!, value: String!);
    func removeAttributeNS(_ namespaceURI: String!, localName: String!);
    func getElementsByTagNameNS(_ namespaceURI: String!, localName: String!) -> DOMNodeList!;
    func getAttributeNodeNS(_ namespaceURI: String!, localName: String!) -> DOMAttr!;
    func setAttributeNodeNS(_ newAttr: DOMAttr!) -> DOMAttr!;
    func hasAttribute(_ name: String!) -> Bool;
    func hasAttributeNS(_ namespaceURI: String!, localName: String!) -> Bool;
    func focus();
    func blur();
    func scrollIntoView(_ alignWithTop: Bool);
    func scrollIntoViewIfNeeded(_ centerIfNeeded: Bool);
    func scrollByLines(_ lines: Int32);
    func scrollByPages(_ pages: Int32);
    func getElementsByClassName(_ name: String!) -> DOMNodeList!;
    func querySelector(_ selectors: String!) -> DOMElement!;
    func querySelectorAll(_ selectors: String!) -> DOMNodeList!;
    func webkitRequestFullScreen(_ flags: UInt16);
}

extension DOMElement : DOMElementJSExport {
}

@objc protocol DOMHTMLCollectionJSExport : JSExport {
    var length: UInt32 { get };

    func item(_ index: UInt32) -> DOMNode!;
    func namedItem(_ name: String!) -> DOMNode!;
    func tags(_ name: String!) -> DOMNodeList!;
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
    var absoluteImageURL: URL! { get };

    func select();
    func setSelectionRange(_ start: Int32, end: Int32);
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
    var absoluteLinkURL: URL! { get };
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

    func namedItem(_ name: String!) -> DOMNode!;
    func add(_ option: DOMHTMLOptionElement!, index: UInt32);
    func remove(_ index: UInt32);
    func item(_ index: UInt32) -> DOMNode!;
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

    func item(_ index: UInt32) -> DOMNode!;
    func namedItem(_ name: String!) -> DOMNode!;
    func add(_ element: DOMHTMLElement!, before: DOMHTMLElement!);
    func remove(_ index: Int32);
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
    func hasFeature(_ feature: String!, version: String!) -> Bool;
    func createDocumentType(_ qualifiedName: String!, publicId: String!, systemId: String!) -> DOMDocumentType!;
    func createDocument(_ namespaceURI: String!, qualifiedName: String!, doctype: DOMDocumentType!) -> DOMDocument!;
    func createCSSStyleSheet(_ title: String!, media: String!) -> DOMCSSStyleSheet!;
    func createHTMLDocument(_ title: String!) -> DOMHTMLDocument!;
}

extension DOMImplementation : DOMImplementationJSExport {
}

@objc protocol DOMStyleSheetListJSExport : JSExport {
    var length: UInt32 { get };

    func item(_ index: UInt32) -> DOMStyleSheet!;
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

    func substringData(_ offset: UInt32, length: UInt32) -> String!;
    func appendData(_ data: String!);
    func insertData(_ offset: UInt32, data: String!);
    func deleteData(_ offset: UInt32, length: UInt32);
    func replaceData(_ offset: UInt32, length: UInt32, data: String!);
}

extension DOMCharacterData : DOMCharacterDataJSExport {
}

@objc protocol DOMTextJSExport : JSExport {
    var wholeText: String! { get };

    func splitText(_ offset: UInt32) -> DOMText!;
    func replaceWholeText(_ content: String!) -> DOMText!;
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

@objc protocol DOMXPathExpressionJSExport : JSExport {
    func evaluate(_ contextNode: DOMNode!, type: UInt16, inResult: DOMXPathResult!) -> DOMXPathResult!;
}
/*
extension DOMXPathExpression : DOMXPathExpressionJSExport {
}
*/
@objc protocol DOMXPathResultJSExport : JSExport {
    var resultType: UInt16 { get };
    var numberValue: Double { get };
    var stringValue: String! { get };
    var booleanValue: Bool { get };
    var singleNodeValue: DOMNode! { get };
    var invalidIteratorState: Bool { get };
    var snapshotLength: UInt32 { get };

    func iterateNext() -> DOMNode!;
    func snapshotItem(_ index: UInt32) -> DOMNode!;
}
/*
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

    func createElement(_ tagName: String!) -> DOMElement!;
    func createDocumentFragment() -> DOMDocumentFragment!;
    func createTextNode(_ data: String!) -> DOMText!;
    func createComment(_ data: String!) -> DOMComment!;
    func createCDATASection(_ data: String!) -> DOMCDATASection!;
    func createProcessingInstruction(_ target: String!, data: String!) -> DOMProcessingInstruction!;
    func createAttribute(_ name: String!) -> DOMAttr!;
    func createEntityReference(_ name: String!) -> DOMEntityReference!;
    func getElementsByTagName(_ tagname: String!) -> DOMNodeList!;
    func importNode(_ importedNode: DOMNode!, deep: Bool) -> DOMNode!;
    func createElementNS(_ namespaceURI: String!, qualifiedName: String!) -> DOMElement!;
    func createAttributeNS(_ namespaceURI: String!, qualifiedName: String!) -> DOMAttr!;
    func getElementsByTagNameNS(_ namespaceURI: String!, localName: String!) -> DOMNodeList!;
    func getElementById(_ elementId: String!) -> DOMElement!;
    func adoptNode(_ source: DOMNode!) -> DOMNode!;
    func createEvent(_ eventType: String!) -> DOMEvent!;
    func createRange() -> DOMRange!;
    func createNodeIterator(_ root: DOMNode!, whatToShow: UInt32, filter: DOMNodeFilter!, expandEntityReferences: Bool) -> DOMNodeIterator!;
    func createTreeWalker(_ root: DOMNode!, whatToShow: UInt32, filter: DOMNodeFilter!, expandEntityReferences: Bool) -> DOMTreeWalker!;
    func getOverrideStyle(_ element: DOMElement!, pseudoElement: String!) -> DOMCSSStyleDeclaration!;
    func createExpression(_ expression: String!, resolver: DOMXPathNSResolver!) -> DOMXPathExpression!;
    func createNSResolver(_ nodeResolver: DOMNode!) -> DOMXPathNSResolver!;
    func evaluate(_ expression: String!, contextNode: DOMNode!, resolver: DOMXPathNSResolver!, type: UInt16, inResult: DOMXPathResult!) -> DOMXPathResult!;
    func getElementsByName(_ elementName: String!) -> DOMNodeList!;
    func createCSSStyleDeclaration() -> DOMCSSStyleDeclaration!;
    func getComputedStyle(_ element: DOMElement!, pseudoElement: String!) -> DOMCSSStyleDeclaration!;
    func getMatchedCSSRules(_ element: DOMElement!, pseudoElement: String!) -> DOMCSSRuleList!;
    func getMatchedCSSRules(_ element: DOMElement!, pseudoElement: String!, authorOnly: Bool) -> DOMCSSRuleList!;
    func getElementsByClassName(_ tagname: String!) -> DOMNodeList!;
    func querySelector(_ selectors: String!) -> DOMElement!;
    func querySelectorAll(_ selectors: String!) -> DOMNodeList!;
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
    func findFrameNamed(_ name: String!) -> WebFrame!;
    var parentFrame: WebFrame! { get };
    var childFrames: [Any]! { get };
}

extension WebFrame: WebFrameJSExport {
    var document: WebKit.DOMDocument! {
        get {
            return domDocument;
        }
    }
}

protocol WebViewJSExport : JSExport {

    var URL: String { get set }; // Same as mainFrameURL below, just a nicer name.
    var postURL: String { get set }; // if written it's an URL for POST requests otherwise the same as mainFrameURL
    var callback: JSValue { get set };

    func resultsArrived(_ results: JSValue) -> Void;
    func reportError(_ account: String, _ message: String) -> Void;
    
    // WebView exports.
    static func canShowMIMEType(_ MIMEType: String!) -> Bool;
    static func canShowMIMETypeAsHTML(_ MIMEType: String!) -> Bool;
    static func mimeTypesShownAsHTML() -> [Any]!;
    static func setMIMETypesShownAsHTML(_ MIMETypes: [Any]!);
    static func URLFromPasteboard(_ pasteboard: NSPasteboard!) -> Foundation.URL!;
    static func URLTitleFromPasteboard(_ pasteboard: NSPasteboard!) -> String!;
    static func registerURLSchemeAsLocal(_ scheme: String!);

    func close()

    var shouldCloseWithWindow: Bool { get set };
    var mainFrame: WebFrame! { get };
    var selectedFrame: WebFrame! { get };
    var backForwardList: WebBackForwardList! { get };

    func setMaintainsBackForwardList(_ flag: Bool);
    func goBack() -> Bool;
    func goForward() -> Bool;
    func goToBackForwardItem(_ item: WebHistoryItem!) -> Bool;

    var textSizeMultiplier: Float { get set };
    var applicationNameForUserAgent: String! { get set };
    var customUserAgent: String! { get set };
    
    func userAgentForURL(_ URL: Foundation.URL!) -> String!;
    
    var supportsTextEncoding: Bool { get }
    var customTextEncodingName: String! { get set };
    var mediaStyle: String! { get set };
    
    func stringByEvaluatingJavaScriptFromString(_ script: String!) -> String!;
    func searchFor(_ string: String!, direction forward: Bool, caseSensitive caseFlag: Bool, wrap wrapFlag: Bool) -> Bool
    
    var groupName: String! { get set };
    var estimatedProgress: Double { get };
//    var loading: Bool { @objc(isLoading) get }
    var loading: Bool { get }
    
    func elementAtPoint(_ point: NSPoint) -> [AnyHashable: Any]!;
    
    var mainFrameURL: String! { get set };
    var mainFrameDocument: DOMDocument! { get };
    var mainFrameTitle: String! { get };
    var mainFrameIcon: NSImage! { get };
}

