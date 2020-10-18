// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef CONNECTEDCLIENT_H
#define CONNECTEDCLIENT_H

#include "dllexport.h"

#ifdef HAVE_TR1
#include <tr1/cstdint>
#else
#include <stdint.h>
#endif
#include <boost/date_time.hpp>

namespace SCS {

/**
  * @brief Clients on the CAN bus that have identfied themselves with an IDS are stored in this format.
  *
  * They are identified by their node id. If they remain silent,
  * they are dropped after a timeout. This class is used for internal housekeeping
  * of CanAeroBusConnector.
  * @author (c) 2009, 2010 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC ConnectedClient
{
public:

    /**
      * Value is given in seconds.
      */
    static const float time_out;

    /**
      * @param node_id unique id on the CAN bus, either hard-wired or auto-assigned via NCS node service
      * @param hardware_revision for software nodes this is their software version number
      * @param software_revision for all nodes this is the config file revision number they require
      * @param identifier_distribution according to SCS or CAN Aerospace specification
      * @param header_type according to CAN Aerospace specification
      */
    ConnectedClient(uint8_t node_id, uint8_t hardware_revision, uint8_t software_revision,
        uint8_t identifier_distribution, uint8_t header_type);

    /**
      * Will be called to reset timeout after reception of data.
      */
    void resetTimer();

    /**
      * try to poke the node with an IDS to see if it is really gone or just normally silent.
      */
    void poke();

    /**
      * @return has the node already been poked
      */
    bool wasPoked() const;

    /**
      * @return True when client has been silent for longer than ConnectedClient::time_out seconds.
      */
    bool hasTimedOut() const;

    /**
      * @return Node id
      */
    uint8_t nodeId() const;

    /**
      * To be used as key in sets or maps, clients are sorted according to their node id.
      * The id remains const over the lifetime of an instance.
      */
    bool operator<(const ConnectedClient& rhs) const;

private:
    uint8_t m_node_id;
    uint8_t m_hardware_revision;
    uint8_t m_software_revision;
    uint8_t m_identifier_distribution;
    uint8_t m_header_type;
    bool m_poked;
    boost::posix_time::ptime m_last_heared_from;
};

}

#endif // CONNECTEDCLIENT_H
