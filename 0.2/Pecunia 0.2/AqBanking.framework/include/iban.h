/**-*-c++-*-****************************************************************
                             -------------------
    cvs         : $Id$
    begin       : Tue Apr 19 2005
    copyright   : (C) 2005 by Andreas Degert (some parts Gerhard Gappmeier)
    email       : ad@papyrus-gmbh.de

    based on the older version from Gerhard Gappmeier
    (gerhard.gappmeier@ascolab.com)

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

#ifndef IBAN_H
#define IBAN_H

/** @file 
 * @brief Checking of International Bank Account Numbers (IBAN)
 *
 * This file contains the classes and C wrappers for IBAN checking.
 */

#ifdef __cplusplus

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <map>
#include <ctype.h>

/** @brief Stores one IBAN (International Bank Account Number)
 *
 * Stores an IBAN (International Bank Account Number) and produces
 * the electronic format (transmission format) and the printable
 * format (paper format) according to the ECBS document TR 201.
 */
class Iban
{
public:

  /** Constructor for an empty Iban. */
  Iban();

  /** Copy constructor. */
  Iban(const Iban& iban);

  /** Constructor from a string.
   * @param iban IBAN string
   * @param normalize when true (the default), @a iban will be
   *        normalized to transmission format; when false, @a iban
   *        must be in transmission format already.
   *
   * normalization consists of deleting all white space, converting
   * lowercase letters to uppercase, and deleting a prefix of the form
   * "IBAN".
   */
  Iban(const std::string& iban, bool normalize = true);

  /** Default destructor. */
  ~Iban();

  /** Returns the transmission format for the IBAN */
  const std::string& transmissionForm() const {
    return m_transmission;
  }

  /** Returns the printable format for the IBAN */
  const std::string& printableForm() {
    if (m_printable.empty()) 
      m_printable = createPrintable();
    return m_printable;
  }

private:
  std::string m_transmission; ///< stored electronic format
  std::string m_printable;    ///< stored paper format

  /** create the electronic format */
  static std::string createTransmission(const std::string& iban_str);
  /** create the paper format */
  std::string createPrintable() const;
};

/** @brief IBAN bank information database and IBAN verification
 *
 * Stores a mapping of IBAN-prefixes to required length of the IBAN
 * and BIC (Bank Identification Code) position inside the IBAN, and a
 * second mapping of the ISO 3166 2-character country code to the list
 * of prefixes for that country (usually one, identically to the
 * country code).
 *
 * The mappings are read from a file when an instance of the class is
 * created.
 */
class IbanCheck {
public:

  /** Code returned by check() (and also by bic_position()). */
  enum Result {
    // do not change anything here without changing
    // the initialisation of m_ResultText!
    OK = 0,            ///< IBAN is formally correct (length and checksum)
    TOO_SHORT,         ///< IBAN is too short to even check
    PREFIX_NOT_FOUND,  ///< the 2-character IBAN prefix is unknown
    WRONG_LENGTH,      ///< IBAN has the wrong length
    COUNTRY_NOT_FOUND, ///< the country code to check against is unknown
    WRONG_COUNTRY,     ///< the IBAN doesn't belong to the country
    BAD_CHECKSUM,      ///< Bad IBAN checksum, i.e. the IBAN probably contains a typo
  };


  /** Constructor that initalizes the mappings from a data file at
   * @a filename.
   *
   * If the file name argument is empty, then the compile-time
   * datafile will be used. On Windows, the location of the datafile
   * will be looked up in the registry.
   *
   * If the file could not be found or is not successfully read, the
   * mappings will be empty. Use error() to check for such an error
   * condition.
   *
   * @param filename If empty, then the compile-time file name will be
   * used. Otherwise the relative or absolute full filename of the
   * data file
   */
  IbanCheck(const std::string& filename = "");

  /** Default destructor */
  ~IbanCheck();

  /** Check the formal correctness of a given iban.  This function
   * checks if the prefix is known, if the length is correct for the
   * prefix, if the checksum is ok and if the prefix is valid for a
   * given country (if set).
   *
   * @param iban     Iban instance
   * @param country  2-character country code (ISO 3166)
   */
  Result check(const Iban& iban, const std::string& country = "") const {
    return check(iban.transmissionForm(), country); }

  /** @overload
   * @param iban     IBAN in transmission format
   * @param country  2-character country code (ISO 3166)
   */
  Result check(const std::string& iban, const std::string& country = "") const;

  /** Returns the position of the BIC inside the IBAN. The iban should
   * be formally correct, if not an error Result might be returned.
   *
   * @param iban   [in] IBAN in transmission format
   * @param start  [out] start of BIC (0-based index)
   * @param end    [out] first position after BIC (0-based index)
   */
  Result bic_position(const std::string& iban, int& start, int& end) const;

  /** Convert Result code into an english message string.
   *
   * @note if the value of @a res is an integer not inside
   * the enum range, a special message will be returned.
   *
   * @param res   Result code from check() or bic_position()
   */
  static const char *resultText(Result res);

  /** @return false if the data file could not be opened and
   * successfully read.
   */
  bool error() const { return m_IbanSpec.size() == 0; }

  /** uses the example data to test the check routines.
   * @return false if not successful
   */
  bool selftest();

private:

  static const char *m_ResultText[];

  typedef std::vector<std::string> svector;

  struct Spec {
    std::string prefix;
    unsigned int length;
    unsigned int bic_start, bic_end;
    std::string example;
  };

  typedef std::map<std::string,Spec*> specmap;

  struct Country {
    std::string country;
    svector prefixes;
  };

  typedef std::map<std::string, Country*> countrymap;

  friend std::istream& operator>>(std::istream &is, Spec &spec);
  friend std::istream& operator>>(std::istream &is, Country &c);

  bool readSpecTable(std::istream &fin, const std::string& stopcomment);
  bool readCountryTable(std::istream &fin);
  static int to_number(char c) { return c - 'A' + 10; }
  static std::string iban2number(const std::string& iban);
  static int modulo97(const std::string& number);

  specmap m_IbanSpec;
  countrymap m_CountryMap;
};

typedef IbanCheck::Result IbanCheck_Result;
extern "C" {
#else /* __cplusplus */
  typedef struct IbanCheck IbanCheck;
  typedef struct Iban Iban;
  typedef int IbanCheck_Result;
#endif /* __cplusplus */
  /** @name IbanCheck methods */
  /* @{ */

  /** Constructor that initalizes the mappings from a data file at
   * @a filename.
   *
   * If the file name argument is empty, then the compile-time
   * datafile will be used. On Windows, the location of the datafile
   * will be looked up in the registry.
   *
   * If the file could not be found or is not successfully read, the
   * mappings will be empty. Use error() to check for such an error
   * condition.
   *
   * @param filename If empty, then the compile-time file name will be
   * used. Otherwise the relative or absolute full filename of the
   * data file
   */
  IbanCheck *IbanCheck_new(const char *filename);
  /** Default destructor */
  void IbanCheck_free(IbanCheck *p);
  /** @overload
   * @param p        IbanCheck object
   * @param iban     IBAN in transmission format
   * @param country  2-character country code (ISO 3166)
   */
  IbanCheck_Result IbanCheck_check_str(const IbanCheck *p,
					      const char *iban,
					      const char *country);
  /** Check the formal correctness of a given iban.  This function
   * checks if the prefix is known, if the length is correct for the
   * prefix, if the checksum is ok and if the prefix is valid for a
   * given country (if set).
   *
   * @param p        IbanCheck object
   * @param iban     Iban instance
   * @param country  2-character country code (ISO 3166)
   */
  IbanCheck_Result IbanCheck_check_iban(const IbanCheck *p,
					       const Iban *iban,
					       const char *country);
  /** Returns the position of the BIC inside the IBAN. The iban should
   * be formally correct, if not an error Result might be returned.
   *
   * @param p        IbanCheck object
   * @param iban    [in] IBAN in transmission format
   * @param start  [out] start of BIC (0-based index)
   * @param end    [out] first position after BIC (0-based index)
   */
  IbanCheck_Result IbanCheck_bic_position(const IbanCheck *p, 
						 const char *iban,
						 int *start, int *end);
  /** Convert Result code into an english message string.
   *
   * @note if the value of @a res is an integer not inside
   * the enum range, a special message will be returned.
   *
   * @param res   Result code from check() or bic_position()
   */
  const char *IbanCheck_resultText(IbanCheck_Result res);
  /** @return false if the data file could not be opened and
   * successfully read.
   */
  int IbanCheck_error(const IbanCheck *p);
  /** uses the example data to test the check routines.
   * @return false if not successful
   */
  int IbanCheck_selftest(IbanCheck *p);
  /* @} */

  /** @name Iban methods */
  /* @{ */
  /** Constructor from a string */
  Iban *Iban_new(const char* iban, int normalize);
  /** Default destructor. */
  void Iban_free(Iban *p);
  /** Returns the transmission format for the IBAN */
  const char *Iban_transmissionForm(const Iban *iban);
  /** Returns the printable format for the IBAN */
  const char *Iban_printableForm(Iban *iban);
  /* @} */
#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* IBAN_H */
