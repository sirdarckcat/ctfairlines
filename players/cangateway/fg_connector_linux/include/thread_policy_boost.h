#ifndef THREAD_POLICY_BOOST_H
#define THREAD_POLICY_BOOST_H

#include <boost/thread.hpp>

class BoostThreaded {
public:
    typedef boost::mutex Mutex;
    typedef boost::mutex::scoped_lock ScopedLock;
    typedef boost::condition_variable WaitCondition;
    void wait(ScopedLock& lock) { condition_.wait(lock); }
    void notify() { condition_.notify_one(); }
    Mutex mutex_;
    WaitCondition condition_;
};

#endif // THREAD_POLICY_BOOST_H
