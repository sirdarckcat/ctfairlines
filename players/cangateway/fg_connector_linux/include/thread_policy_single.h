#ifndef THREAD_POLICY_SINGLE_H
#define THREAD_POLICY_SINGLE_H

class SingleThreaded {
public:
    typedef void* Mutex;
    typedef void* ScopedLock;
    void wait(ScopedLock&) {}
    void notify() {}
    Mutex mutex_;
};

#endif // THREAD_POLICY_SINGLE_H
