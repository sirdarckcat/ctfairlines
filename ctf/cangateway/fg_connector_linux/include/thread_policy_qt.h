#ifndef THREAD_POLICY_QT_H
#define THREAD_POLICY_QT_H

#include <QMutexLocker>
#include <QWaitCondition>

class QThreaded {
public:
    typedef QMutex Mutex;
    typedef QMutexLocker ScopedLock;
    typedef QWaitCondition WaitCondition;
    void wait(ScopedLock&) { condition_.wait(mutex_); }
    void notify() { condition_.wakeOne(); }
    QThreaded():mutex_(new QMutex) {};
    ~QThreaded() { delete mutex_; }
    Mutex* mutex_;
    WaitCondition condition_;
};

#endif // THREAD_POLICY_QT_H
