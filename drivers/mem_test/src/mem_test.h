/*############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
############################################################################*/

#pragma once

//*******************************************************************************
// Includes
//*******************************************************************************
#include <stdint.h>
#include <stdbool.h>

//*******************************************************************************
// Constants
//*******************************************************************************

#define MEM_TEST_START_OFFS					0x00
#define MEM_TEST_STOP_OFFS					0x04
#define MEM_TEST_MODE_OFFS					0x0C
#define MEM_TEST_SIZE_LO_OFFS				0x10
#define MEM_TEST_SIZE_HI_OFFS				0x14
#define MEM_TEST_ADDR_LO_OFFS				0x18
#define MEM_TEST_ADDR_HI_OFFS				0x1C
#define MEM_TEST_PATTERN_OFFS				0x20
#define MEM_TEST_STATUS_OFFS				0x24
#define MEM_TEST_ERRORS_OFFS				0x28
#define MEM_TEST_FIRSTERR_LO_OFFS			0x2C
#define MEM_TEST_FIRSTERR_HI_OFFS			0x30
#define MEM_TEST_ITER_OFFS					0x34

//*******************************************************************************
// Types
//*******************************************************************************
typedef enum {RANDOM, IMMEDIATE, SEARCH} strategy;

typedef enum {
	MemTest_Mode_Single = 0,
	MemTest_Mode_Continuous = 1,
	MemTest_Mode_WriteOnly = 2,
	MemTest_Mode_ReadOnly = 3
} MemTest_Mode;

typedef enum {
	MemTest_Pattern_Count = 0,
	MemTest_Pattern_Walk1 = 1,
	MemTest_Pattern_OwnAddr = 2,
	MemTest_Pattern_Prbn = 3
} MemTest_Pattern;

typedef enum {
	MemTest_Status_Idle = 0,
	MemTest_Status_Writing = 1,
	MemTest_Status_Reading = 2,
	MemTest_Status_AxiErr = 3,
	MemTest_Status_IntErr = 6,
	MemTest_Status_Unknown = 7
} MemTest_Status;


//*******************************************************************************
// Functions
//*******************************************************************************

//Start Memory Test
void MemTest_Start(const uint32_t baseAddr);

//Stop Memory Test (only required in continuous mode)
void MemTest_Stop(const uint32_t baseAddr);

//Set memory test mode (only allowed if stopped)
void MemTest_SetMode(	const uint32_t baseAddr,
						const MemTest_Mode mode);
						
//Set memory test pattern (only allowed if stopped)
void MemTest_SetPattern(	const uint32_t baseAddr,
							const MemTest_Pattern pattern);
							
//Set memory range to test (only allowed if stopped)
void MemTest_SetRange(	const uint32_t baseAddr,
						const uint64_t startAddr,
						const uint64_t size);
						
//Get Memory Tester Status
MemTest_Status MemTest_GetStatus(const uint32_t baseAddr);

//Get Error Counter (cleared on Start())
uint32_t MemTest_GetErrors(const uint32_t baseAddr);

//Get Iteration Counter (cleared on Start())
uint32_t MemTest_GetIterations(const uint32_t baseAddr);

//Get Address of first error
uint64_t MemTest_GetFirstErrorAddr(const uint32_t baseAddr);

