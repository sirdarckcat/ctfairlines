// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef UDPSENDER_H
#define UDPSENDER_H

#include "dllexport.h"

#include <sstream>
#include <string>
#include <boost/asio.hpp>
#include <boost/bind.hpp>

namespace SCS {

/**
  * @brief Send UDP packets to given IP address and port. The sender is multicast aware
  *
  * @author (c) 2009-2010 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC UDPSender
{
public:

    /**
      * @param io_service boost::asio::io_service to handle the asynchronous requests
      * @param ip_address ip address struct
      * @param port port to which data is sent
      * @param disable_loopback disable loopback adapter, enabled by default
      */
    UDPSender(boost::asio::io_service& io_service,
              const boost::asio::ip::address& ip_address,
              short port,
              bool disable_loopback = false);

    /**
      * Cancel asynchronous writes and close socket.
      */
    ~UDPSender() {}

    /**
      * @param data arbitrary binary data to write
      * @param bytes number of bytes to write
      */
    void write(const void* data, size_t bytes);


private:

    typedef boost::asio::ip::udp::endpoint UDPEndpoint;
    typedef boost::asio::ip::udp::socket UDPSocket;

    /**
      * control result of async_send
      * @param correct_size how many bytes should have been written
      * @param error which error_code was set
      * @param bytes_written how many bytes were actually written
      */
    void handle_send_to(size_t correct_size,
                        const boost::system::error_code& error,
                        size_t bytes_written);

    void resetFallback(const boost::system::error_code& error);

    UDPEndpoint m_endpoint;

    UDPSocket m_socket;

    int m_multicast_port;

    bool m_fallback_loopback_active;

    int m_fallback_fail_counter;

    boost::asio::deadline_timer m_fallback_reset_timer;
};

}

#endif // UDPSENDER_H
