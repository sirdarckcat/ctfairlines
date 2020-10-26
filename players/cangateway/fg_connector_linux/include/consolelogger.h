#ifndef CONSOLELOGGER_H
#define CONSOLELOGGER_H

#include "logwriter.h"

/**
  * Writes to standard output, does an exit(EXIT_FAILURE) when failure message arrives
  */
class ConsoleLogger: public SCS::LogWriter
{
public:
    void writeString(const SCS::LogEntry& entry);
};

#endif // CONSOLELOGGER_H
