#ifndef IDS_H
#define IDS_H

#include "canaerotypes.h"
#include <vector>
#include <string>

namespace SCS {

//! @file ids.h
static const uint8_t IDENTIFIER_REVISION = 2;   //!< revision of SCS identifier distribution this SDK was created with

typedef scs_Id_t<float,                 302,    BIT11> G_LOAD_NORMAL;
typedef scs_Id_t<float,                 303,    BIT11> PITCH_RATE_DEG_S;
typedef scs_Id_t<float,                 304,    BIT11> ROLL_RATE_DEG_S;
typedef scs_Id_t<float,                 305,    BIT11> YAW_RATE_DEG_S;
typedef scs_Id_t<float,                 306,    BIT11> RUDDER_DEG;
typedef scs_Id_t<float,                 307,    BIT11> STABILIZER_DEG;
typedef scs_Id_t<float,                 308,    BIT11> ELEVATOR_DEG;
typedef scs_Id_t<float,                 309,    BIT11> AILERON_LEFT_DEG;
typedef scs_Id_t<float,                 310,    BIT11> AILERON_RIGHT_DEG;
typedef scs_Id_t<float,                 311,    BIT11> PITCH_DEG;
typedef scs_Id_t<float,                 312,    BIT11> BANK_DEG;
typedef scs_Id_t<float,                 313,    BIT11> SIDESLIP_DEG;
typedef scs_Id_t<float,                 314,    BIT11> VS_M_S;
typedef scs_Id_t<float,                 315,    BIT11> IAS_M_S;
typedef scs_Id_t<float,                 316,    BIT11> TAS_M_S;
typedef scs_Id_t<float,                 318,    BIT11> MACH;
typedef scs_Id_t<float,                 319,    BIT11> ALTSET_PILOT_HPA;
typedef scs_Id_t<float,                 320,    BIT11> ALT_PILOT_M;
typedef scs_Id_t<float,                 321,    BIT11> TRUE_HDG_DEG;
typedef scs_Id_t<float,                 323,    BIT11> TAT_K;
typedef scs_Id_t<float,                 324,    BIT11> OAT_K;
typedef scs_Id_t<float,                 328,    BIT11> AOA_DEG;
typedef scs_Id_t<float,                 332,    BIT11> TRUE_ALT_M;
typedef scs_Id_t<float,                 333,    BIT11> WIND_SPEED_M_S;
typedef scs_Id_t<float,                 334,    BIT11> WIND_DIR_DEG;
typedef scs_Id_t<float,                 400,    BIT11> PITCH_CONTROL_NORM;
typedef scs_Id_t<float,                 401,    BIT11> ROLL_CONTROL_NORM;
typedef scs_Id_t<float,                 403,    BIT11> YAW_CONTROL_NORM;
typedef scs_Id_t<float,                 405,    BIT11> TRIM_ELEV_NORM;
typedef scs_Id_t<std::vector<float>,    414,    BIT29> THROTTLE_SEPARATE_INPUT_NORM;
typedef scs_Id_t<float,                 430,    BIT11> FLAP_LEVER_NORM;
typedef scs_Id_t<float,                 432,    BIT11> PARK_BRAKE_NORM;
typedef scs_Id_t<float,                 433,    BIT11> SPEEDBRAKE_LEVER_NORM;
typedef scs_Id_t<float,                 435,    BIT11> BRAKE_PEDAL_LEFT_NORM;
typedef scs_Id_t<float,                 436,    BIT11> BRAKE_PEDAL_RIGHT_NORM;
typedef scs_Id_t<bool,                  442,    BIT11> STALL_WARNING;
typedef scs_Id_t<std::vector<float>,    500,    BIT29> ENG_N1_PERCENT;
typedef scs_Id_t<std::vector<float>,    504,    BIT29> ENG_N2_PERCENT;
typedef scs_Id_t<std::vector<float>,    520,    BIT29> ENG_EGT_K;
typedef scs_Id_t<std::vector<float>,    524,    BIT29> ENG_FF_KG_H;
typedef scs_Id_t<std::vector<float>,    800,    BIT29> HYD_PRES_HPA;
typedef scs_Id_t<float,                 1036,   BIT11> POS_GPS_LAT_DEG;
typedef scs_Id_t<float,                 1037,   BIT11> POS_GPS_LON_DEG;
typedef scs_Id_t<float,                 1039,   BIT11> GS_M_S;
typedef scs_Id_t<float,                 1041,   BIT11> MAG_TRK_DEG;
typedef scs_Id_t<float,                 1070,   BIT11> RADIO_HT_M;
typedef scs_Id_t<float,                 1071,   BIT11> DME1_DIST_M;
typedef scs_Id_t<float,                 1072,   BIT11> DME2_DIST_M;
typedef scs_Id_t<float,                 1083,   BIT11> ADF1_BRG_DEG;
typedef scs_Id_t<float,                 1084,   BIT11> ADF2_BRG_DEG;
typedef scs_Id_t<float,                 1087,   BIT11> LOC1_DEV_DEG;
typedef scs_Id_t<float,                 1088,   BIT11> LOC2_DEV_DEG;
typedef scs_Id_t<float,                 1091,   BIT11> GS1_DEV_DEG;
typedef scs_Id_t<float,                 1092,   BIT11> GS2_DEV_DEG;
typedef scs_Id_t<float,                 1095,   BIT11> FD1_PITCH_DEV_DEG;
typedef scs_Id_t<float,                 1097,   BIT11> FD1_ROLL_DEV_DEG;
typedef scs_Id_t<int32_t,               1100,   BIT29> COM1_FREQ_KHZ;
typedef scs_Id_t<int32_t,               1101,   BIT29> COM2_FREQ_KHZ;
typedef scs_Id_t<int32_t,               1104,   BIT29> NAV1_FREQ_KHZ;
typedef scs_Id_t<int32_t,               1105,   BIT29> NAV2_FREQ_KHZ;
typedef scs_Id_t<int32_t,               1108,   BIT11> ADF1_FREQ_KHZ;
typedef scs_Id_t<int32_t,               1109,   BIT11> ADF2_FREQ_KHZ;
typedef scs_Id_t<float,                 1121,   BIT11> MAG_VAR_DEG;
typedef scs_Id_t<float,                 1126,   BIT11> OBS1_DEG;
typedef scs_Id_t<float,                 1127,   BIT11> OBS2_DEG;
typedef scs_Id_t<bool,                  1176,   BIT11> WEIGHT_ON_WEELS;
typedef scs_Id_t<char4,                 1200,   BIT11> UTC_TIME;
typedef scs_Id_t<char4,                 1206,   BIT11> UTC_DATE;

typedef scs_Id_t<bool,                  1500,   BIT29> AVIONICS_SWITCH;
typedef scs_Id_t<bool,                  1501,   BIT29> BATTERY_SWITCH;
typedef scs_Id_t<bool,                  1510,   BIT29> LIGHT_BEACON_SWITCH;
typedef scs_Id_t<bool,                  1511,   BIT29> LIGHT_STROBE_SWITCH;
typedef scs_Id_t<bool,                  1512,   BIT29> LIGHT_LANDING_SWITCH;
typedef scs_Id_t<bool,                  1513,   BIT29> LIGHT_NAV_SWITCH;
typedef scs_Id_t<bool,                  1514,   BIT29> LIGHT_TAXI_SWITCH;
typedef scs_Id_t<bool,                  1515,   BIT29> LIGHT_INSTR_SWITCH;
typedef scs_Id_t<std::vector<float>,    1520,   BIT29> ENG_ANTI_ICE_NORM;
typedef scs_Id_t<bool,                  1521,   BIT29> PITOT_HEAT_SWITCH;
typedef scs_Id_t<int32_t,               1531,   BIT29> AP_MODE_BITFIELD;
typedef scs_Id_t<float,                 1532,   BIT29> AP_VS_M_S;
typedef scs_Id_t<float,                 1533,   BIT29> AP_ALT_M;
typedef scs_Id_t<float,                 1534,   BIT29> AP_HDG_DEG;
typedef scs_Id_t<float,                 1535,   BIT29> AP_SPD_M_S;
typedef scs_Id_t<float,                 1536,   BIT29> AP_MACH;
typedef scs_Id_t<bool,                  1537,   BIT29> AP_FD_SWITCH;
typedef scs_Id_t<int32_t,               1538,   BIT29> AP_AIRBUS_FGS_BITFIELD;
typedef scs_Id_t<int32_t,               1555,   BIT29> ACF_NUM_ENGINES;
typedef scs_Id_t<int32_t,               1556,   BIT29> ACF_NUM_FLAP_NOTCH;
typedef scs_Id_t<float,                 1557,   BIT29> ACF_FUEL_CAP_KG;
typedef scs_Id_t<std::vector<float>,    1560,   BIT29> GEAR_POSITION;
typedef scs_Id_t<std::vector<float> ,   1561,   BIT29> REVERSER_DEPLOY_NORM;
typedef scs_Id_t<bool,                  1562,   BIT29> SPOILER_ARMED;
typedef scs_Id_t<float,                 1563,   BIT29> FLAPS_POS_DEG;
typedef scs_Id_t<float,                 1564,   BIT29> FLAPS_LEFT_NORM;
typedef scs_Id_t<float,                 1565,   BIT29> FLAPS_RIGHT_NORM;
typedef scs_Id_t<float,                 1566,   BIT29> SLAT_POS_DEG;
typedef scs_Id_t<float,                 1570,   BIT29> TOTAL_WT_KG;
typedef scs_Id_t<float,                 1571,   BIT29> ZFW_KG;
typedef scs_Id_t<bool,                  1590,   BIT29> WARN_DOOR_OPEN;
typedef scs_Id_t<bool,                  1591,   BIT29> SIGN_SEATBELT;
typedef scs_Id_t<bool,                  1592,   BIT29> SIGN_NOSMOKING;
typedef scs_Id_t<int32_t,               1600,   BIT29> OBS1_TO_FROM;
typedef scs_Id_t<int32_t,               1601,   BIT29> OBS2_TO_FROM;
typedef scs_Id_t<bool,                  1602,   BIT29> NAV1_HAS_DME;
typedef scs_Id_t<bool,                  1603,   BIT29> NAV2_HAS_DME;
typedef scs_Id_t<bool,                  1604,   BIT29> ADF1_TUNED;
typedef scs_Id_t<std::string,           1605,   BIT29> ADF1_TUNED_ID;
typedef scs_Id_t<float,                 1606,   BIT29> ADF1_TUNED_LAT;
typedef scs_Id_t<float,                 1607,   BIT29> ADF1_TUNED_LON;
typedef scs_Id_t<bool,                  1608,   BIT29> ADF2_TUNED;
typedef scs_Id_t<std::string,           1609,   BIT29> ADF2_TUNED_ID;
typedef scs_Id_t<float,                 1610,   BIT29> ADF2_TUNED_LAT;
typedef scs_Id_t<float,                 1611,   BIT29> ADF2_TUNED_LON;
typedef scs_Id_t<bool,                  1612,   BIT29> NAV1_TUNED;
typedef scs_Id_t<std::string,           1613,   BIT29> NAV1_TUNED_ID;
typedef scs_Id_t<float,                 1614,   BIT29> NAV1_TUNED_LAT;
typedef scs_Id_t<float,                 1615,   BIT29> NAV1_TUNED_LON;
typedef scs_Id_t<bool,                  1616,   BIT29> NAV1_TUNED_LOC;
typedef scs_Id_t<float,                 1617,   BIT29> NAV1_TUNED_LOC_CRS;
typedef scs_Id_t<float,                 1618,   BIT29> NAV1_TUNED_GS_INCL;
typedef scs_Id_t<bool,                  1619,   BIT29> NAV2_TUNED;
typedef scs_Id_t<std::string,           1620,   BIT29> NAV2_TUNED_ID;
typedef scs_Id_t<float,                 1621,   BIT29> NAV2_TUNED_LAT;
typedef scs_Id_t<float,                 1622,   BIT29> NAV2_TUNED_LON;
typedef scs_Id_t<bool,                  1623,   BIT29> NAV2_TUNED_LOC;
typedef scs_Id_t<float,                 1624,   BIT29> NAV2_TUNED_LOC_CRS;
typedef scs_Id_t<float,                 1625,   BIT29> NAV2_TUNED_GS_INCL;
typedef scs_Id_t<int32_t,               1626,   BIT29> NAV_FLAGS_BITFIELD;
typedef scs_Id_t<float,                 1630,   BIT29> RUDDER_NORM;
typedef scs_Id_t<float,                 1631,   BIT29> ELEVATOR_NORM;
typedef scs_Id_t<float,                 1632,   BIT29> AILERON_NORM;
typedef scs_Id_t<float,                 1633,   BIT29> TRIM_RUD_DEG;
typedef scs_Id_t<float,                 1634,   BIT29> TRIM_ELEV_DEG;
typedef scs_Id_t<float,                 1635,   BIT29> THROTTLE_MASTER_INPUT_NORM;
typedef scs_Id_t<bool,                  1650,   BIT29> OVERRIDE_AIL_ON;
typedef scs_Id_t<bool,                  1651,   BIT29> OVERRIDE_ELV_ON;
typedef scs_Id_t<bool,                  1652,   BIT29> OVERRIDE_THRO_ON;
typedef scs_Id_t<std::vector<float>,    1655,   BIT29> OVERRIDE_THRO_NORM;
typedef scs_Id_t<float,                 1656,   BIT29> OVERRIDE_ELV_NORM;
typedef scs_Id_t<float,                 1657,   BIT29> OVERRIDE_AIL_NORM;
typedef scs_Id_t<bool,                  1660,   BIT29> SIM_PAUSED;
typedef scs_Id_t<float,                 1661,   BIT29> SIM_QNH_HPA;
typedef scs_Id_t<float,                 1662,   BIT29> SIM_DEW_K;
typedef scs_Id_t<float,                 1664,   BIT29> BARBER_POLE_SPD_M_S;
typedef scs_Id_t<float,                 1670,   BIT29> PITCH_ACCL_DEG_S_S;
typedef scs_Id_t<float,                 1671,   BIT29> ROLL_ACCL_DEG_S_S;
typedef scs_Id_t<float,                 1672,   BIT29> YAW_ACCL_DEG_S_S;
typedef scs_Id_t<bool,                  1700,   BIT29> MCP_BY_XP;
typedef scs_Id_t<int32_t,               1701,   BIT29> MCP_SPD;
typedef scs_Id_t<int32_t,               1702,   BIT29> MCP_HDG;
typedef scs_Id_t<int32_t,               1703,   BIT29> MCP_ALT;
typedef scs_Id_t<int32_t,               1704,   BIT29> MCP_VS;
typedef scs_Id_t<int32_t,               1705,   BIT29> MCP_BUTTON_LIGHTS;
typedef scs_Id_t<int32_t,               1706,   BIT29> MCP_BACK_LIGHT;
typedef scs_Id_t<int32_t,               1707,   BIT29> MCP_AT;
typedef scs_Id_t<int32_t,               1708,   BIT29> MCP_BUTTON_PUSHES;
typedef scs_Id_t<int32_t,               1709,   BIT29> MCP_CRS1;
typedef scs_Id_t<int32_t,               1710,   BIT29> MCP_CRS2;

}

#endif // IDS_H
