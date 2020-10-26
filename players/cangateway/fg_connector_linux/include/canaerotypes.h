// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

/** @mainpage

    libcanaero, a C++ library to access CAN Aerospace over UDP

    @section intro INTRODUCTION

    This library allows an easy, reliable and fast access to CAN aerospace
    over network.
    It uses UDP multicast to feed multiple clients with flight
    data from a variety of flight simulators. Currently Laminar Research X-Plane (R)
    and Microsoft Flight Simulator (R) are supported.


    @section features FEATURES

    - runs on Linux, Mac OS X and Windows
    - no end-user configuration required
    - simulator data is normalized to the SI system
    - applications using libcanaero are agnostic of which
      simulator is providing data
    - strongly typed data access

    @section prerequisites PREREQUISITES

    @subsection LINUX Linux
    Make sure you have gcc 4.5 installed. It is most likely already part of your distribution, or available as a distribution package.

    -# The Boost threading library version 1.45 is required.\n
    To get it, go to https://sourceforge.net/projects/boost/files/boost/1.45.0/
    -# Unpack boost to your home folder
    -# Open a terminal, navigate to the boost folder and execute
    @code ./bootstrap.sh @endcode
    -# Then execute
    @code sudo ./bjam install -q --layout=system --with-system --with-thread toolset=gcc variant=release link=static threading=multi @endcode
    This will place the boost libraries in /usr/local/lib and the
    boost headers in /usr/local/include
    -# You may now delete the folder where you unpacked boost.

    @subsection MAC Mac OS X

    -# Install the developer tools from your OS X DVD.
    -# Users of 10.6 Snow Leopard skip to step 4
    -# The 10.5 developer tools ship with gcc versions 4.01 and 4.2.1. Unfortunately 4.0.1 is set as default, which isn't very mature.
    So we set 4.2.1 as the default compiler:
    @code
    cd /usr/bin
    sudo rm cc gcc c++ g++
    ln -s gcc-4.2 cc
    ln -s gcc-4.2 gcc
    ln -s c++-4.2 c++
    ln -s g++-4.2 g++
    cd
    @endcode
    As usual sudo requires the password of your administrator account. \n\n
    -# The Boost threading library version 1.45 is required.\n
    To get it, go to https://sourceforge.net/projects/boost/files/boost/1.45.0/
    -# Unpack boost to your home folder
    -# Open a terminal, navigate to the boost folder and execute
    @code ./bootstrap.sh @endcode
    Ignore the Unicode/ICU support for Boost.Regex?... not found message.
    -# Then execute
    @code sudo ./bjam install -q --layout=system --with-system --with-thread toolset=darwin variant=release link=static threading=multi architecture=combined @endcode
    This will place the boost libraries in /usr/local/lib and the
    boost headers in /usr/local/include
    -# You may now delete the folder where you unpacked boost.


    @subsection WINDOWS Windows

    -# Get the gcc 4.4 compiler bundled with the Qt SDK 2010.05. Download it from
    ftp://ftp.qt.nokia.com/qtsdk/qt-sdk-win-opensource-2010.05.exe
    -# Install it with all options to default, by just clicking "Continue".
    -# The Boost threading library version 1.45 is required. \n
    To get it, go to https://sourceforge.net/projects/boost/files/boost/1.45.0/
    -# Unpack boost to your home directory
    -# Open Start->Programs->Qt SDK by Nokia v2010.05 (open source)->Qt Command Prompt
    Note that it won't work with the default commandline window, since the environment variables must be set to match the compiler. The Shortcut placed in the Qt SDK folder of the start menu does this conveniently.
    -# In this command window, navigate into the extracted boost folder
    -# run @code bootstrap.bat @endcode
    -# run the following command:
    @code bjam.exe install -q --layout=system --with-system --with-thread toolset=gcc variant=release link=static threading=multi @endcode
    This will place the boost libraries in C:\\Boost\\lib and the
    boost headers in C:\\Boost\\include
    -# You may now delete the folder where you unpacked boost.

    @subsection Other OTHER

    Most platforms offer additional compiler environments than those listed above.
    In order to guarantee success with SCS on all platforms, using the above compiler environments is mandatory.

    @section usage USAGE SUMMARY

    -#  Include receiver.h and import the namespace SCS.
    -#  Include ids.h to have a convenient access to all available IDs (data offered by SCS).
    -#  Create a @link SCS::Receiver @endlink instance.
    -#  Inform the receiver instance which data you want to receive from or
        send to the network.
    -#  Call @link SCS::Receiver::run @endlink from your application's main loop.
    -#  For more advanced usage, like publishing your own data or exposing modules
        to configuration services, you can create a class inheriting from Receiver.
    -#  To do so, familiarize yourself with the @link SCS::Receiver @endlink class.
    -#  Use one of the supplied Makefiles to build the application

    @section example EXAMPLE

    See the examples directory for the annotated "hello-scs" example that shows the basic concept.
    To compile it, use the supplied Makefiles.
    
    @subsection Windows
    - to use the makefile, open the Qt SDK command prompt Start->Programs->Qt SDK by Nokia v2010.05 (open source)->Qt Command Prompt
    - invoke the makefile with the command @code mingw32-make -f Makefile.Win @endcode
    
    @subsection Mac
    - invoke the makefile with the command @code make -f Makefile.Mac @endcode
    
    @subsection Linux
    - invoke the makefile with the command @code make -f Makefile.Linux @endcode

    @section notes NOTES

    - For accessing Microsoft Flight Simulator (R), FSUIPC by Pete Dowson is required.
    - Detailed specification of CAN Aerospace can be found at http://stockflightsystems.com


    @section licence LICENSE

    Copyright (C) 2008-2010 by Philipp Münzel. All rights reserved.

    You are hereby granted the right to include an unmodified copy of libcanaero
    in binary form into your open- or closed-source, commercially or
    non-commercially licensed application.

    Modifying your copy of libcanaero in any way is prohibited.
    Although some parts of libcanaero's source code (.h-files) are published,
    you are not allowed to modify these parts and/or create new binary distributions
    of libcanaero.

    THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
    ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
    OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
    HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
    OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
    SUCH DAMAGE.

*/

#ifndef CANAEROTYPES_H
#define CANAEROTYPES_H

#include "dllexport.h"
#include <string>

#ifdef HAVE_TR1
#include <tr1/cstdint>
#else
#include <stdint.h>
#endif

//! @file canaerotypes.h

//! Number of payload bytes CAN 2.0A and 2.0B are able to transport.
#define CAN2AB_PAYLOAD 8

namespace SCS {

//! @brief Union combining CAN Aerospace message data types.
//!
//! This union holds all possible data that can be transmitted in the bytes
//! 4-7 of a CAN Aerospace message.
//! Binary data types will be handled through their unsigned variants.
union DLL_PUBLIC canAS_Data_t {
    float       flt;        //!< float according to IEEE
    uint32_t    uLong;      //!< Unsigned 32 bit integer.
    int32_t     sLong;      //!< Signed 32 bit integer.
    uint16_t    uShort[2];  //!< 2 x unsigned 16 bit integer.
    int16_t     sShort[2];  //!< 2 x signed 16 bit integer.
    uint8_t     uChar[4];   //!< 4 x unsigned 8 bit integer.
    int8_t      sChar[4];   //!< 4 x signed 8 bit integer.
    char        aChar[4];   //!< 4 x unsigned ASCII character.
};


//! @brief Struct combining CAN Aerospace message header and message data.
//!
//! This struct holds bytes 0-7 of a CAN Aerospace message.
struct DLL_PUBLIC canAS_t {
    uint8_t         nodeId;         //!< Id of transmitting/receiving node.
    uint8_t         dataType;       //!< Id for CAN Aerospace message data type.
    uint8_t         serviceCode;    //!< Service code, see CAN Aerospace specification.
    uint8_t         messageCode;    //!< Message code, see CAN Aerospace specification.
    canAS_Data_t    data;           //!< CAN Aerospace message data.
};


//! @brief Union combining raw CAN payload data and CAN Aerospace message.
//!
//! The 8 payload bytes of a CAN message can either be accessed
//! as raw bytes or as a CAN Aerospace message.
union DLL_PUBLIC can_Data_t {
    uint8_t     byte[CAN2AB_PAYLOAD];   //!< Raw CAN message.
    canAS_t     aero;                   //!< CAN Aerospace message.
};

//! @brief Identifier is in 11 bit or 29bit format
//!
//! Refer to chapter 1 of SCS documentation
enum AS_IDwidth {
    BIT11 = 0,
    BIT29 = 1
};


//! @brief Convenience wrapper for CAN ID with highest bit code to tell 11/29 bit apart
//!
//! Offers a convenient function to log CAN IDs with according length information.
struct DLL_PUBLIC can_Id_t {
    can_Id_t();
    can_Id_t(uint32_t unflagged_id, AS_IDwidth width);
    AS_IDwidth idWidth() const;
    uint32_t id() const;
    std::string toString() const;
    bool operator<(const can_Id_t& rhs) const;
    uint32_t id_;
};

//! @brief These structs hold all IDs available from SCS.
//!
//! They return the canID in correct bit width and specify the type of dat transmitted.
template <typename T, uint32_t id, AS_IDwidth width>
struct DLL_PUBLIC scs_Id_t {
    typedef T Type;                                     //!< The type of the data you receive from SCS
    static can_Id_t Id() {return can_Id_t(id, width);}  //!< The CAN Id for which you query SCS
};


//! @brief CAN message as transmitted over the network.
//!
//! A CAN message for transmission consists of a CAN Id in either 11 or 29 bit format,
//! data length code and payload.
struct DLL_PUBLIC can_t {
    can_Id_t    id;         //!< CAN id, used for both 11 and 29 bit ids with id29 being flagged within the most significant bit
    can_Data_t  msg;        //!< CAN message data bytes.
    uint8_t     byte_count; //!< Data length code aka number of data bytes.
};


//! @brief The header types as specified by the CAN aerospace 1.7 standard.
//!
//! We comply to this header type.
//! Used in IDS Node Service, header type in byte 3
enum AS_HeaderTypes {
    AS_Standard = 0
};


//! @brief The identifier distribution as specified by the flightpanels SCS specification
//!
//! Used in IDS Node Service, identifier distribution in byte 2
enum AS_Identifier_Distribution {
    Distribution_Standard = 0,      //!< standard 1.7 distribution
    Distribution_Flightpanels = 100 //!< flightpanels.com distribution 100 for user-defined distribution sheme
};


//! @brief The revision of identifier distribution as specified by the flightpanels SCS
//!
//! Used in IDS Node Service, software revision in byte 1
enum AS_Identifier_Distribution_Revision {
    Identifier_Distribution_Revision_This_Release = 1
};


//! @brief Reserved node ids
//!
//! These node ids are already assigned in the distribution. They may NOT be used
//! by any application or hardware device
enum AS_NodeIds{
    BROADCAST_NODE_ID = 0,
    SCS_NODE_ID = 1,
    VASFMC_NODE_ID = 2
};


//! @brief Node service request codes
//!
//! These are the services that SCS undestands. Refer to chapter 4 of SCS documentation
enum AS_NodeService {
    IDS = 0,    //!< Identify plugin software revision and id distribution
    NSS = 1,    //!< Synchronize with X-Planes clock time
    // DDS and DUS not implemented in plugin
    // SCS n.a.
    // TIS supersed by TIS29
    // FLASH n.a.
    STS = 7,    //!< Transmit all messages once
    // FSS n.a.
    // TCS n.a.
    // BSS n.a.
    // NIS superseded by NCS
    MIS = 12,   //!< Which modules of SCS are available? Stratmann, Kiwi, whatever ...
    MCS = 13,   //!< Engage certain functionality, e.g. Stratmann or Hager AP
    // CIS n.a.

    // User defined range starts here
    DRS = 100,  //!< Request data to be transmitted regularly
    TIS29=101,  //!< Transmission interval service for extended identifiers
    NCS = 102   //!< Dynamic node id configuration service
};


//! @brief Data types as specified in CANaerospace 1.7
//!
//! Refer to chapter 3 of SCS documentation
enum AS_Type {
    AS_NODATA   = 0,
    AS_ERROR    = 1,
    AS_FLOAT    = 2,
    AS_LONG     = 3,
    AS_ULONG    = 4,
    AS_BLONG    = 5,
    AS_SHORT    = 6,
    AS_USHORT   = 7,
    AS_BSHORT   = 8,
    AS_CHAR     = 9,
    AS_UCHAR    = 10,
    AS_BCHAR    = 11,
    AS_SHORT2   = 12,
    AS_USHORT2  = 13,
    AS_BSHORT2  = 14,
    AS_CHAR4    = 15,
    AS_UCHAR4   = 16,
    // Left out some types that are not needed at the moment
    AS_ACHAR    = 23,
    AS_ACHAR2   = 24,
    AS_ACHAR4   = 25,
    // user defined (FP = flightpanels) type of sending 5 ascii charachters (4 in message, 1 in servie code)
    FP_ACHAR5   = 100,
    FP_VFLOAT   = 101,
    FP_VLONG    = 102
};


//! @brief 4 characters holding a time or date, according to CAN Aerospace 1.7
//!
//! @see Identifier distribution ID 1200 for UTC time and ID 1206 for UTC date
union char4{
    int32_t i;                  //!< integer value (only used internally)
    int8_t  c[4];               //!< for bytes according to ID 1200 or 1206 specification
    char4():i(0){};
    char4(int init):i(init){};
    std::string toString();
};

}

#endif // CANAEROTYPES_H
