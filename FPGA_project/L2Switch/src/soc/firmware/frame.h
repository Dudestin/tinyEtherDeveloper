#pragma once

#define MAC_ADDR (0xAA_AA_AA_AA_AA_AA) // system MAC address (not each port's MAC address)
#define BRIDGE_PRIORITY (32768)        // 0(high priority) to 65535, default : 32768
/* if you desire to use this switch as STP root-bridge, active following statements */
// #define BRIDGE_PRIORITY (0)

/* definition of Frame memory layout */

/* Ethernet Frame Header */
/* 14 Bytes */
struct HEADER {
    unsigned char  DST_MAC[6];  // 6-Bytes
    unsigned char  SRC_MAC[6];  // 6-Bytes
    unsigned short TYPE;        // 2-Bytes
} __attribute__((__packed__));

/* my original expanded header */
/* 16 Bytes */
/* used in RX only, don't use for TX !! */
struct EXPAND_HEADER {
    unsigned short PAD : 12;
    unsigned char  FCS_CORRECT : 1;
    unsigned char  IS_CTRL : 1;
    unsigned char  PORT : 2; // frame comming port
    struct HEADER orig_header;
} __attribute__((__packed__));

/* IEEE802.2 LLC */
/* 3 Bytes */
struct LLC {
    unsigned char DSAP;
    unsigned char SSAP;
    unsigned char CTRL;
} __attribute__((__packed__));

/* BPDU ver.0 format */
/* 38 + 8(PAD) = 46 Bytes */
struct BPDU_ver0 {
    struct LLC llc;
    unsigned short PROT_ID;  // 2-bytes
    unsigned char  PROT_VER;
    unsigned char  BPDU_TYPE;
    unsigned char  BPDU_FLAG;
    unsigned long  ROOT_ID;  // 8-Bytes
    unsigned int   ROOT_PATH_COST; // 4-Bytes
    unsigned long  BRID_ID;  // 8-Bytes
    unsigned short PORT_IDEN;// 2-Bytes
    unsigned short MSG_AGE;  // 2-Bytes
    unsigned short MAX_AGE;  // 2-Bytes
    unsigned short HEL_TIME; // 2-Bytes
    unsigned short FRWD_DLY; // 2-Bytes    
    unsigned char  PAD[7];   // padding, 7-Bytes
} __attribute__((__packed__));

/* PAUSE defined as IEEE802.3X */
/* 4 + 42 = 46 Bytes (and Padding) */
struct PAUSE {
    unsigned short OPR_CODE; // 2-Bytes
    unsigned short ABT_TIME; // 2-Bytes
    unsigned char  PAD[42];  // 42-Bytes
} __attribute__((__packed__));

/* Payload memory layout */
union  PAYLOAD {
    struct BPDU_ver0 bpdu;
    struct PAUSE pause;
} __attribute__((__packed__)) body; // 46-Bytes

/* FRAME layout for TX module */
/* 14(HEADER) + 46(PAYLOAD) + 4(FCS) = 64 Bytes */
struct FRAME_TX {
    struct HEADER header; // 14-Bytes
    union  PAYLOAD payload; // 46-Bytes
    unsigned int FCS; // 4-Bytes
} __attribute__((__packed__));

/* FRAME layout for RX module */
/* 16(EXPAND_HEADER) + 46(PAYLOAD) + 4(FCS) = 66 Bytes */
/* exceed 64 Bytes, so half of FCS section will be cut off*/
/* But this is not a problem, FCS correct check is done by hardware at before */
/* you can check FCS-check result at EXPAND_HEADER.FCS_CORRECT */
struct FRAME_RX {
    struct EXPAND_HEADER exp_header; // 16-Bytes
    union  PAYLOAD payload; // 46-Bytes
    unsigned int FCS; // 4-Bytes
} __attribute__((__packed__));
