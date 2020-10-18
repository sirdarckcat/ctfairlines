#ifndef RECEIVERINTERFACEANSIC_H
#define RECEIVERINTERFACEANSIC_H

#include "dllexport.h"

#ifdef __cplusplus
extern "C" {
#endif

//! @file ansicreceiver.h
//! @brief These functions expose a SCS::Receiver to be callable from an ANSI C application
//!
//! Use this to connect to SCS if you can't use the C++ interface.
//! Exposes only the most basic functions.


typedef void(*funcSTS)(); //!< handle a State Transmission Service
typedef void(*funcMCS)(unsigned short, unsigned short); //!< handle a Module Control Service
typedef unsigned long(*funcMIS)();  //!< handle a Module Information Service
typedef int(*funcDRS)(unsigned long);   //!< handle a Data Request Service

/**
  * @brief Open the network interfaces and announce yourself to other participants on the bus.
  * @param required_software_revision revision of the CAN Aerospace distribution your application requires
  * @return opaque pointer to Receiver
  */
DLL_PUBLIC void* createReceiver(unsigned short required_revision);

/**
  * @brief Open the network interfaces and announce yourself to other participants on the bus.
  *
  * Mimics overriding the Receiver class with virtual functions. Use this if you want to ovveride the
  * default behavior
  * @param required_software_revision revision of the CAN Aerospace distribution your application requires
  * @param sts function to be called instead of Receiver::handleSTS
  * @param mcs function to be called instead of Receiver::handleMCS
  * @param mis function to be called instead of Receiver::handleMIS
  * @param drs function to be called instead of Receiver::handleDRS
  * @return opaque pointer to Receiver
  */
DLL_PUBLIC void* createReceiverWithFunctionOverride(unsigned short required_revision,
                                                    funcSTS sts,
                                                    funcMCS mcs,
                                                    funcMIS mis,
                                                    funcDRS drs);

/**
  * @brief Open the network interfaces and announce yourself to other participants on a specified multicast group.
  *
  * This function should not be needed under normal circumstances. You should use it only
  * if you need to change the mulitcast group. Don't use it to inject other IP adresses than
  * multicast addresses. SCS in default config will NOT work if you do this
  * @param required_software_revision revision of the CAN Aerospace distribution your application requires
  * @param own_node_id your assigned node id or 255 for auto-configuration
  * @param host_addr multicast group for SCS communication
  * @return opaque pointer to Receiver
  */
DLL_PUBLIC void* createReceiverForGroup(unsigned short required_revision, unsigned int node_id, const char* host_addr);

/**
  * @brief Open the network interfaces and announce yourself to other participants on a specified multicast group.
  *
  * This function should not be needed under normal circumstances. You should use it only
  * if you need to change the mulitcast group. Don't use it to inject other IP adresses than
  * multicast addresses. SCS in default config will NOT work if you do this
  *
  * Mimics overriding the Receiver class with virtual functions. Use this if you want to ovveride the
  * default behavior
  * @param required_software_revision revision of the CAN Aerospace distribution your application requires
  * @param own_node_id your assigned node id or 255 for auto-configuration
  * @param host_addr multicast group for SCS communication
  * @param sts function to be called instead of Receiver::handleSTS
  * @param mcs function to be called instead of Receiver::handleMCS
  * @param mis function to be called instead of Receiver::handleMIS
  * @param drs function to be called instead of Receiver::handleDRS
  * @return opaque pointer to Receiver
  */
DLL_PUBLIC void* createReceiverForGroupWithFunctionOverride(unsigned short required_revision,
                                                           unsigned int node_id,
                                                           const char* host_addr,
                                                           funcSTS sts,
                                                           funcMCS mcs,
                                                           funcMIS mis,
                                                           funcDRS drs);

/**
  * Request to receive updates on the given CAN Id from the bus. The identifier distribution
  * defines which data format is used.
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param i Pointer to variable to be updated when value changes on the bus
  */
DLL_PUBLIC void requestDataI(void* recv, unsigned long id, int id29, int* i);

/**
  * Request to receive updates on the given CAN Id from the bus. The identifier distribution
  * defines which data format is used.
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param f Pointer to variable to be updated when value changes on the bus
  */
DLL_PUBLIC void requestDataF(void* recv, unsigned long id, int id29, float* f);

/**
  * Request to receive updates on the given CAN Id from the bus. The identifier distribution
  * defines which data format is used.
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param d Pointer to variable to be updated when value changes on the bus
  */
DLL_PUBLIC void requestDataD(void* recv, unsigned long id, int id29, double* d);

/**
  * Request to receive updates on the given CAN Id from the bus. The identifier distribution
  * defines which data format is used. If the identifier distribution uses bools, this function converts it to ints
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param i Pointer to variable to be updated when value changes on the bus
  */
DLL_PUBLIC void requestDataB(void* recv, unsigned long id, int id29, int* i);

/**
  * Request to receive updates on the given CAN Id from the bus. The identifier distribution
  * defines which data format is used.
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param c Pointer to char array to be updated when value changes on the bus
  * @param maxlength maximum number of characters to be written to the memory specified by c
  */
DLL_PUBLIC void requestDataS(void* recv, unsigned long id, int id29, char* c, unsigned long maxlength);

/**
  * Request to receive updates on the given CAN Id from the bus. The identifier distribution
  * defines which data format is used.
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param f Pointer to float array to be updated when value changes on the bus
  * @param maxlength maximum number of floats to be written to the memory specified by f
  */
DLL_PUBLIC void requestDataVF(void* recv, unsigned long id, int id29, float* f, unsigned long maxlength);

/**
  * Request another bus participant to en- or disable one of its modules.
  *
  * Causes the node to be asked via MIS aboutits capabilities and enables
  * the requested capability via MCS.
  * @param recv opaque pointer to Receiver
  * @param node_id node which owns the requested module
  * @param module number of the module to be enabled
  * @param mode the mode command to set
  */
DLL_PUBLIC void requestModule(void* recv, unsigned int node_id, unsigned int module, unsigned int mode);


/**
  * Send value of given CAN id to the bus, so other participants are informed and can
  * synchronize themselves to the new value.
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param i value to be send
  */
DLL_PUBLIC void sendDataI(void* recv, unsigned long id, int id29, int i);

/**
  * Send value of given CAN id to the bus, so other participants are informed and can
  * synchronize themselves to the new value.
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param i value to be send
  */
DLL_PUBLIC void sendDataF(void* recv, unsigned long id, int id29, float f);

/**
  * Send value of given CAN id to the bus, so other participants are informed and can
  * synchronize themselves to the new value.
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param i value to be send
  */
DLL_PUBLIC void sendDataD(void* recv, unsigned long id, int id29, double d);

/**
  * Send value of given CAN id to the bus, so other participants are informed and can
  * synchronize themselves to the new value.
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param i value to be send
  */
DLL_PUBLIC void sendDataB(void* recv, unsigned long id, int id29, int i);

/**
  * Send value of given CAN id to the bus, so other participants are informed and can
  * synchronize themselves to the new value.
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param i value to be send
  */
DLL_PUBLIC void sendDataS(void* recv, unsigned long id, int id29, const char* c, unsigned long maxlength);

/**
  * Send value of given CAN id to the bus, so other participants are informed and can
  * synchronize themselves to the new value.
  * @param recv opaque pointer to Receiver
  * @param id CAN id of simulation data, specified in identifier distribution
  * @param id29 id width of the CAN id, 1 for 29bit, 0 for 11bit
  * @param i value to be send
  */
DLL_PUBLIC void sendDataVF(void* recv, unsigned long id, int id29, float* f, unsigned long maxlength);

/**
  * Call this repeatedly, either from the application's main loop or a separate
  * application thread.
  *
  * Will update pointers and invoke callbacks with new data.
  * Big black magic box that makes all work as you expect, ensuring the
  * protocol is handled following the CAN Aerospace and SCS specifications.
  * @param recv opaque pointer to Receiver
  */
DLL_PUBLIC void run(void* recv);

/**
  * Close all connections and free memory allocated by Receiver
  * @param recv opaque pointer to Receiver
  */
DLL_PUBLIC void freeReceiver(void* recv);

#ifdef __cplusplus
}
#endif

#endif // RECEIVERINTERFACEANSIC_H
