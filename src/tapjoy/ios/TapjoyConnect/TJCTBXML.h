// ================================================================================================
//  TJCTBXML.h
//  Fast processing of XML files
//
// ================================================================================================
//  Created by Tom Bradley on 21/10/2009.
//  Version 1.4
//  
//  Copyright (c) 2009 Tom Bradley
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
// ================================================================================================

#import <Foundation/Foundation.h>

// ================================================================================================
//  Defines
// ================================================================================================
#define TJC_MAX_ELEMENTS 100
#define TJC_MAX_ATTRIBUTES 100

#define TJC_TBXML_ATTRIBUTE_NAME_START 0
#define TJC_TBXML_ATTRIBUTE_NAME_END 1
#define TJC_TBXML_ATTRIBUTE_VALUE_START 2
#define TJC_TBXML_ATTRIBUTE_VALUE_END 3
#define TJC_TBXML_ATTRIBUTE_CDATA_END 4

// ================================================================================================
//  Structures
// ================================================================================================
/*!	\struct TJCTBXMLAttribute
 *	\brief The TJCTBXML attribute list node.
 *
 */
typedef struct TJCTBXMLAttribute 
{
	char * name;							/*!< The name of the XML attribute. */
	char * value;							/*!< The value of the XML attribute. */
	struct TJCTBXMLAttribute * next;			/*!< Pointer to the next #TJCTBXMLAttribute. */
} TJCTBXMLAttribute;

/*!	\struct TJCTBXMLElement
 *	\brief The TJCTBXML element list node.
 *
 */
typedef struct TJCTBXMLElement
{
	char * name;							/*!< The name of the XML Element. */
	char * text;							/*!< The text associated with the XML Element. */
	TJCTBXMLAttribute * firstAttribute;		/*!< Pointer to the first #TJCTBXMLAttribute node in this element. */
	struct TJCTBXMLElement * parentElement;	/*!< Pointer to the parent #TJCTBXMLElement of this element. */
	struct TJCTBXMLElement * firstChild;		/*!< Pointer to the first child #TJCTBXMLElement of this element. */
	struct TJCTBXMLElement * currentChild;		/*!< Pointer to the current chile #TJCTBXMLElement of this element. */
	struct TJCTBXMLElement * nextSibling;		/*!< Pointer to the next sibling #TJCTBXMLElement of this element. */
	struct TJCTBXMLElement * previousSibling;	/*!< Pointer to the previous sibling #TJCTBXMLElement of this element. */
} TJCTBXMLElement;

/*!	\struct TJCTBXMLElementBuffer
 *	\brief The TJCTBXML element buffer.
 *
 */
typedef struct TJCTBXMLElementBuffer
{
	TJCTBXMLElement * elements;				/*!< The current TJCTBXMLElement. */
	struct TJCTBXMLElementBuffer * next;		/*!< Pointer to the next TJCTBXMLElementBuffer. */
	struct TJCTBXMLElementBuffer * previous;	/*!< Pointer to the previous TJCTBXMLElementBuffer. */
} TJCTBXMLElementBuffer;

/*!	\struct TJCTBXMLAttributeBuffer
 *	\brief The TJCTBXML attribute buffer.
 *
 */
typedef struct TJCTBXMLAttributeBuffer 
{
	TJCTBXMLAttribute * attributes;			/*!< The current TJCTBXMLAttribute. */
	struct TJCTBXMLAttributeBuffer * next;		/*!< Pointer to the next TJCTBXMLAttributeBuffer. */
	struct TJCTBXMLAttributeBuffer * previous;	/*!< Pointer to the previous TJCTBXMLAttributeBuffer. */
} TJCTBXMLAttributeBuffer;

/*!	\interface TJCTBXML
 *	\brief The Tapjoy Connect TJCTBXML public interface.
 *
 */
@interface TJCTBXML : NSObject 
{
	
@private
	TJCTBXMLElement * rootXMLElement;					/*!< The TJCTBXML XML root element that is set when one of the initialize functions are invoked. */
	TJCTBXMLElementBuffer * currentElementBuffer;		/*!< Points to a #TJCTBXMLElementBuffer in the #TJCTBXMLElement linked list. */
	TJCTBXMLAttributeBuffer * currentAttributeBuffer;	/*!< Points to a #TJCTBXMLAttributeBuffer in the #TJCTBXMLElement linked list. */
	long currentElement;							/*!< The index into the #TJCTBXMLElement linked list of #currentElementBuffer. */
	long currentAttribute;							/*!< The index into the #TJCTBXMLElement linked list of #currentAttributeBuffer. */
	char * bytes;									/*!< Holds encoded XML data. */
	long bytesLength;								/*!< Size of the encoded XML data in bytes. */
}

@property (nonatomic, readonly) TJCTBXMLElement * rootXMLElement;


/*!	\fn tbxmlWithURL:(NSURL*)aURL
 *	\brief Returns a #TJCTBXML object with the given NSURL.
 *  
 * This method allocates a TJCTBXML object that is return after the XML data is decoded.
 *	\param aURL The NSURL to initialize the #TJCTBXML object with.
 *  \return A #TJCTBXML object.
 */
+ (id)tbxmlWithURL:(NSURL*)aURL;

/*!	\fn tbxmlWithXMLString:(NSString*)aXMLString
 *	\brief Returns a #TJCTBXML object with the given NSString.
 *  
 * This method allocates a TJCTBXML object that is return after the XML data is decoded.
 *	\param aXMLString The NSString that refers to an NSURL that is used to initialize the #TJCTBXML object with.
 *  \return A #TJCTBXML object.
 */
+ (id)tbxmlWithXMLString:(NSString*)aXMLString;

/*!	\fn tbxmlWithXMLData:(NSData*)aData
 *	\brief Returns a #TJCTBXML object with the given NSData.
 *  
 * The NSData contains the XML data that is then decoded and stored within the #TJCTBXML object.
 * This method allocates a TJCTBXML object that is return after the XML data is decoded.
 *	\param aData The NSData that contains XML data that is used to initialize the #TJCTBXML object with.
 *  \return A #TJCTBXML object.
 */
+ (id)tbxmlWithXMLData:(NSData*)aData;

/*!	\fn initWithURL:(NSURL*)aURL
 *	\brief Returns a #TJCTBXML object with the given NSURL.
 *  
 * The NSURL points to an XML file that is then decoded and stored within the #TJCTBXML object.
 *	\param aURL The NSURL to initialize the #TJCTBXML object with.
 *  \return A #TJCTBXML object.
 */
- (id)initWithURL:(NSURL*)aURL;

/*!	\fn initWithXMLString:(NSString*)aXMLString
 *	\brief Returns a #TJCTBXML object with the given NSString.
 *  
 * The NSString refers to an NSURL which points to an XML file that is then decoded and stored within the #TJCTBXML object.
 *	\param aXMLString The NSString that refers to an NSURL that is used to initialize the #TJCTBXML object with.
 *  \return A #TJCTBXML object.
 */
- (id)initWithXMLString:(NSString*)aXMLString;

/*!	\fn initWithXMLData:(NSData*)aData
 *	\brief Returns a #TJCTBXML object with the given NSData.
 *  
 * The NSData contains the XML data that is then decoded and stored within the #TJCTBXML object.
 *	\param aData The NSData that contains XML data that is used to initialize the #TJCTBXML object with.
 *  \return A #TJCTBXML object.
 */
- (id)initWithXMLData:(NSData*)aData;

@end

// ================================================================================================
//  TJCTBXML Static Functions Interface
// ================================================================================================

/*!	\category TJCTBXML(StaticFunctions)
 *	\brief The Tapjoy Connect TJCTBXML static functions category.
 *
 */
@interface TJCTBXML(StaticFunctions)

/*!	\fn elementName:(TJCTBXMLElement*)aXMLElement
 *	\brief Returns the element name of the given #TJCTBXMLElement.
 *  
 *	\param aXMLElement The #TJCTBXMLElement from which to retrieve the name from.
 *  \return An NSString containing the name of the given #TJCTBXMLElement.
 */
+ (NSString*) elementName:(TJCTBXMLElement*)aXMLElement;

/*!	\fn textForElement:(TJCTBXMLElement*)aXMLElement
 *	\brief Returns the element text of the given #TJCTBXMLElement.
 *  
 *	\param aXMLElement The #TJCTBXMLElement from which to retrieve the text from.
 *  \return An NSString containing the text of the given #TJCTBXMLElement.
 */
+ (NSString*) textForElement:(TJCTBXMLElement*)aXMLElement;

/*!	\fn numberForElement:(TJCTBXMLElement*)aXMLElement
 *	\brief Returns the element integer value of the given #TJCTBXMLElement.
 *  
 *	\param aXMLElement The #TJCTBXMLElement from which to retrieve the integer value from.
 *  \return An integer value of the given #TJCTBXMLElement. Returns 0 if no integer value exists.
 */
+ (int)	numberForElement:(TJCTBXMLElement*)aXMLElement;

/*!	\fn boolForElement:(TJCTBXMLElement*)aXMLElement
 *	\brief Returns the element boolean value of the given #TJCTBXMLElement.
 *  
 *	\param aXMLElement The #TJCTBXMLElement from which to retrieve the boolean value from.
 *  \return An boolean value of the given #TJCTBXMLElement.
 */
+ (BOOL) boolForElement:(TJCTBXMLElement*)aXMLElement;

/*!	\fn negativeNumberForUnknownElement:(TJCTBXMLElement*)aXMLElement
 *	\brief Returns the element integer value of the given #TJCTBXMLElement.
 *  
 * This is similar to #numberForElement except -1 is returned instead of 0 when no integer value exists.
 *	\param aXMLElement The #TJCTBXMLElement from which to retrieve the integer value from.
 *  \return An integer value of the given #TJCTBXMLElement. Returns -1 if no integer value exists.
 */
+ (int) negativeNumberForUnknownElement:(TJCTBXMLElement*)aXMLElement;

/*!	\fn valueOfAttributeNamed:forElement:(NSString* aName, TJCTBXMLElement* aXMLElement)
 *	\brief Returns the value of the attribute that matches the given #TBXMLElement's attribute name.
 *  
 * The first matching attribute with the same given name in the given #TJCTBXMLElement attribute list is returned.
 *	\param aName The name to search for in the given #TBXMLElement's attribute list.
 *	\param aXMLElement The attribute list is contained within this #TJCTBXMLElement.
 *  \return An NSString containing the value of the attribute. If no matching attribute is found, the NSString is nil.
 */
+ (NSString*) valueOfAttributeNamed:(NSString *)aName forElement:(TJCTBXMLElement*)aXMLElement;

/*!	\fn attributeName:(TJCTBXMLAttribute*)aXMLAttribute
 *	\brief Returns the attribute name of the given #TJCTBXMLAttribute.
 *  
 *	\param aXMLAttribute The #TJCTBXMLAttribute from which to retrieve the name from.
 *  \return An NSString containing the name of the given #TJCTBXMLAttribute.
 */
+ (NSString*) attributeName:(TJCTBXMLAttribute*)aXMLAttribute;

/*!	\fn attributeValue:(TJCTBXMLAttribute*)aXMLAttribute
 *	\brief Returns the attribute value of the given #TJCTBXMLAttribute.
 *  
 *	\param aXMLAttribute The #TJCTBXMLAttribute from which to retrieve the value from.
 *  \return An NSString containing the value of the given #TJCTBXMLAttribute.
 */
+ (NSString*) attributeValue:(TJCTBXMLAttribute*)aXMLAttribute;

/*!	\fn nextSiblingNamed:searchFromElement:(NSString* aName, TJCTBXMLElement* aXMLElement)
 *	\brief Returns the next sibling of the given #TJCTBXMLElement that contains a matching name with the given name.
 *  
 * The first matching next sibling of the given #TJCTBXMLElement is returned.
 *	\param aName The name to search for in the given #TBXMLElement's sibling list.
 *	\param aXMLElement The sibling list is contained within this #TJCTBXMLElement.
 *  \return A #TJCTBXMLElement that contains the matching name to the given name. If no matching #TJCTBXMLElement is found, nil is returned.
 */
+ (TJCTBXMLElement*) nextSiblingNamed:(NSString*)aName searchFromElement:(TJCTBXMLElement*)aXMLElement;

/*!	\fn childElementNamed:parentElement:(NSString* aName, TJCTBXMLElement* aParentXMLElement)
 *	\brief Returns the child of the given #TJCTBXMLElement that contains a matching name with the given name.
 *  
 * The first matching child of the given #TJCTBXMLElement is returned.
 *	\param aName The name to search for in the given #TBXMLElement's child list.
 *	\param aParentXMLElement The child list is contained within this #TJCTBXMLElement.
 *  \return A #TJCTBXMLElement that contains the matching name to the given name. If no matching #TJCTBXMLElement is found, nil is returned.
 */
+ (TJCTBXMLElement*) childElementNamed:(NSString*)aName parentElement:(TJCTBXMLElement*)aParentXMLElement;

@end
