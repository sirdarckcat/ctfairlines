// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef SCOPEDPARALLELEXECUTOR_H
#define SCOPEDPARALLELEXECUTOR_H

#include "dllexport.h"

#include <boost/thread.hpp>
#include <boost/function.hpp>
#include <boost/asio.hpp>

namespace SCS {

/**
  * @brief Easy way to execute an infinite loop in a separate thread
  * until the object goes out of scope.
  *
  * This class executes an inifinte loop and calls the provided
  * in every cycle. This all takes place in a separate thread. The processing
  * is stopped gracefully and the thread joined when the instance of this
  * class goes out of scope.
  *
  * @author (c) 2009,2010 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC ScopedParallelExecutor
{
public:
    ScopedParallelExecutor();

    /**
      * @param run_function Function to be called in every loop cycle
      * @param run_interval_ms Sleep time between function calls in milliseconds
      */
    ScopedParallelExecutor(boost::function<void()> run_function, long run_interval_ms);

    /**
      * Waits for next function call and breaks main loop after it, then joins the thread.
      */
    ~ScopedParallelExecutor();

    /**
      * @param run_function Function to be called in every cycle. Replaces the old function.
      */
    void setCallback(boost::function<void()> run_function);

    /**
      * @param milliseconds Sleep time between function calls in milliseconds
      */
    void setRunInterval(long milliseconds);

    /**
      * Platfrom-independant sleep function
      * @param seconds
      */
    static void delay(int seconds);

private:
    void runFunction();
    void runIOService();

private:
    boost::function<void()> m_run_function;
    long m_run_interval_ms;
    boost::asio::io_service m_io_service;
    std::auto_ptr<boost::asio::io_service::work> m_work;
    boost::thread m_thread;
    boost::asio::deadline_timer m_timer;
    bool m_stop;
};
}
#endif // SCOPEDPARALLELEXECUTOR_H
