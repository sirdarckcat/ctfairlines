// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef ASIOCONNECTOR_H
#define ASIOCONNECTOR_H

#include "dllexport.h"

#include <string>
#include <memory>
#include <boost/asio.hpp>
#include <boost/thread.hpp>

#include "canaerotypes.h"
#include "connector.h"
#include "udpsender.h"
#include "udpreceiver.h"

namespace SCS {

/**
  * @brief Implementation of the NetworkConnector for CAN Aerospace messages
  * using the UDPSender and UDPReceiver classes for asynchronous communication.
  *
  * Build on top of the boost::asio library using two threads for
  * asynchronous sending and receiving of UDP messages.
  *
  * @note This class is reentrant. There is no guarantee the receiver callback
  * will be called from the main thread. Receiving callbacks must be thread-safe.
  * @author (c) 2009,2010 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC ASIOConnector: public NetworkConnector<can_t>
{
public:
    /**
      * @param host_addr the multicast group to communicate with
      * @param incoming_port port for incoming messages
      * @param outgoing_port port for outgoing messages
      */
    ASIOConnector(const std::string& host_addr,
                  int incoming_port,
                  int outgoing_port);

    /**
      * Cancel all I/O operations, close sockets and join threads
      */
    ~ASIOConnector();

    /**
      * @note No ownership tranfer, the caller is responsible for cleaning up this instance
      * @param listener pointer to instance to be notified of arriving messages
      */
    void setListener(BusConnector<can_t>* listener);

    /**
      * @param msg pointer to data for sending
      * @param bytes sizeof data to send
      */
    void send(const void* msg, std::size_t bytes);


private:
    /**
      * run the service of the receiver thread
      */
    void runIService();

    /**
      * run the service of the sender thread
      */
    void runOService();

    /**
      * callback function that the receiver calls when new data arrives
      */
    void receive(void* msg, std::size_t bytes_recvd);

private:
    boost::asio::io_service m_o_service;
    boost::asio::io_service m_i_service;
    std::auto_ptr<UDPSender> m_sender;
    std::auto_ptr<UDPReceiver> m_receiver;
    std::auto_ptr<boost::asio::io_service::work> m_o_work;
    std::auto_ptr<boost::asio::io_service::work> m_i_work;
    boost::thread m_sender_thread;
    boost::thread m_receiver_thread;
    BusConnector<can_t>* m_connector;
};

}

#endif // ASIOCONNECTOR_H
