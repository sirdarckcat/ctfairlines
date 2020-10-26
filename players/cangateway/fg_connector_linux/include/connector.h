// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef CONNECTOR_H
#define CONNECTOR_H

#include "dllexport.h"

#include <vector>

#include "canaerotypes.h"

namespace SCS {

/**
  * @brief Interface to high-level IO provider that knows the protocol format.
  * @author  (c) 2009, 2010 by Philipp Münzel
  * @version 1.3
  */
template <typename Packet>
class DLL_PUBLIC BusConnector
{
public:

    virtual ~BusConnector() {}

    /**
      * @note To be called synchronously
      * @param msg single packet to send
      */
    virtual void send(const Packet& msg) = 0;

    /**
      * @note To be called synchronously
      * @param msg array of packets to send
      */
    virtual void send(const std::vector<Packet>& msg) = 0;

    /**
      * @note To be called asynchronously.
      * @param msg single packet received
      */
    virtual void receiveMessage(const Packet& msg) = 0;

    /**
      * @note To be called asynchronously.
      * @param msg array of packets received
      */
    virtual void receiveMessage(const std::vector<Packet>& msg) = 0;
};

/**
  * @brief Interface to low-level IO provider for sending data and notification of a BusConnector
  * on reception of new data.
  * @author  (c) 2009, 2010 by Philipp Münzel
  * @version 1.3
  */
template <typename Packet>
class DLL_PUBLIC NetworkConnector{
public:

    virtual ~NetworkConnector() {}

    /**
      * @param connector pointer to an instance to be notified when new packets arrive
      */
    virtual void setListener(BusConnector<Packet>* connector) = 0;

    /**
      * @note To be called synchronously.
      * @param msg pointer to data to send
      * @param bytes sizeof data to send
      */
    virtual void send(const void* msg, std::size_t bytes) = 0;
};

}

#endif // CONNECTOR_H
