// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef CANAEROMETADATA_H
#define CANAEROMETADATA_H

#include "dllexport.h"

#include <ostream>
#ifdef HAVE_TR1
#include <tr1/cstdint>
#else
#include <stdint.h>
#endif

#include "canaerofunctions.h"
#include "log.h"

namespace SCS {

/**
  * @brief Processing of information contained in the CAN Aerospace header.
  *
  * Primary key is the CAN Id with either 11 or 29 bits.
  * The node id identifies the sender of normal operation data.
  * The message code for normal operation data is incremented with every
  * transmission. It counts from 0 to 255 and then wraps around to 0 again.
  * When incoming data is found to have inconsistent counting, a packet loss
  * information is reported to the Logger, the packet is processed nontheless.
  * @author (c) 2008-2010 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC CanAeroMetadata
{
public:

    /**
      * @param can_id CAN identifier
      * @param id29 whether identifier is 11 or 29 bit long
      * @param node_id sending node for normal operation data
      */
    CanAeroMetadata(can_Id_t can_id, uint8_t node_id = SCS_NODE_ID);

    /**
      * @return CAN with either 11 or 29 bit
      */
    can_Id_t id() const;

    /**
      * @return whether identifier is 11 or 29 bit long
      */
    AS_IDwidth isId29() const;

    /**
      * @return new message code for the next outgoing message
      * @note This function is indeed const because it cannot change the sorting order.
      */
    uint8_t increaseMessageCode() const;

    /**
      * Check if message code of incoming message is consistent, i.e. it is incremented
      * by one from the previously stored code.
      * @param new_code message code received
      * @return true for expected code, false for packet loss which has triggered a log message
      * @note This function is indeed const because it cannot change the sorting order.
      */
    bool checkMessageCode(uint8_t new_code) const;

    /**
      * node id of the transmitting node
      */
    uint8_t nodeId() const;

    /**
      * change node id (after re-assigning of node-ids)
      * @note this is indeed const because it doesn't affect the sorting order
      */
    void setNodeId(uint8_t node_id) const;

    /**
      * To be used as key in sets or maps, CAN data are sorted according to their id.
      * The id remains const over the lifetime of an instance.
      */
    bool operator<(const CanAeroMetadata& rhs) const;

private:
    mutable uint8_t m_node_id;  //!< This is mutable because it doesn't affect sorting
    can_Id_t    m_can_id;   //!< Immutable, is parameter for map sorting!
    mutable uint8_t m_message_code; //!< This is mutable because it doesn't affect sorting
};

}

std::ostream& operator<< (std::ostream& out, const SCS::CanAeroMetadata& meta);
SCS::Log& operator<< (SCS::Log& out, const SCS::CanAeroMetadata& meta);

#endif // CANAEROMETADATA_H
