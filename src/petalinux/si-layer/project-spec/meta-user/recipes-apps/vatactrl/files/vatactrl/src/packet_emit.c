/*
 * Automatically send out UDP packets whenever data arrives on stream-MM fifo
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

#include "mmap_addr.h"

#define SERVER   "192.168.1.11"
#define PORT     5000 
#define MAXLINE  1024 
#define NDATA    128
#define DEFAULT_DATA_FILE "data.hex"

#define FIFO_BASEADDR XPAR_AXI_FIFO_MM_S_0_BASEADDR
#define FIFO_HIGHADDR XPAR_AXI_FIFO_MM_S_0_HIGHADDR

#define GPIO_BASEADDR XPAR_AXI_GPIO_TRIGGER_BASEADDR
#define GPIO_HIGHADDR XPAR_AXI_GPIO_TRIGGER_HIGHADDR

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
    servaddr_ptr->sin_port = htons(PORT); 
    if (inet_aton(SERVER, &servaddr_ptr->sin_addr) == 0) {
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
    FILE *data_fp;
    if (argc == 1) {
        if ((data_fp = fopen(DEFAULT_DATA_FILE, "a")) == NULL) {
            printf("ERROR: could not open data file: %s.\n", DEFAULT_DATA_FILE);
            return 1;
        }
    } else if (argc == 2) {
        if ((data_fp = fopen(argv[1], "a")) == NULL) {
            printf("ERROR: could not open data file: %s.\n", argv[1]);
            return 1;
        }
    } else {
        printf("Usage: packet_emit [DATA-FILE]\n");
        return 1;
    }

    signal(SIGINT, int_handle);

    int sockfd; 
    struct sockaddr_in servaddr; 

    // Creating socket file descriptor 
    if (create_sock(&sockfd, &servaddr) != 0) {
        return 1; 
    }

    // mmap the axi bus
    int axi_fd;
    if ( (axi_fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("ERROR: could not open /dev/mem.\n");
        return 1;
    }
    u32 fifo_span = FIFO_HIGHADDR - FIFO_BASEADDR + 1;
    u32 *pfifo = mmap_addr(axi_fd, FIFO_BASEADDR, fifo_span);
    u32 gpio_span = GPIO_HIGHADDR - GPIO_BASEADDR + 1;
    u32 *pgpio = mmap_addr(axi_fd, GPIO_BASEADDR, gpio_span);
          
    int i, j, nbyte;
    u32 data[NDATA] = {0};

    // Clear interrupts:
    pfifo[0] = 0xFFFFFFFF;
    // Start data acq:
    pgpio[0] = 1;
    // Start sending the data!
    for (i=0; keep_running == 1; i++) {
        if ((nbyte = read_fifo(pfifo, data)) > 0) { 
            data[nbyte/sizeof(u32)] = (u32)i;
            sendto(sockfd, (const char *)data, nbyte+sizeof(u32), MSG_CONFIRM,
                   (const struct sockaddr *)&servaddr, sizeof(servaddr)); 
            for (j=0; j<=nbyte/sizeof(u32); j++) {
                fprintf(data_fp, "%08x", data[j]);
            }
            fprintf(data_fp, "\n");
        }
    }
    pgpio[0] = 0;
              
    if (munmap((void *)pfifo, fifo_span) != 0) {
        printf("ERROR: munmap() failed on FIFO\n");
        close(axi_fd);
        close(sockfd); 
        return 1;
    }
    if (munmap((void *)pgpio, gpio_span) != 0) {
        printf("ERROR: munmap() failed on GPIO\n");
        close(axi_fd);
        close(sockfd); 
        return 1;
    }

    close(axi_fd);
    close(sockfd); 
    fclose(data_fp);

    return 0; 
} 

// vim: set ts=4 sw=4 sts=4 et:
