/*
 * Automatically send out UDP packets whenever data arrives on specified ASIC VATA interface.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <sys/mman.h>
#include <sys/socket.h> 
#include <sys/types.h> 
#include <arpa/inet.h> 
#include <netinet/in.h> 

#include "xil_types.h"
#include "xllfifo_hw.h"
#include "xparameters.h"

#include "vata_util.h"
#include "vata_constants.h"

#define MAXLINE  1024 
#define NDATA    128

//#define FIFO_BASEADDR XPAR_AXI_FIFO_MM_S_DATA_BASEADDR
//#define FIFO_HIGHADDR XPAR_AXI_FIFO_MM_S_DATA_HIGHADDR
//
//#define GPIO_BASEADDR XPAR_AXI_GPIO_TRIGGER_BASEADDR
//#define GPIO_HIGHADDR XPAR_AXI_GPIO_TRIGGER_HIGHADDR

static volatile int keep_running = 1;
void int_handle(int dummy) {
    keep_running = 0;
}

int create_sock(int *sockfd_ptr, struct sockaddr_in *servaddr_ptr) {
    int sockfd;
    if ( (sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0 ) { 
        perror("socket creation failed"); 
        return 1;
    }

    memset(servaddr_ptr, 0, sizeof(struct sockaddr_in)); 

    servaddr_ptr->sin_family = AF_INET; 
    //servaddr_ptr->sin_port = htons(DATA_PACKET_PORT); 
    servaddr_ptr->sin_port = htons(5000); 
    if (inet_aton("10.10.0.200", &servaddr_ptr->sin_addr) == 0) {
        perror("Invalid address.\n");
        return 1;
    }

    *sockfd_ptr = sockfd;
    return 0;
}

/* Returns number of bytes to send.
 * 0 if nothing was in the fifo.
 */
int read_fifo(u32 *pfifo, u32 *msg) {
    u32 rdfo = pfifo[XLLF_RDFO_OFFSET/4];
    if (rdfo == 0) {
        return 0;
    } 
    u32 rlr = pfifo[XLLF_RLF_OFFSET/4]/4;
    u32 i;
    msg[0] = rdfo;
    for (i=1; i<=rlr && i < NDATA; i++) {
        msg[i] = pfifo[XLLF_RDFD_OFFSET/4]; 
    }
    return sizeof(u32)*i;
}
  
int main(int argc, char **argv) { 

    int axi_fd, err;
    VataAddr vata_addr = args2vata_addr(argc, argv, &err);
    if (err != 0) {
        printf_args2vata_err(err);
        return 1;
    }
    u32 *pfifo = mmap_vata_fifo(&axi_fd, vata_addr);
    
    signal(SIGINT, int_handle);

    int sockfd; 
    struct sockaddr_in servaddr; 

    // Creating socket file descriptor 
    if (create_sock(&sockfd, &servaddr) != 0) {
        return 1; 
    }

    int i, j, k = 0, nbyte;
    u32 data[NDATA] = {0};

    // Clear interrupts:
    pfifo[0] = 0xFFFFFFFF;
    // Start sending the data!
    for (i=0; keep_running == 1; i++) {
        if ((nbyte = read_fifo(pfifo, data)) > 0) { 
            data[nbyte/sizeof(u32)] = (u32)i;
            sendto(sockfd, (const void *)data, nbyte+sizeof(u32), 0,
                   (const struct sockaddr *)&servaddr, sizeof(servaddr)); 
            printf("%06d: ", k);
            for (j=0; j<=nbyte/sizeof(u32); j++) {
                printf("%08x", data[j]);
            }
            printf("\n");
            k++;
        }
    }
              
    if (unmmap_vata_fifo(pfifo, vata_addr) != 0) {
        printf("ERROR: munmap() failed on FIFO\n");
        close(axi_fd);
        close(sockfd); 
        return 1;
    }

    close(axi_fd);
    close(sockfd); 

    return 0; 
} 

// vim: set ts=4 sw=4 sts=4 et:
