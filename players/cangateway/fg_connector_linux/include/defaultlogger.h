#ifndef DEFAULTLOGGER_H
#define DEFAULTLOGGER_H

#include <boost/noncopyable.hpp>
#include "logwriter.h"

namespace SCS {

class Singleton : private boost::noncopyable {
public:
    static LogWriter& getLogger();
    static void setLogger(LogWriter*);

private:
    Singleton();
    static LogWriter* writer_;
};

}

#endif // DEFAULTLOGGER_H
