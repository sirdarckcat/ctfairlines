// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef RECEIVER_H
#define RECEIVER_H

#include "dllexport.h"

#include <map>
#include <boost/function.hpp>

#include "canaerometadata.h"
#include "datareference.h"
#include "canaerobusconnector.h"
#include "canaerodatamanager.h"

namespace SCS {

/**
  * @brief The main class and entry point to the CAN Aerospace world.
  * It manages network access and handles all protocol requirements.
  *
  * The receiver maintains a list of CAN ids the application subscribed to.
  * Notification on data changes is available either via callback functions or
  * through pointers to variables that shall be updated.
  *
  * Calling Receiver::requestData enables you to communicate with all
  * participants on the bus. It is the sole thing to do for interaction with
  * the simulator.
  *
  * For more advanced use cases, like custom node services and publishing own data,
  * inherit from Receiver and reimplement handleSTS, handleMCS and handleDRS functions.
  *
  * For even more customization, you can implement the CanAeroDataManager interface.
  * Also take a look at the TypelessDataReference interface, which is implemented by
  * several templates for strongly-typed data access.
  *
  * @note Thread safety: This class is reentrant.
  * @note callbacks are guaranteed to be invoked from the same thread the Receiver::run()
  * function is called.
  *
  * @author (c) 2009, 2010 by Philipp Münzel
  * @version 1.3
  */
class DLL_PUBLIC Receiver : public CanAeroDataManager
{
public:

    /**
      * Open the network interfaces and announce yourself to other participants on the bus.
      * @param required_software_revision revision of the CAN Aerospace distribution your application requires
      * @param own_node_id your assigned node id or 255 for auto-configuration
      * @param host_addr can be used to assign different SCS subnets to different multicast groups. If you don't need this, leave it unchanged!!!
      */
    Receiver(uint8_t required_software_revision,
             uint8_t own_node_id = 255,
             const std::string& host_addr = "239.40.41.42");


    /**
      * Open the network interfaces and announce yourself to other participants on the bus.
      * @param required_software_revision revision of the CAN Aerospace distribution your application requires
      * @param connector pointer to a compliant network connector, ownership is taken by Receiver
      * @param own_node_id your assigned node id or 255 for auto-configuration
      */
    Receiver(uint8_t required_software_revision,
             NetworkConnector<can_t>* connector,
             uint8_t own_node_id = 255);


    /**
      * Close all connections
      */
    virtual ~Receiver();


    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @note This function comes in handy when you need own DataRef implementations.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param dataref pointer to some ready-to-use DataReference implementation
      * @deprecated Only for internal use. To be discontinued without further notice.
      */
    void requestData(can_Id_t can_id, TypelessDataReference* dataref);


    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, int32_t* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, float* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, double* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, bool* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, char4* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, std::string* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, std::vector<float>* t);


    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (int32_t)> f, int32_t* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (float)> f, float* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (double)> f, double* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (bool)> f, bool* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (char4)> f, char4* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (const std::string&)> f, std::string* t);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      * @param t Pointer to variable to be updated when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (const std::vector<float>&)> f, std::vector<float>* t);


    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (int32_t)> f);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (float)> f);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (double)> f);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (bool)> f);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (char4)> f);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (const std::string&)> f);

    /**
      * Request to receive updates on the given CAN Id from the bus. The identifier distribution
      * defines which data format is used.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param f Callback function to be called when value changes on the bus
      */
    void requestData(can_Id_t can_id, boost::function<void (const std::vector<float>&)> f);


    /**
      * Send value of given CAN id to the bus, so other participants are informed and can
      * synchronize themselves to the new value.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t value to be send
      */
    void sendData(can_Id_t can_id, int32_t t);

    /**
      * Send value of given CAN id to the bus, so other participants are informed and can
      * synchronize themselves to the new value.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t value to be send
      */
    void sendData(can_Id_t can_id, float t);

    /**
      * Send value of given CAN id to the bus, so other participants are informed and can
      * synchronize themselves to the new value.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t value to be send
      */
    void sendData(can_Id_t can_id, double t);

    /**
      * Send value of given CAN id to the bus, so other participants are informed and can
      * synchronize themselves to the new value.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t value to be send
      */
    void sendData(can_Id_t can_id, bool t);

    /**
      * Send value of given CAN id to the bus, so other participants are informed and can
      * synchronize themselves to the new value.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t value to be send
      */
    void sendData(can_Id_t can_id, char4 t);

    /**
      * Send value of given CAN id to the bus, so other participants are informed and can
      * synchronize themselves to the new value.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t value to be send
      */
    void sendData(can_Id_t can_id, const std::string& t);

    /**
      * Send value of given CAN id to the bus, so other participants are informed and can
      * synchronize themselves to the new value.
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @param t value to be send
      */
    void sendData(can_Id_t can_id, const std::vector<float>& t);


    /**
      * Send value of given CAN id to the bus, so other participants are informed and can
      * synchronize themselves to the new value.
      * @note The value sent is read from the pointer you specified when requesting the data
      * @param can_id CAN id of simulation data, specified in identifier distribution
      */
    void sendData(can_Id_t can_id);

//    /**
//      * Offer data to be requested by other participants on the bus.
//      * @param can_id_29bit the CAN id in 29bit adress range which others have to request to get this data
//      * @param t pointer where data should be read if someone requests it and is written if someone sends it
//      */
//    void offerData(uint32_t can_id_29bit, int32_t* t);

//    void offerData(uint32_t can_id_29bit, boost::function<void(int32_t)> readfunc, boost::function<int32_t()> writefunc);


    /**
      * Call this repeatedly, either from the application's main loop or a separate
      * application thread.
      *
      * Will update pointers and invoke callbacks with new data.
      * Big black magic box that makes all work as you expect, ensuring the
      * protocol is handled following the CAN Aerospace and SCS specifications.
      * @note It is guaranteed that all callbacks are called from the very same
      * thread this function is called from.
      * @param do_log_output log all messages to the defaultlogger. Disable
      * this if you call the LogWriter::writeEntries() of your own logger somewhere else
      */
    void run(bool do_log_output = true);


    /**
      * Request another bus participant to en- or disable one of its modules.
      *
      * Causes the node to be asked via MIS aboutits capabilities and enables
      * the requested capability via MCS.
      * @param node_id node which owns the requested module
      * @param module number of the module to be enabled
      * @param mode the mode command to set
      */
    void requestModule(uint8_t node_id, uint16_t module, uint16_t mode = 1);


    /**
      * @param can_id CAN id of simulation data, specified in identifier distribution
      * @note This function comes in handy when you need own DataRef implementations.
      * @return pointer to instance of (custom) DataReference implementation
      * @deprecated Only for internal use. To be discontinued without further notice.
      */
    TypelessDataReference* get(can_Id_t can_id);


protected:

    /**
      * Handle incoming state transmission services.
      * You may override this function if you inherit from Receiver.
      * The state transmission service must transmit all CAN ids
      * published exclusively by your application once.
      */
    virtual void handleSTS();

    /**
      * Handle incoming module configuration services.
      * You may override this function if you inherit from Receiver.
      * @param module Module affected
      * @param mode Mode parameter that shall be passed to this module
      */
    virtual void handleMCS(uint16_t module, uint16_t mode);

    /**
      * Handle incoming module information services.
      * You may override this function if you inherit from Receiver.
      */
    virtual uint32_t handleMIS();

    /**
      * Handle incoming data request services.
      * You may override this function if you inherit from Receiver.
      * The data request service must only answer requests for CAN ids
      * published exclusively by your application.
      */
    virtual bool handleDRS(uint32_t) ;


private:
    /**
      * Handle incoming data the application subscribed to. Is called on
      * incoming normal operation data.
      */
    void incomingData(const can_t&);

    /**
      * Change all node ids in the map of requested data.
      */
    void changeNodeId(uint8_t node_id);

private:
    class ReceiverImpl;
    ReceiverImpl* m_pimpl;
    friend class CanAeroBusConnector;
};

}

#endif // RECEIVER_H
