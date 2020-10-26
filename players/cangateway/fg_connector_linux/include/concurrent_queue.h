#ifndef CONCURRENT_QUEUE_H
#define CONCURRENT_QUEUE_H

#include <queue>

template<typename Data, class ThreadingPolicy>
class concurrent_queue
{
public:
    void push(Data const& data)
    {
        {
            ScopedLock lock(tp.mutex_);
            the_queue.push(data);
        }
        tp.notify();
    }

    bool empty() const
    {
        ScopedLock lock(tp.mutex_);
        return the_queue.empty();
    }

    bool try_pop(Data& popped_value)
    {
        ScopedLock lock(tp.mutex_);
        if(the_queue.empty())
        {
            return false;
        }

        popped_value = the_queue.front();
        the_queue.pop();
        return true;
    }

    void wait_and_pop(Data& popped_value)
    {
        ScopedLock lock(tp.mutex_);
        while(the_queue.empty())
        {
            wait(tp.mutex_);
        }

        popped_value=the_queue.front();
        the_queue.pop();
    }
private:
    typedef typename ThreadingPolicy::ScopedLock ScopedLock;
    std::queue<Data> the_queue;
    ThreadingPolicy tp;
};

#endif // CONCURRENT_QUEUE_H
