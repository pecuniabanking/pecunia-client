/***************************************************************************
 $RCSfile$
 -------------------
 cvs         : $Id$
 begin       : Sat Jun 28 2003
 copyright   : (C) 2003 by Martin Preuss
 email       : martin@libchipcard.de

 ***************************************************************************
 *                                                                         *
 *   This library is free software; you can redistribute it and/or         *
 *   modify it under the terms of the GNU Lesser General Public            *
 *   License as published by the Free Software Foundation; either          *
 *   version 2.1 of the License, or (at your option) any later version.    *
 *                                                                         *
 *   This library is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   Lesser General Public License for more details.                       *
 *                                                                         *
 *   You should have received a copy of the GNU Lesser General Public      *
 *   License along with this library; if not, write to the Free Software   *
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston,                 *
 *   MA  02111-1307  USA                                                   *
 *                                                                         *
 ***************************************************************************/



#ifndef GWENHYWFAR_TEXT_H
#define GWENHYWFAR_TEXT_H

#include <gwenhywfar/gwenhywfarapi.h>
#include <gwenhywfar/types.h>
#include <gwenhywfar/logger.h>
#include <gwenhywfar/buffer.h>
#include <stdio.h>


#ifdef __cplusplus
extern "C" {
#endif

#define GWEN_TEXT_FUZZY_SHIFT               10


#define GWEN_TEXT_FLAGS_DEL_LEADING_BLANKS  0x00000001
#define GWEN_TEXT_FLAGS_DEL_TRAILING_BLANKS 0x00000002
#define GWEN_TEXT_FLAGS_DEL_MULTIPLE_BLANKS 0x00000004
#define GWEN_TEXT_FLAGS_NEED_DELIMITER      0x00000008
#define GWEN_TEXT_FLAGS_NULL_IS_DELIMITER   0x00000010
#define GWEN_TEXT_FLAGS_DEL_QUOTES          0x00000020
#define GWEN_TEXT_FLAGS_CHECK_BACKSLASH     0x00000040


/**
 * This function cuts out a word from a given string.
 * @return address of the new word, 0 on error
 * @param src pointer to the beginning of the source string
 * @param delims pointer to a string containing all delimiters
 * @param buffer pointer to the destination buffer
 * @param maxsize length of the buffer. Actually up to this number of
 * characters are copied to the buffer. If after this number of chars no
 * delimiter follows the string will be terminated. You will have to check
 * whether there is a delimiter directly after the copied string
 * @param flags defines how the source string is to be processed
 * @param next pointer to a pointer to receive the address up to which the
 * source string has been handled. You can use this to continue with the
 * source string behind the word we've just cut out. This variable is only
 * modified upon successfull return
 */
GWENHYWFAR_API
char *GWEN_Text_GetWord(const char *src,
                        const char *delims,
                        char *buffer,
                        unsigned int maxsize,
                        uint32_t flags,
                        const char **next);

GWENHYWFAR_API
int GWEN_Text_GetWordToBuffer(const char *src,
                              const char *delims,
                              GWEN_BUFFER *buf,
                              uint32_t flags,
                              const char **next);


/**
 * This function does escaping like it is used for HTTP URL encoding.
 * All characters which are not alphanumeric are escaped by %XX where
 * XX ist the hexadecimal code of the character.
 */
GWENHYWFAR_API
char *GWEN_Text_Escape(const char *src,
                       char *buffer,
                       unsigned int maxsize);

GWENHYWFAR_API
char *GWEN_Text_Unescape(const char *src,
                         char *buffer,
                         unsigned int maxsize);

GWENHYWFAR_API
char *GWEN_Text_UnescapeN(const char *src,
			  unsigned int srclen,
                          char *buffer,
                          unsigned int maxsize);

GWENHYWFAR_API
char *GWEN_Text_EscapeTolerant(const char *src,
			       char *buffer,
			       unsigned int maxsize);

GWENHYWFAR_API
char *GWEN_Text_UnescapeTolerant(const char *src,
				 char *buffer,
				 unsigned int maxsize);

GWENHYWFAR_API
char *GWEN_Text_UnescapeTolerantN(const char *src,
				  unsigned int srclen,
				  char *buffer,
				  unsigned int maxsize);


GWENHYWFAR_API
int GWEN_Text_EscapeToBuffer(const char *src, GWEN_BUFFER *buf);

GWENHYWFAR_API
int GWEN_Text_UnescapeToBuffer(const char *src, GWEN_BUFFER *buf);

/**
 * Does the same as @ref GWEN_Text_EscapeToBuffer does, but this version
 * here does not escape some characters generally accepted within strings
 * (such as space, comma, decimal point etc).
 */
GWENHYWFAR_API
int GWEN_Text_EscapeToBufferTolerant(const char *src, GWEN_BUFFER *buf);

GWENHYWFAR_API
int GWEN_Text_EscapeToBufferTolerant2(GWEN_BUFFER *src, GWEN_BUFFER *buf);


/**
 * This function does the same as @ref GWEN_Text_UnescapeToBuffer but it
 * doesn't complain about unescaped characters in the source string.
 */
GWENHYWFAR_API
int GWEN_Text_UnescapeToBufferTolerant(const char *src, GWEN_BUFFER *buf);


GWENHYWFAR_API
char *GWEN_Text_ToHex(const char *src, unsigned l, char *buffer,
                      unsigned int maxsize);

/**
 * Writes the given binary data as a hex string to the destination buffer.
 * @param groupsize if !=0 then after this many characters in the destination
 *   buffer the delimiter is inserted
 * @param delimiter character to write after groupsize characters
 * @param skipLeadingZeroes if !=0 then leading zeroes are suppressed
 */
GWENHYWFAR_API
int GWEN_Text_ToHexBuffer(const char *src, unsigned l,
                          GWEN_BUFFER *buf,
                          unsigned int groupsize,
                          char delimiter,
                          int skipLeadingZeroes);

/**
 * Converts a string to Hex. After "groupsize" bytes the "delimiter" is
 * inserted.
 */
GWENHYWFAR_API
char *GWEN_Text_ToHexGrouped(const char *src,
                             unsigned l,
                             char *buffer,
                             unsigned maxsize,
                             unsigned int groupsize,
                             char delimiter,
                             int skipLeadingZeros);

GWENHYWFAR_API
int GWEN_Text_FromHex(const char *src, char *buffer, unsigned maxsize);

/**
 * Reads hex bytes and stores them in the given buffer.
 */
GWENHYWFAR_API
int GWEN_Text_FromHexBuffer(const char *src, GWEN_BUFFER *buf);


/**
 * Reads bcd bytes and stores them in the given buffer.
 */
GWENHYWFAR_API
int GWEN_Text_FromBcdBuffer(const char *src, GWEN_BUFFER *buf);


/**
 * Writes the given BCD data as a hex string to the destination buffer.
 * @param groupsize if !=0 then after this many characters in the destination
 *   buffer the delimiter is inserted
 * @param delimiter character to write after groupsize characters
 * @param skipLeadingZeroes if !=0 then leading zeroes are suppressed
 */
GWENHYWFAR_API
int GWEN_Text_ToBcdBuffer(const char *src, unsigned l,
                          GWEN_BUFFER *buf,
                          unsigned int groupsize,
                          char delimiter,
                          int skipLeadingZeroes);


/**
 * @return number of bytes in the buffer (-1 on error)
 * @param fillchar if 0 then no filling takes place, positive values
 * extend to the right, negative values to the left.
 */
GWENHYWFAR_API
int GWEN_Text_NumToString(int num, char *buffer, unsigned int bufsize,
                          int fillchar);

/**
 * This functions transforms a string into a double float value.
 * It always uses a comma (",") regardless of the current locale settings.
 * This makes sure that a value can always be parsed regardless of the
 * country settings of the producer of that string.
 */
GWENHYWFAR_API
int GWEN_Text_DoubleToBuffer(double num, GWEN_BUFFER *buf);

/**
 * This functions transforms a double float value into a string.
 * It always uses a comma (",") regardless of the current locale settings.
 * This makes sure that a value can always be parsed regardless of the
 * country settings of the producer of that string.
 */
GWENHYWFAR_API
int GWEN_Text_StringToDouble(const char *s, double *num);


/**
 * Compares two strings. If either of them is given but empty, that string
 * will be treaten as not given. This way a string NOT given equals a string
 * which is given but empty.
 * @param ign set to !=0 to ignore cases
 */
GWENHYWFAR_API
int GWEN_Text_Compare(const char *s1, const char *s2, int ign);


/**
 * This function compares two string and returns the number of matches or
 * -1 on error.
 * @param w string to compare
 * @param p pattern to compare against
 * @param sensecase if 0 then cases are ignored
 */
GWENHYWFAR_API
int GWEN_Text_ComparePattern(const char *w, const char *p, int sensecase);


/**
 * This is used for debugging purposes and it shows the given data as a
 * classical hexdump.
 */
GWENHYWFAR_API
void GWEN_Text_DumpString(const char *s, unsigned int l, FILE *f,
                          unsigned int insert);


GWENHYWFAR_API
void GWEN_Text_DumpString2Buffer(const char *s, unsigned int l,
                                 GWEN_BUFFER *mbuf,
                                 unsigned int insert);

GWENHYWFAR_API
void GWEN_Text_LogString(const char *s, unsigned int l,
                         const char *logDomain,
                         GWEN_LOGGER_LEVEL lv);


/**
 * Condenses a buffer containing chars.
 * This means removing unnecessary spaces.
 */
GWENHYWFAR_API
  void GWEN_Text_CondenseBuffer(GWEN_BUFFER *buf);


/**
 * This function counts the number of characters in the given UTF-8 buffer.
 * @param s pointer to a buffer which contains UTF-8 characters
 * @param len number of bytes (if 0 then all bytes up to a zero byte are
 *  counted)
 */
GWENHYWFAR_API
  int GWEN_Text_CountUtf8Chars(const char *s, int len);


/**
 * Replaces special characters which are used by XML (like "<", "&" etc)
 * by known sequences (like "&amp;").
 */
GWENHYWFAR_API
int GWEN_Text_EscapeXmlToBuffer(const char *src, GWEN_BUFFER *buf);

/**
 * Replaces special character sequences to their coresponding character.
 */
GWENHYWFAR_API
int GWEN_Text_UnescapeXmlToBuffer(const char *src, GWEN_BUFFER *buf);


/**
 * Compares two strings and returns the percentage of their equality.
 * It is calculated by this formula:
 *  matches*100 / ((length of s1)+(length of s2))
 * Each match is weight like this:
 *  <ul>
 *   <li>*s1==*s2: 2</li>
 *   <li>toupper(*s1)==toupper(*s2): 2 if ign, 1 otherwise</li>
 *   <li>isalnum(*s1)==isalnum(*s2): 1
 *  </ul>
 * @return percentage of equality between both strings
 * @param s1 1st of two strings to compare
 * @param s2 2nd of two strings to compare
 * @param ign if !=0 then the cases are ignored
 */
GWENHYWFAR_API
  double GWEN_Text_CheckSimilarity(const char *s1, const char *s2, int ign);



#ifdef __cplusplus
}
#endif


#endif



