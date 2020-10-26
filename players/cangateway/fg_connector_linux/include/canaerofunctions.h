// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef CANAEROFUNCTIONS_H
#define CANAEROFUNCTIONS_H

#include "dllexport.h"

#include <string>
#include <stdexcept>
#ifdef HAVE_TR1
    #include <tr1/cstdint>
#else
    #include <stdint.h>
#endif

#include "canaerotypes.h"

namespace SCS {

    class WrongDataTypeError : public std::runtime_error {
    public:
        WrongDataTypeError():
                std::runtime_error("")
        {}
    };

    DLL_PUBLIC int ipow(int base, int exp);

    DLL_PUBLIC int32_t getIntFromCan(const can_t& can) throw (WrongDataTypeError);

    DLL_PUBLIC uint32_t getUnsignedIntFromCan(const can_t& can) throw (WrongDataTypeError);

    DLL_PUBLIC uint16_t getFirstUnsignedShortsFromCan(const can_t& can) throw (WrongDataTypeError);

    DLL_PUBLIC uint16_t getSecondUnsignedShortsFromCan(const can_t& can) throw (WrongDataTypeError);

    DLL_PUBLIC float getFloatFromCan(const can_t& can) throw (WrongDataTypeError);

    DLL_PUBLIC double getDoubleFromCan(const can_t& can) throw (WrongDataTypeError);

    DLL_PUBLIC bool getBoolFromCan(const can_t& can) throw (WrongDataTypeError);

    DLL_PUBLIC std::string getStdStringFromCan(const can_t& can) throw (WrongDataTypeError);

    DLL_PUBLIC void getStdStringChunkFromCan(const can_t& can, std::string& str) throw (WrongDataTypeError);

    DLL_PUBLIC unsigned char getUCharFromCan(const can_t& can, uint8_t position = 0) throw (WrongDataTypeError);

    DLL_PUBLIC uint8_t getIndexFromCan(const can_t& can) throw (WrongDataTypeError);

    DLL_PUBLIC AS_Type getASDataTypeFromCan(const can_t& can);

    DLL_PUBLIC SCS::char4 getChar4FromCan(const can_t& can) throw (WrongDataTypeError);

    DLL_PUBLIC can_t writeToCan(can_Id_t id, double data, uint8_t message_code, uint8_t node_id);

    DLL_PUBLIC can_t writeToCan(can_Id_t id, float data, uint8_t message_code, uint8_t node_id);

    DLL_PUBLIC can_t writeToCan(can_Id_t id, float data, uint8_t index, uint8_t message_code, uint8_t node_id);

    DLL_PUBLIC can_t writeToCan(can_Id_t id, int data, uint8_t index, uint8_t message_code, uint8_t node_id);

    DLL_PUBLIC can_t writeToCan(can_Id_t id, int data, uint8_t message_code, uint8_t node_id);

    DLL_PUBLIC can_t writeToCan(can_Id_t id, bool data, uint8_t message_code, uint8_t node_id);

    DLL_PUBLIC can_t writeToCan(can_Id_t id, const std::string& data, uint8_t message_code, uint8_t node_id);

    DLL_PUBLIC can_t writeToCan(can_Id_t id, const std::string& data, uint8_t index, uint8_t message_code, uint8_t node_id);

    DLL_PUBLIC can_t writeToCan(can_Id_t id, const SCS::char4& data, uint8_t message_code, uint8_t node_id);

    DLL_PUBLIC can_t writeNodeServiceRequest(uint8_t node_id, uint8_t service_code, AS_Type type = AS_NODATA, canAS_Data_t data = canAS_Data_t(), uint8_t msg_code = 0, can_Id_t channel = can_Id_t(128,BIT11));

    DLL_PUBLIC can_t writeDRSNodeServiceRequest(uint8_t node_id, uint32_t param, uint8_t requestor, can_Id_t channel = can_Id_t(128,BIT11));

    DLL_PUBLIC can_t writeMCSNodeServiceRequest(uint8_t node_id, uint16_t module, uint16_t mode, uint8_t requestor, can_Id_t channel = can_Id_t(128,BIT11));

    DLL_PUBLIC can_t writeMISNodeServiceRequest(uint8_t node_id, uint8_t requestor, can_Id_t channel = can_Id_t(128,BIT11));

    DLL_PUBLIC can_t writeNCSNodeServiceRequest(uint32_t node_uuid, can_Id_t channel = can_Id_t(128,BIT11));

    DLL_PUBLIC can_t writeNodeServiceResponse(uint8_t node_id, uint8_t service_code, AS_Type data_type, canAS_Data_t message_data, uint8_t message_code = 0,  can_Id_t channel = can_Id_t(129, BIT11));

    DLL_PUBLIC can_t writeNCSResponse(uint32_t node_uuid, uint8_t node_id, can_Id_t channel = can_Id_t(129,BIT11));

}


#endif // CANAEROFUNCTIONS_H
