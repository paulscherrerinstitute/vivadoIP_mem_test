/*############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
############################################################################*/

#include "mem_test.h"
#include <xil_io.h>

//Start Memory Test
void MemTest_Start(const uint32_t baseAddr)
{
	Xil_Out32(baseAddr + MEM_TEST_START_OFFS, 1);
}

//Stop Memory Test (only required in continuous mode)
void MemTest_Stop(const uint32_t baseAddr)
{
	Xil_Out32(baseAddr + MEM_TEST_STOP_OFFS, 1);
}

//Set memory test mode (only allowed if stopped)
void MemTest_SetMode(	const uint32_t baseAddr,
						const MemTest_Mode mode)
{
	Xil_Out32(baseAddr + MEM_TEST_MODE_OFFS, (uint32_t)mode);					
}
						
//Set memory test pattern (only allowed if stopped)
void MemTest_SetPattern(	const uint32_t baseAddr,
							const MemTest_Pattern pattern)
{
	Xil_Out32(baseAddr + MEM_TEST_PATTERN_OFFS, (uint32_t)pattern);						
}
							
//Set memory range to test (only allowed if stopped)
void MemTest_SetRange(	const uint32_t baseAddr,
						const uint64_t startAddr,
						const uint64_t size)
{
	Xil_Out32(baseAddr+MEM_TEST_SIZE_LO_OFFS, (uint32_t)size);
	Xil_Out32(baseAddr+MEM_TEST_SIZE_HI_OFFS, (uint32_t)(size >> 32));
	Xil_Out32(baseAddr+MEM_TEST_ADDR_LO_OFFS, (uint32_t)startAddr);
	Xil_Out32(baseAddr+MEM_TEST_ADDR_HI_OFFS, (uint32_t)(startAddr >> 32));							
}
						
//Get Memory Tester Status
MemTest_Status MemTest_GetStatus(const uint32_t baseAddr)
{
	return (MemTest_Status)Xil_In32(baseAddr+MEM_TEST_STATUS_OFFS);
}

//Get Error Counter (cleared on Start())
uint32_t MemTest_GetErrors(const uint32_t baseAddr)
{
	return Xil_In32(baseAddr+MEM_TEST_ERRORS_OFFS);
}

//Get Iteration Counter (cleared on Start())
uint32_t MemTest_GetIterations(const uint32_t baseAddr)
{
	return Xil_In32(baseAddr+MEM_TEST_ITER_OFFS);
}

//Get Address of first error
uint64_t MemTest_GetFirstErrorAddr(const uint32_t baseAddr)
{
	const uint64_t addrHigh = Xil_In32(baseAddr+MEM_TEST_FIRSTERR_HI_OFFS);
	const uint64_t addrLow  = Xil_In32(baseAddr+MEM_TEST_FIRSTERR_LO_OFFS);
	return (addrHigh << 32) | addrLow;	
}
