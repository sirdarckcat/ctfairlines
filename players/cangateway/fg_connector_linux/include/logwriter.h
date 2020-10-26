// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef LOGWRITER_H
#define LOGWRITER_H

#include "dllexport.h"

#include "log.h"
#if defined USE_QMUTEX
#include "thread_policy_qt.h"
#define ThreadingPolicy QThreaded
#elif defined USE_BOOST_MUTEX
#include "thread_policy_boost.h"
#define ThreadingPolicy BoostThreaded
#endif
#include "concurrent_queue.h"


namespace SCS {

/**
  * @brief Thread-safe logger that can write log messages to console, file, etc..
  *
  * By default, this is implemented by ConsoleLogger. If you want to log
  * to a file or GUI instead, override the LogWriter::writeString function.
  * @author (c) 2009,2010 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC LogWriter
{
public:
    virtual ~LogWriter() {}

    /**
      * Post a log entry to the log queue.
      * Can be called from any thread.
      */
    void postEntry(const LogEntry& entry);

    /**
      * Write all entries from the queue by calling LogWriter::writeSring for each one.
      * Should be called from the thread where it is safe to write to logfile, console, etc..
      */
    void writeEntries();

    /**
      * Write an entry from the queue to the actual logger
      */
    virtual void writeString(const LogEntry&) = 0;

private:
    concurrent_queue<SCS::LogEntry, ThreadingPolicy> m_queue;
};

}

#endif // LOGWRITER_H
