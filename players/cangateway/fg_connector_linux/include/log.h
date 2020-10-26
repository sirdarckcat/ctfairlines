// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef LOG_H
#define LOG_H

#include "dllexport.h"

#include <string>
#include <ctime>
#include <sstream>
#ifdef HAVE_TR1
#include <tr1/cstdint>
#else
#include <stdint.h>
#endif

namespace SCS {

class DLL_PUBLIC LogWriter;

enum Level {
    L_UNSPEC=-1,    //!< unspecified, occurs when no severity function pointer was called
    L_FAIL  = 0,    //!< Failure, forces quit of application
    L_ERROR = 1,    //!< Error, permits keeping the application running
    L_WARN  = 2,    //!< Warning
    L_INFO  = 3     //!< Information
};

/**
  * @brief Every log message that arises from libcanaero is in this format.
  */
struct DLL_PUBLIC LogEntry {
    Level lvl;          //!< Severity of the occured event, see enum
    std::string txt;    //!< Human-readable message
    time_t time;        //!< Timestamp
};


/**
  * @brief A stream-based logger using any LogWriter.
  * A Log instance corresponds to ONE log entry.
  *
  * Creating an instance provides the stream to which a log message is written.
  * Specifying severity level and Log::endl are mandatory.
  * @code Log() << Log::Error << "This is an error" << Log::endl;
  * Log() << Log::Info << "This is an information about " << some_integer << Log::endl @endcode
  * @author  (c) 2009,2010 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC Log {
public:
    /**
      * create a new Logstream for ONE new message
      */
    Log();

    /**
      * Indicate the following message has severity Information
      */
    static Log& Info(Log& log);

    /**
      * Indicate the following message has severity Warnining
      */
    static Log& Warn(Log& log);

    /**
      * Indicate the following message has severity Error
      */
    static Log& Error(Log& log);

    /**
      * Indicate the following message has severity Failure
      */
    static Log& Fail(Log& log);

    /**
      * Terminate the log stream. This is mandatory!
      */
    static Log& endl(Log& log);

    /**
      * Log an integer.
      * @param i
      */
    Log& operator<<(int i);

    /**
      * Log an unsigned 32 bit integer (CAN Id are stored in this format)
      * @param u32
      */
    Log& operator<<(uint32_t u32);

    /**
      * Log a float.
      * @param f
      */
    Log& operator<<(float f);

    /**
      * Log a double.
      * @param d
      */
    Log& operator<<(double d);

    /**
      * Log a char
      * @param c
      */
    Log& operator<<(char c);

    /**
      * Log a string.
      * @param s
      */
    Log& operator<<(const std::string& s);

    Log& operator<<(Log& (*f)(Log&));

private:
    Level m_severity;
    LogWriter& m_writer;
    std::ostringstream m_stream;
};
}

#endif // LOG_H
