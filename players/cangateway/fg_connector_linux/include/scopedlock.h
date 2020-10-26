// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef SCOPEDLOCK_H
#define SCOPEDLOCK_H

#ifdef USE_BOOST_MUTEX
    #include <boost/thread.hpp>
    typedef boost::mutex Mutex;
    #define LOCK(x1) (boost::mutex::scoped_lock(x1))
#elif USE_QMUTEX
    #include <QMutexLocker>
    typedef QMutex Mutex;
    #define LOCK(x1) (QMutexLocker(&x1))
#else
    #error No Mutex declaration defined
#endif

#endif // SCOPEDLOCK_H
