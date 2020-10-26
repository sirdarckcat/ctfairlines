// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef CANAERODATAMANAGER_H
#define CANAERODATAMANAGER_H

#include "dllexport.h"
#include "canaerotypes.h"

namespace SCS {

/**
  * @brief Top-level interface. You must implement this to
  * handle service requests addressed to you and receive normal operation data.
  *
  * This interface's functions are called after processing of protocol headers
  * and standard node services. It must react to node-specific service
  * requests and handle incoming data.
  *
  * @author (c) 2009, 2010 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC CanAeroDataManager {
public:

    virtual ~CanAeroDataManager() {}

    /**
      * In case your application publishes CAN Aerospace normal operation data,
      * the state transmission service must trigger a sending of all data previously
      * requested via DRS.
      */
    virtual void handleSTS() = 0;

    /**
      * In case your application has modules exposed to the module information
      * and module configuration service, you must react on module configuration services here.
      * @param module Module affected
      * @param mode Mode parameter that shall be passed to this module
      */
    virtual void handleMCS(uint16_t module, uint16_t mode) = 0;

    /**
      * In case your application has modules exposed to the module information
      * and module configuration service, you must react on module information services here.
      * @return the bitfield of active modules
      */
    virtual uint32_t handleMIS() = 0;

    /**
      * In case your application publishes CAN Aerospace normal operation data,
      * you must react on data request services here.
      * @param id CAN id of data to be transmitted (cyclic) from now on
      */
    virtual bool handleDRS(uint32_t id) = 0;

    /**
      * Incoming normal operation data must be handled in this function.
      * @param can Message containing normal operation data
      */
    virtual void incomingData(const can_t& can) = 0;

    /**
      * An NCS caused a re-numbering of this node. Make sure all your CanAeroMetadatas
      * are updated to the new sending node id, otherwise you will hear yourself and this
      * causes all kinds of nasty side-effects.
      * @param node_id the new node_id this node was assigned
      */
    virtual void changeNodeId(uint8_t node_id) = 0;
};
}

#endif // CANAERODATAMANAGER_H
