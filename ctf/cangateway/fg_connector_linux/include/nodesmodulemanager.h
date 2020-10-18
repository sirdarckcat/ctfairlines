#ifndef NODESMODULEMANAGER_H
#define NODESMODULEMANAGER_H

#include <vector>
#include <map>
#include "canaerotypes.h"

namespace SCS {

/**
  * @brief Keeps track of all nodes connected to the bus and which modules they
  * exposed.
  *
  * This class saves you the trouble of doing all the Module Request Service requetsts
  * and Module Information Service requests and reponses by hand.
  * @author (c) 2009, 2010 by Philipp Münzel
  * @version 1.3
  */
class NodesModuleManager
{
public:
    NodesModuleManager();
    void requestMode(uint8_t node, uint16_t module, uint16_t mode);
    void setMode(uint8_t node, uint32_t modules);
    void removeNode(uint8_t node);
    bool isActive(uint8_t node, uint16_t module);
    std::vector<can_t> generateCommands(uint8_t requestor);
private:
    typedef std::map<uint8_t, uint32_t> MISMap;
    MISMap m_requested_modules;
    MISMap m_active_modules;
};

}

#endif // NODESMODULEMANAGER_H
