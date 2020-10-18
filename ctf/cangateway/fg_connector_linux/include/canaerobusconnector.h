// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef CANAEROBUSCONNECTOR_H
#define CANAEROBUSCONNECTOR_H

#include "dllexport.h"

#include <memory>
#include <queue>
#include <string>
#include <boost/date_time.hpp>

#include "canaerotypes.h"
#include "connectedclient.h"
#include "connector.h"
#include "scopedlock.h"
#include "nodesmodulemanager.h"

namespace SCS {

class CanAeroDataManager;

/**
  * @brief Handles CAN Aerospace message header and decodes node services.
  *
  * For communicating with CAN Aerospace, various node services must
  * be handled and some book keeping on connected clients must be done.
  * This class handles all this.
  *
  * @note This class is reentrant and thread-safe.
  * @author (c) 2009, 2010 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC CanAeroBusConnector: public BusConnector<can_t>
{
public:

    /**
      * @param manager instance handling incoming and outgoing data after protocol processing
      * @param connector the network-accessing instance
      * @param own_node_id your assigned node id or -1 for auto-configuration
      * @param config_revision minimum revision of SCS variables file required
      */
    CanAeroBusConnector(CanAeroDataManager* manager,
                        NetworkConnector<can_t>* connector,
                        uint8_t own_node_id,
                        uint8_t config_revision);

    /**
      * Remove all clients from the list that were silent for more than ConnectedClient::time_out seconds.
      */
    void doHouseKeeping();

    /**
      * @return the node id assigned in the c'tor, or the automatically assigned id after calling the c'tor with auto-configuration
      */
    uint8_t ownNodeId() const;

    /**
      * @param msg single message to send
      */
    void send(const can_t& msg);

    /**
      * @param msg array of messages to send
      */
    void send(const std::vector<can_t>& msg);

    /**
      * Send state transmission service to a node
      * @param node_id addressed node, broadcast by default
      */
    void sendSTS(uint8_t node_id = BROADCAST_NODE_ID);

    /**
      * Send data request service
      * @param request_id the CAN id you want
      * @param whether identifier is 11 or 29 bit long
      * @param node_id addressed node, broadcast by default
      */
    void sendDRS(can_Id_t can_id, uint8_t node_id = BROADCAST_NODE_ID);

    /**
      * Send identification service request
      * @param node_id addressed node, broadcast by default
      */
    void sendIDS(uint8_t node_id = BROADCAST_NODE_ID);

    /**
      * Processes service requests and responses, filters normal operation data.
      * @note This function is thread-safe.
      * @param msg single packet received
      */
    void receiveMessage(const can_t& msg);

    /**
      * Processes service requests and responses, filters normal operation data.
      * @note This function is thread-safe.
      * @param msg array of packets received
      */
    void receiveMessage(const std::vector<can_t>& msg);

    /**
      * request a module of a node to be en- or disabled.
      */
    void requestModule(uint8_t node_id, uint16_t module, uint16_t mode);

    /**
      * @param node_id the node that offers various modules
      * @param module the module to be queried
      * @return if a module is active on a node
      */
    bool isModuleActive(uint8_t node_id, uint16_t module);

    /**
      * @param node_id the client in question
      * @return whether the client has been actively transmitting data within the last 15 seconds
      */
    bool isClientActive(uint8_t node_id);

private:

    /**
      * Send module information service request
      * @param node_id adressed node, broadcast by default
      */
    void sendMIS(uint8_t node_id = BROADCAST_NODE_ID);

    void processServiceRequests(const can_t&);

    void processServiceResponses(const can_t&);

    uint8_t getNewNodeId(uint32_t uuid);


private:

    typedef std::map<uint8_t, ConnectedClient> ClientMap;
    typedef std::map<uint32_t, uint8_t> NCSMap;
    Mutex m_map_mutex;
    ClientMap m_connected_clients;
    NCSMap m_ncs_lookup;
    uint8_t m_own_node_id;
    const uint8_t m_config_revision;
    uint32_t m_gen_uuid;
    CanAeroDataManager* m_manager;
    NetworkConnector<can_t>* m_network_connector;
    NodesModuleManager m_nodes_module_manager;
    boost::posix_time::ptime m_last_did_MIS;
#ifdef USE_STOCK_DATAFRAME
    uint32_t m_frame_counter;
#endif
};

}

#endif // CANAEROBUSCONNECTOR_H
