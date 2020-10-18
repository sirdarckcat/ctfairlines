// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef UDPRECEIVER_H
#define UDPRECEIVER_H

#include "dllexport.h"

#include <boost/asio.hpp>
#include <boost/bind.hpp>
#include <boost/function.hpp>

namespace SCS {

/**
  * @brief Receive UDP packets from IP address and port. The receiver is multicast aware.
  *
  * If the address provided belongs to the IP multicast range, the multicast group is
  * automatically joined, else it is handled as unicast.
  * @author (c) 2009 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC UDPReceiver
{
public:

    /**
      * Open a socket and listen asynchronously to incoming data.
      * @param function function to parse incoming data, takes a raw pointer to data and size in bytes
      * @param io_service a boost::asio::io_service to handle the asynchronous requests
      * @param address ip address struct
      * @param port port from which data is received
      */
    UDPReceiver(boost::function<void (void*, std::size_t)> function,
                boost::asio::io_service& io_service,
                const boost::asio::ip::address& address,
                short port);

    /**
      * Stop receiving data and close connection.
      */
    ~UDPReceiver();


private:

    typedef boost::asio::ip::udp::endpoint UDPEndpoint;
    typedef boost::asio::ip::udp::socket UDPSocket;

    /**
      * Handle result of the async receive.
      * @param error Which error occured during receiving
      * @param bytes_recvd number of bytes received
      */
    void handle_receive_from(const boost::system::error_code& error,
                             std::size_t bytes_recvd);

    UDPEndpoint m_endpoint;

    UDPSocket m_socket;

    enum { max_length = 1440 }; //!< 1440 bytes can be send via UDP without IP-fragmenting

    char data_[max_length];     //!< store received raw data in this buffer

    /**
      * function to be called to parse incoming data
      */
    boost::function<void (void*, std::size_t)> m_recv_fun;

    boost::asio::ip::address m_addr;

};

}

#endif // UDPRECEIVER_H
