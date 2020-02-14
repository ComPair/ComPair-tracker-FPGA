// Default UART settings should be:
// Baud: 9600
// 8 data bits
// 1 stop bit
// No parity.
//
// Messages:
// * "DELAYX\r", where 'X' is up to 26-digit long number to set the toggle delay time.
// * All other messages should be "PORT_NAME\r", which will start the given port toggling.
// * Toggling will stop once any \r-terminated  message is sent after the port-name message.
//
// If communication doesn't work at all, try swichting the UART_BASEADDR and UART_CLOCK_HZ
// macros to us XUARTPS_0
//
// NOTE: In case it's not clear, all uart msgs sent to PS should be terminated with '\r'
// This program cribbed heavily from:
// SDK/2018.3/data/embeddedsw/XilinxProcessorIPLib/drivers/uartps_v3_7/examples

#include "xparameters.h"
#include "xstatus.h"
#include "xil_types.h"
#include "xil_assert.h"
#include "xuartps_hw.h"
#include "xgpio_l.h"
#include "xil_printf.h"

#include <stdlib.h>
#include <string.h>

#include "platform.h"

#include "dbe_port_mapping.h"

// Note that XUARTPS_0 may have to get used???
#define UART_BASEADDR XPAR_XUARTPS_1_BASEADDR
#define UART_CLOCK_HZ XPAR_XUARTPS_1_CLOCK_HZ

// Size of send and receive buffers
#define N_BUF 32

void toggle_gpio(u32 port_num, u32 uart_baseaddr);
int uart_loop(u32 uart_baseaddr);
int run_cmd(u32 uart_baseaddr, char *recv_buf, char *send_buf);

volatile int delay = 10000; // Initial toggle delay

int main(void)
{
    init_platform();
    xil_printf("Starting toggle program.\r\n");

    int status = uart_loop(UART_BASEADDR);

    if (status != XST_SUCCESS) {
        xil_printf("GPIO toggle program failed??\r\n");
        return XST_FAILURE;
    }

    xil_printf("GPIO toggle program exiting successfully\r\n");

    cleanup_platform();
    return XST_SUCCESS;
}


// Initialize the uart
// Then, receive commands on loop, and dispatch them to the run_cmd function.
int uart_loop(u32 uart_baseaddr) {
    u32 running = 1;
    u32 cntrl_reg = XUartPs_ReadReg(uart_baseaddr, XUARTPS_CR_OFFSET);

    /* Enable TX and RX for the device */
    XUartPs_WriteReg(uart_baseaddr, XUARTPS_CR_OFFSET,
              ((cntrl_reg & ~XUARTPS_CR_EN_DIS_MASK) |
               XUARTPS_CR_TX_EN | XUARTPS_CR_RX_EN));

    char recv_buf[N_BUF];
    char send_buf[N_BUF];
    int bufindx = 0, run_cmd_ret, i;
    while (running) {
        // Wait until there is data
        while (!XUartPs_IsReceiveData(uart_baseaddr));
        recv_buf[bufindx] = XUartPs_ReadReg(uart_baseaddr,
                                            XUARTPS_FIFO_OFFSET);

        // If we have a '\r', then we are at the end of the command.
        if (recv_buf[bufindx] == '\r') {
            recv_buf[bufindx] = '\0'; // string terminate.
            xil_printf("Received command: %s\r\n", recv_buf);
            run_cmd_ret = run_cmd(uart_baseaddr, recv_buf, send_buf);
            if (run_cmd_ret > 0) {
                for (i=0; i<run_cmd_ret; i++) {
                    // Wait for space in FIFO...
                        while (XUartPs_IsTransmitFull(uart_baseaddr));
                    XUartPs_WriteReg(uart_baseaddr, XUARTPS_FIFO_OFFSET,
                             send_buf[i]);
                }
                bufindx = 0;
            } else {
                // Error occured. Exit.
                running = 0;
            }
        } else {
            bufindx++;
            if (bufindx == N_BUF) {
                // sent command is too long. Puke.
                xil_printf(
                    "Exiting program. Receiving a command that is too long and too hard to deal with.\r\n");
                return XST_FAILURE;
            }
        }
    }

    return XST_SUCCESS;
}

void toggle_gpio(u32 port_num, u32 uart_baseaddr) {

    u32 baseaddr = GPIO_BASEADDR[port_num];
    u32 data_offset = DATA_OFFSET[port_num];
    u32 on_value = ON_VALUE[port_num];

    // Keep toggling until we have data.
    int i;
    while (!XUartPs_IsReceiveData(uart_baseaddr)) {
        XGpio_WriteReg(baseaddr, data_offset, on_value);
        for (i=0; i < delay; i++);
        XGpio_WriteReg(baseaddr, data_offset, (u32)0);
        for (i=0; i < delay; i++);
    }

    // Now empty recv FIFO...
    char recv = '\0';
    while (recv != '\r') {
        while (!XUartPs_IsReceiveData(uart_baseaddr));
        recv = XUartPs_ReadReg(uart_baseaddr, XUARTPS_FIFO_OFFSET);
    }

}

int run_cmd(u32 uart_baseaddr, char *recv_buf, char *send_buf) {

    if (strncmp("DELAY", recv_buf, 5) == 0) {
        delay = atoi(recv_buf + 5);
        xil_printf("Setting delay to %u\r\n", delay);
        goto return_ok;
    } else if (strncmp("DIG_ASIC_1_S0", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_1_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_1_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_1_S1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_1_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_1_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_1_S2", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_1_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_1_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_1_S_LATCH", recv_buf, 18) == 0) {
        toggle_gpio(DIG_ASIC_1_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_1_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_1_I1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_1_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_1_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_1_I3", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_1_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_1_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_1_I4", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_1_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_1_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_2_S0", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_2_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_2_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_2_S1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_2_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_2_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_2_S2", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_2_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_2_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_2_S_LATCH", recv_buf, 18) == 0) {
        toggle_gpio(DIG_ASIC_2_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_2_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_2_I1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_2_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_2_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_2_I3", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_2_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_2_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_2_I4", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_2_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_2_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_1_CALD", recv_buf, 15) == 0) {
        toggle_gpio(DIG_ASIC_1_CALD, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_1_CALD\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_1_CALDB", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_1_CALDB, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_1_CALDB\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_1_OUT_5", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_1_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_1_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_1_OUT_6", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_1_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_1_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_2_OUT_5", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_2_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_2_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_2_OUT_6", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_2_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_2_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_3_S0", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_3_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_3_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_3_S1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_3_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_3_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_3_S2", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_3_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_3_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_3_S_LATCH", recv_buf, 18) == 0) {
        toggle_gpio(DIG_ASIC_3_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_3_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_3_I1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_3_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_3_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_3_I3", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_3_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_3_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_3_I4", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_3_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_3_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_4_S0", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_4_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_4_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_4_S1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_4_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_4_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_4_S2", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_4_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_4_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_4_S_LATCH", recv_buf, 18) == 0) {
        toggle_gpio(DIG_ASIC_4_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_4_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_4_I1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_4_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_4_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_4_I3", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_4_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_4_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_4_I4", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_4_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_4_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_3_CALD", recv_buf, 15) == 0) {
        toggle_gpio(DIG_ASIC_3_CALD, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_3_CALD\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_3_CALDB", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_3_CALDB, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_3_CALDB\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_3_OUT_5", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_3_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_3_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_3_OUT_6", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_3_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_3_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_4_OUT_5", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_4_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_4_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_4_OUT_6", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_4_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_4_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_5_S0", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_5_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_5_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_5_S1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_5_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_5_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_5_S2", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_5_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_5_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_5_S_LATCH", recv_buf, 18) == 0) {
        toggle_gpio(DIG_ASIC_5_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_5_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_5_I1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_5_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_5_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_5_I3", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_5_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_5_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_5_I4", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_5_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_5_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_6_S0", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_6_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_6_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_6_S1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_6_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_6_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_6_S2", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_6_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_6_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_6_S_LATCH", recv_buf, 18) == 0) {
        toggle_gpio(DIG_ASIC_6_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_6_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_6_I1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_6_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_6_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_6_I3", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_6_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_6_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_6_I4", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_6_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_6_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_5_CALD", recv_buf, 15) == 0) {
        toggle_gpio(DIG_ASIC_5_CALD, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_5_CALD\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_5_CALDB", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_5_CALDB, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_5_CALDB\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_5_OUT_5", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_5_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_5_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_5_OUT_6", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_5_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_5_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_6_OUT_5", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_6_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_6_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_6_OUT_6", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_6_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_6_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_7_S0", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_7_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_7_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_7_S1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_7_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_7_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_7_S2", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_7_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_7_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_7_S_LATCH", recv_buf, 18) == 0) {
        toggle_gpio(DIG_ASIC_7_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_7_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_7_I1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_7_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_7_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_7_I3", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_7_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_7_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_7_I4", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_7_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_7_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_8_S0", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_8_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_8_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_8_S1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_8_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_8_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_8_S2", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_8_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_8_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_8_S_LATCH", recv_buf, 18) == 0) {
        toggle_gpio(DIG_ASIC_8_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_8_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_8_I1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_8_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_8_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_8_I3", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_8_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_8_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_8_I4", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_8_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_8_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_7_CALD", recv_buf, 15) == 0) {
        toggle_gpio(DIG_ASIC_7_CALD, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_7_CALD\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_7_CALDB", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_7_CALDB, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_7_CALDB\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_7_OUT_5", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_7_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_7_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_7_OUT_6", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_7_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_7_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_8_OUT_5", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_8_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_8_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_8_OUT_6", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_8_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_8_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("DIG_A_VTH_CAL_DAC_MOSI_P", recv_buf, 24) == 0) {
        toggle_gpio(DIG_A_VTH_CAL_DAC_MOSI_P, uart_baseaddr);
        xil_printf("Toggling port DIG_A_VTH_CAL_DAC_MOSI_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_A_CAL_DAC_SYNCn_P", recv_buf, 21) == 0) {
        toggle_gpio(DIG_A_CAL_DAC_SYNCn_P, uart_baseaddr);
        xil_printf("Toggling port DIG_A_CAL_DAC_SYNCn_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_A_VTH_CAL_DAC_SCLK_P", recv_buf, 24) == 0) {
        toggle_gpio(DIG_A_VTH_CAL_DAC_SCLK_P, uart_baseaddr);
        xil_printf("Toggling port DIG_A_VTH_CAL_DAC_SCLK_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_A_CAL_PULSE_TRIGGER_P", recv_buf, 25) == 0) {
        toggle_gpio(DIG_A_CAL_PULSE_TRIGGER_P, uart_baseaddr);
        xil_printf("Toggling port DIG_A_CAL_PULSE_TRIGGER_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_A_VTH_DAC_SYNCn_P", recv_buf, 21) == 0) {
        toggle_gpio(DIG_A_VTH_DAC_SYNCn_P, uart_baseaddr);
        xil_printf("Toggling port DIG_A_VTH_DAC_SYNCn_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_A_TELEMX_MISO_P", recv_buf, 19) == 0) {
        toggle_gpio(DIG_A_TELEMX_MISO_P, uart_baseaddr);
        xil_printf("Toggling port DIG_A_TELEMX_MISO_P\r\n");
        goto return_ok;
    } else if (strncmp("PPS", recv_buf, 3) == 0) {
        toggle_gpio(PPS, uart_baseaddr);
        xil_printf("Toggling port PPS\r\n");
        goto return_ok;
    } else if (strncmp("DIG_A_TELEMX_MOSI_P", recv_buf, 19) == 0) {
        toggle_gpio(DIG_A_TELEMX_MOSI_P, uart_baseaddr);
        xil_printf("Toggling port DIG_A_TELEMX_MOSI_P\r\n");
        goto return_ok;
    } else if (strncmp("EXTCLK", recv_buf, 6) == 0) {
        toggle_gpio(EXTCLK, uart_baseaddr);
        xil_printf("Toggling port EXTCLK\r\n");
        goto return_ok;
    } else if (strncmp("DIG_A_TELEM1_SCLK_P", recv_buf, 19) == 0) {
        toggle_gpio(DIG_A_TELEM1_SCLK_P, uart_baseaddr);
        xil_printf("Toggling port DIG_A_TELEM1_SCLK_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_A_TELEM1_CSn_P", recv_buf, 18) == 0) {
        toggle_gpio(DIG_A_TELEM1_CSn_P, uart_baseaddr);
        xil_printf("Toggling port DIG_A_TELEM1_CSn_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_A_TELEM2_CSn_P", recv_buf, 18) == 0) {
        toggle_gpio(DIG_A_TELEM2_CSn_P, uart_baseaddr);
        xil_printf("Toggling port DIG_A_TELEM2_CSn_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_B_TELEMX_MISO_P", recv_buf, 19) == 0) {
        toggle_gpio(DIG_B_TELEMX_MISO_P, uart_baseaddr);
        xil_printf("Toggling port DIG_B_TELEMX_MISO_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_B_TELEMX_MOSI_P", recv_buf, 19) == 0) {
        toggle_gpio(DIG_B_TELEMX_MOSI_P, uart_baseaddr);
        xil_printf("Toggling port DIG_B_TELEMX_MOSI_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_B_TELEMX_SCLK_P", recv_buf, 19) == 0) {
        toggle_gpio(DIG_B_TELEMX_SCLK_P, uart_baseaddr);
        xil_printf("Toggling port DIG_B_TELEMX_SCLK_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_B_TELEM1_CSn_P", recv_buf, 18) == 0) {
        toggle_gpio(DIG_B_TELEM1_CSn_P, uart_baseaddr);
        xil_printf("Toggling port DIG_B_TELEM1_CSn_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_B_TELEM2_CSn_P", recv_buf, 18) == 0) {
        toggle_gpio(DIG_B_TELEM2_CSn_P, uart_baseaddr);
        xil_printf("Toggling port DIG_B_TELEM2_CSn_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_B_CAL_PULSE_TRIGGER_P", recv_buf, 25) == 0) {
        toggle_gpio(DIG_B_CAL_PULSE_TRIGGER_P, uart_baseaddr);
        xil_printf("Toggling port DIG_B_CAL_PULSE_TRIGGER_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_B_VTH_CAL_DAC_MOSI_P", recv_buf, 24) == 0) {
        toggle_gpio(DIG_B_VTH_CAL_DAC_MOSI_P, uart_baseaddr);
        xil_printf("Toggling port DIG_B_VTH_CAL_DAC_MOSI_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_B_VTH_CAL_DAC_SCLK_P", recv_buf, 24) == 0) {
        toggle_gpio(DIG_B_VTH_CAL_DAC_SCLK_P, uart_baseaddr);
        xil_printf("Toggling port DIG_B_VTH_CAL_DAC_SCLK_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_B_CAL_DAC_SYNCn_P", recv_buf, 21) == 0) {
        toggle_gpio(DIG_B_CAL_DAC_SYNCn_P, uart_baseaddr);
        xil_printf("Toggling port DIG_B_CAL_DAC_SYNCn_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_B_VTH_DAC_SYNCn_P", recv_buf, 21) == 0) {
        toggle_gpio(DIG_B_VTH_DAC_SYNCn_P, uart_baseaddr);
        xil_printf("Toggling port DIG_B_VTH_DAC_SYNCn_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_9_S0", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_9_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_9_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_9_S1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_9_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_9_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_9_S2", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_9_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_9_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_9_S_LATCH", recv_buf, 18) == 0) {
        toggle_gpio(DIG_ASIC_9_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_9_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_9_I1", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_9_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_9_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_9_I3", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_9_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_9_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_9_I4", recv_buf, 13) == 0) {
        toggle_gpio(DIG_ASIC_9_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_9_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_10_S0", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_10_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_10_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_10_S1", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_10_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_10_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_10_S2", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_10_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_10_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_10_S_LATCH", recv_buf, 19) == 0) {
        toggle_gpio(DIG_ASIC_10_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_10_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_10_I1", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_10_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_10_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_10_I3", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_10_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_10_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_10_I4", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_10_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_10_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_9_CALD", recv_buf, 15) == 0) {
        toggle_gpio(DIG_ASIC_9_CALD, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_9_CALD\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_9_CALDB", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_9_CALDB, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_9_CALDB\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_9_OUT_5", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_9_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_9_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_9_OUT_6", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_9_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_9_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_10_OUT_5", recv_buf, 17) == 0) {
        toggle_gpio(DIG_ASIC_10_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_10_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_10_OUT_6", recv_buf, 17) == 0) {
        toggle_gpio(DIG_ASIC_10_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_10_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_11_S0", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_11_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_11_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_11_S1", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_11_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_11_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_11_S2", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_11_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_11_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_11_S_LATCH", recv_buf, 19) == 0) {
        toggle_gpio(DIG_ASIC_11_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_11_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_11_I1", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_11_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_11_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_11_I3", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_11_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_11_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_11_I4", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_11_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_11_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_12_S0", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_12_S0, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_12_S0\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_12_S1", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_12_S1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_12_S1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_12_S2", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_12_S2, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_12_S2\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_12_S_LATCH", recv_buf, 19) == 0) {
        toggle_gpio(DIG_ASIC_12_S_LATCH, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_12_S_LATCH\r\n");
        goto return_ok;
    } else if (strncmp("Trig_Ack_P", recv_buf, 10) == 0) {
        toggle_gpio(Trig_Ack_P, uart_baseaddr);
        xil_printf("Toggling port Trig_Ack_P\r\n");
        goto return_ok;
    } else if (strncmp("Event_ID_Latch_P", recv_buf, 16) == 0) {
        toggle_gpio(Event_ID_Latch_P, uart_baseaddr);
        xil_printf("Toggling port Event_ID_Latch_P\r\n");
        goto return_ok;
    } else if (strncmp("Event_ID_P", recv_buf, 10) == 0) {
        toggle_gpio(Event_ID_P, uart_baseaddr);
        xil_printf("Toggling port Event_ID_P\r\n");
        goto return_ok;
    } else if (strncmp("Trig_ENA_P", recv_buf, 10) == 0) {
        toggle_gpio(Trig_ENA_P, uart_baseaddr);
        xil_printf("Toggling port Trig_ENA_P\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_12_I1", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_12_I1, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_12_I1\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_12_I3", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_12_I3, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_12_I3\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_12_I4", recv_buf, 14) == 0) {
        toggle_gpio(DIG_ASIC_12_I4, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_12_I4\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_11_CALD", recv_buf, 16) == 0) {
        toggle_gpio(DIG_ASIC_11_CALD, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_11_CALD\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_11_CALDB", recv_buf, 17) == 0) {
        toggle_gpio(DIG_ASIC_11_CALDB, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_11_CALDB\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_11_OUT_5", recv_buf, 17) == 0) {
        toggle_gpio(DIG_ASIC_11_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_11_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_11_OUT_6", recv_buf, 17) == 0) {
        toggle_gpio(DIG_ASIC_11_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_11_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_12_OUT_5", recv_buf, 17) == 0) {
        toggle_gpio(DIG_ASIC_12_OUT_5, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_12_OUT_5\r\n");
        goto return_ok;
    } else if (strncmp("DIG_ASIC_12_OUT_6", recv_buf, 17) == 0) {
        toggle_gpio(DIG_ASIC_12_OUT_6, uart_baseaddr);
        xil_printf("Toggling port DIG_ASIC_12_OUT_6\r\n");
        goto return_ok;
    } else if (strncmp("Si_HIT_P", recv_buf, 8) == 0) {
        toggle_gpio(Si_HIT_P, uart_baseaddr);
        xil_printf("Toggling port Si_HIT_P\r\n");
        goto return_ok;
    } else if (strncmp("Si_RDY_P", recv_buf, 8) == 0) {
        toggle_gpio(Si_RDY_P, uart_baseaddr);
        xil_printf("Toggling port Si_RDY_P\r\n");
        goto return_ok;
    } else if (strncmp("Si_BUSY_P", recv_buf, 9) == 0) {
        toggle_gpio(Si_BUSY_P, uart_baseaddr);
        xil_printf("Toggling port Si_BUSY_P\r\n");
        goto return_ok;
    } else if (strncmp("Si_SPARE_P", recv_buf, 10) == 0) {
        toggle_gpio(Si_SPARE_P, uart_baseaddr);
        xil_printf("Toggling port Si_SPARE_P\r\n");
        goto return_ok;
    } else {
        xil_printf("ERROR: bad command\r\n");
        strncpy(send_buf, "bad command\r", 12);
        return 12;
    }

return_ok:
    strncpy(send_buf, "ok\r", 3);
    return 3;
}

// vim: set ts=4 sw=4 sts=4 et:
