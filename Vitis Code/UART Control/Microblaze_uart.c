/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xuartlite.h"

#define TMC_JXSE_BASE_ADDR XPAR_M_AHB_0_BASEADDR
#define TMC_JXSE_ENC_CMD       0x0000    
#define TMC_JXSE_ENC_SRST      0x0004    
#define TMC_JXSE_INT_STAT      0x0010    
#define TMC_JXSE_INT_RAW       0x0014    
#define TMC_JXSE_INT_EN        0x0018    
#define TMC_JXSE_ENC_TGT_SIZE  0x0020    
#define TMC_JXSE_ENC_PIC_SIZE  0x0024    
#define TMC_JXSE_ENC_PIC_FMT   0x0028    
#define TMC_JXSE_ENC_PROF      0x002C    
#define TMC_JXSE_ENC_NL        0x0034    
#define TMC_JXSE_ENC_MODE      0x0038    
#define TMC_JXSE_ENC_WGT_SET   0x003C    
#define TMC_JXSE_ENC_ERR_INFO0 0x0040    
#define TMC_JXSE_ENC_ERR_MASK0 0x0044    

// RF Settings
// Address for SPI
#define EN_TX                   0x41     // Enable n's Chip
#define EN_TX_BFn_PATH          0x42    // Enable n's Chip each antenna
#define EN_TX_BFn_PA            0x43    // Enable n's BF
#define EN_TX_BFn_VGA           0x46    
#define EN_MOD                  0x49
#define EN_MOD_DA               0x4A
#define EN_MOD_VCO              0x4B
#define MOD_VTUNE_ADJ           0x4D
#define MOD_BIAS                0x4E
#define TX_VG_BFn_PA_BIAS       0x50
#define TX_VG_BFn_VGA_ADJ       0x58
#define TX_CTRL2_BFn_LIN_BIAS   0x5A
#define TX_BFn_PS32_PH          0x68
#define TX_BFn_PS10_PH          0x69
#define TX_CTRL1_BFn_LIN        0x6B

// Address for I2C
#define EN_MOD_I2C              0x100
#define EN_BF0_VDDBF            0x101
#define EN_BF0_VDDPA            0x102
#define CTRL0                   0x103
#define VG0                     0x104
#define EN_BF1_VDDBF            0x105
#define EN_BF1_VDDPA            0x106
#define CTRL1                   0x107
#define VG1                     0x108
#define EN_BF2_VDDBF            0x109
#define EN_BF2_VDDPA            0x10A
#define CTRL2                   0x10B
#define VG2                     0x10C
#define EN_BF3_VDDBF            0x10D
#define EN_BF3_VDDPA            0x10E
#define CTRL3                   0x10F
#define VG3                     0x110

// UART
#define TEST_BUFFER_SIZE 16
XUartLite UartLite;
u8 SendBuffer[TEST_BUFFER_SIZE]; /* Buffer for Transmitting Data */
u8 RecvBuffer[TEST_BUFFER_SIZE]; /* Buffer for Receiving Data */

// Function
//void RF_initial_setting(int array_index_i, int * spi_address_array);
//int UART_BUF_Clear(int is_clear);
void RF_initial_setting(int array_index_i, int* spi_address_array, int flush_fin)
{
    int send_index = 0;
    int recv_index = 0;

    if (flush_fin == 1)
    {
        SendBuffer[0] = 'S';
        SendBuffer[1] = 0x03;

        if (array_index_i == 0)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = ((spi_address_array[array_index_i] >> 4) & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x08;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 1)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x0F;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 2)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x01;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 3)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x0F;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 4)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x08;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 5)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x08;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 6)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x08;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 7)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x08;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 8)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x00;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x07;
            SendBuffer[8] = 0x0F;
        }
        else if (array_index_i == 9)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x0D;
            SendBuffer[6] = 0x09;
            SendBuffer[7] = 0x0B;
            SendBuffer[8] = 0x09;
        }
        else if (array_index_i == 10)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x06;
            SendBuffer[6] = 0x06;
            SendBuffer[7] = 0x06;
            SendBuffer[8] = 0x06;
        }
        else if (array_index_i == 11)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x00;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 12)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x0B;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 13)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x06;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 14)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x00;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }
        else if (array_index_i == 15)
        {
            SendBuffer[2] = 0x00;
            SendBuffer[3] = (spi_address_array[array_index_i] >> 4 & 0x0F);
            SendBuffer[4] = (spi_address_array[array_index_i] & 0x0F);
            SendBuffer[5] = 0x00;
            SendBuffer[6] = 0x00;
            SendBuffer[7] = 0x00;
            SendBuffer[8] = 0x00;
        }

        SendBuffer[9] = 'Z';
    }


    for (send_index = 0; send_index < 10; send_index = send_index + 1)
    {
        XUartLite_SendByte(XPAR_UARTLITE_0_BASEADDR, SendBuffer[send_index]);
    }

    for (recv_index = 0; recv_index < 10; recv_index = recv_index + 1)
    {
        XUartLite_RecvByte(XPAR_UARTLITE_0_BASEADDR);
    }

    //XUartLite_ResetFifos(&UartLite);    // Resetting UART TX, RX Buffer
}

int main()
{
	u32 read_data;
	u32 write_data;

    init_platform();
    int Index;

    // Array Setting (init val)
    int array_index_i = 0;
    int spi_address_array[15] = { EN_TX, EN_TX_BFn_PATH, EN_TX_BFn_PA, EN_TX_BFn_VGA, EN_MOD, EN_MOD_DA, EN_MOD_VCO,
                                  MOD_VTUNE_ADJ, MOD_BIAS, TX_VG_BFn_PA_BIAS, TX_VG_BFn_VGA_ADJ, TX_CTRL2_BFn_LIN_BIAS,
                                 TX_BFn_PS32_PH, TX_BFn_PS10_PH, TX_CTRL1_BFn_LIN };
    int i2c_address_array[17] = { EN_MOD_I2C, EN_BF0_VDDBF, EN_BF0_VDDPA, CTRL0, VG0, EN_BF1_VDDBF, EN_BF1_VDDPA, CTRL1, VG1,
                                  EN_BF2_VDDBF, EN_BF2_VDDPA, CTRL2, VG2, EN_BF3_VDDBF, EN_BF3_VDDPA, CTRL3, VG3 };
    int flush_fin = 1;

    // AXI4-Lite
    Xil_Out32(XPAR_M05_AXI_0_BASEADDR+8, 0x01234567);
    Xil_Out32(XPAR_M05_AXI_0_BASEADDR+4, 0x89abcdef);
    read_data=Xil_In32(XPAR_M05_AXI_0_BASEADDR+8);
    Xil_Out32(XPAR_M05_AXI_0_BASEADDR+64, 0x89abcdef);

    // RF initial setting and Read
    for (array_index_i = 0; array_index_i < 15; array_index_i++)
    {
        RF_initial_setting(array_index_i, spi_address_array, flush_fin);
        flush_fin = 1;
    }

    while (1) {
    	read_data = Xil_In32 (TMC_JXSE_BASE_ADDR + TMC_JXSE_ENC_TGT_SIZE);
    	read_data = Xil_In32 (TMC_JXSE_BASE_ADDR + TMC_JXSE_ENC_PIC_SIZE);
    	read_data = Xil_In32 (TMC_JXSE_BASE_ADDR + TMC_JXSE_ENC_PIC_FMT);
    	usleep(50);
    	write_data = 0x12345678;
    	Xil_Out32(TMC_JXSE_BASE_ADDR + TMC_JXSE_ENC_TGT_SIZE, write_data);
    };

    cleanup_platform();
    return 0;
}