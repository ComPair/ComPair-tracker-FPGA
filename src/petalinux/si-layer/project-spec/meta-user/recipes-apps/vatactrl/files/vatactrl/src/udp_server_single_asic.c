/* 
 * Simple server to read from FIFO and spit out UDP packets to whoever is listening.
 */

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include "xllfifo_hw.h"
#include "xparameters.h"

#include "vata_util.h"
#include "vata_constants.h"

#define BUFSIZE 1024

static volatile int keep_running = 1;
void int_handle(int dummy) {
    keep_running = 0;
}

/*
 * error - wrapper for perror
 */
void error(char *msg) {
	perror(msg);
	exit(1);
}


int main(int argc, char **argv)
{
	int sockfd;		/* socket */
	//int portno;		/* port to listen on */
	int clientlen;		/* byte size of client's address */
	struct sockaddr_in serveraddr;	/* server's addr */
	struct sockaddr_in clientaddr;	/* client addr */
	struct hostent *hostp;	/* client host info */
	char *buf;		/* message buf */
	char *hostaddrp;	/* dotted decimal host addr string */
	int optval;		/* flag value for setsockopt */
	int n;			/* message byte size */
    int axi_fd;
    int err;
    int data_fd;

    if (argc > 2) {
        if ((data_fd = open(argv[2], O_RDWR | O_SYNC | O_CREAT, S_IRUSR | S_IWUSR)) == -1) {
            fprintf(stderr, "ERROR: could not open data file: %s\n", argv[2]);
            return 1;
        }
    } else {
        data_fd = -1;
    }



    VataAddr vata_addr = args2vata_addr(argc, argv, &err);
    if (err != 0) {
        printf_args2vata_err(err);
        return 1;
    }

    u32 *pfifo = mmap_vata_fifo(&axi_fd, vata_addr);
    if (pfifo == NULL) {
        fprintf(stderr, "ERROR: could not mmap vata fifo.\n");
        return 1;
    }

	/* 
	 * socket: create the parent socket 
	 */
	sockfd = socket(AF_INET, SOCK_DGRAM, 0);
	if (sockfd < 0)
		error("ERROR opening socket");

	/* setsockopt: Handy debugging trick that lets 
	 * us rerun the server immediately after we kill it; 
	 * otherwise we have to wait about 20 secs. 
	 * Eliminates "ERROR on binding: Address already in use" error. 
	 */
	optval = 1;
	setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR,
		   (const void *)&optval, sizeof(int));

	/*
	 * build the server's Internet address
	 */
	bzero((char *)&serveraddr, sizeof(serveraddr));
	serveraddr.sin_family = AF_INET;
	serveraddr.sin_addr.s_addr = inet_addr(DAQ_SERVER_ADDR);
	serveraddr.sin_port = htons(DATA_PACKET_PORT);

	/* 
	 * bind: associate the parent socket with a port 
	 */
	if (bind(sockfd, (struct sockaddr *)&serveraddr,
		 sizeof(serveraddr)) < 0)
		error("ERROR on binding");

	/* 
	 * main loop: wait for a datagram, then echo it
	 */
	clientlen = sizeof(clientaddr);

    /*
     * recvfrom: receive a UDP datagram from a client
     */
    buf = malloc(BUFSIZE);
    n = recvfrom(sockfd, buf, BUFSIZE, 0,
             (struct sockaddr *)&clientaddr, &clientlen);
    if (n < 0)
        error("ERROR in recvfrom");

    /* 
     * gethostbyaddr: determine who sent the datagram
     */
    hostp = gethostbyaddr((const char *)&clientaddr.sin_addr.s_addr,
                  sizeof(clientaddr.sin_addr.s_addr),
                  AF_INET);
    if (hostp == NULL)
        error("ERROR on gethostbyaddr");
    hostaddrp = inet_ntoa(clientaddr.sin_addr);
    if (hostaddrp == NULL)
        error("ERROR on inet_ntoa\n");

    printf("Client connected, received %d bytes\n", n);

    signal(SIGINT, int_handle);
    /* 
     * sendto: echo the input back to the client 
     */
    u32 isr, rlr, rdfo;
    int i, j;
    u32 data_buf[256];
    pfifo[0] = 0xFFFFFFFF;
    while (keep_running == 1) {
        //isr = pfifo[0];
        //pfifo[0] = 0xFFFFFFFF;
        rdfo = pfifo[XLLF_RDFO_OFFSET/4];
        if (rdfo > 0) {
            rlr = pfifo[XLLF_RLF_OFFSET/4]/4;
            for (j=0; j < rlr && j < 256; j++) {
                data_buf[j] = pfifo[XLLF_RDFD_OFFSET/4]; 
                printf("%08X", data_buf[j]);
            }
            if (data_fd >= 0) {
                write(data_fd, (void *)data_buf, rlr*sizeof(u32));
            }
            printf("\n");
            n = sendto(sockfd, data_buf, rlr * sizeof(u32), 0,
               (struct sockaddr *)&clientaddr, clientlen);
            printf("Sent %d bytes to client\n", n);
        } else {
            usleep(10000);
        }
    }

    if (data_fd >= 0) {
        close(data_fd);
    }

    if (unmmap_vata_fifo(pfifo, vata_addr) != 0) {
        printf("ERROR: munmap() failed on FIFO\n");
        close(axi_fd);
        return 1;
    }

    close(axi_fd);
}
// vim: set ts=4 sw=4 sts=4 et:
