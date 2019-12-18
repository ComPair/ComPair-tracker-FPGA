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
#include <sys/time.h>

#include "xllfifo_hw.h"
#include "xparameters.h"

#include "vata_util.h"
#include "vata_constants.h"

#define BUFSIZE 1024
#define NDATA_BUF 512
#define FIFO_NCHECK_TIMEOUT 1000

#define OFFSET0 DATA_PACKET_HEADER_NBYTES

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

    if (argc > 1) {
        if ((data_fd = open(argv[1], O_RDWR | O_SYNC | O_CREAT, S_IRUSR | S_IWUSR)) == -1) {
            fprintf(stderr, "ERROR: could not open data file: %s\n", argv[2]);
            return 1;
        }
    } else {
        data_fd = -1;
    }

    //VataAddr vata_addrs = args2vata_addr(argc, argv, &err);
    if (err != 0) {
        printf_args2vata_err(err);
        return 1;
    }

    u32 *pfifo[2];

    pfifo[0] = mmap_vata_fifo(&axi_fd, VATA_ADDRS[0]);
    if (pfifo[0] == NULL) {
        fprintf(stderr, "ERROR: could not mmap vata 0 fifo.\n");
        return 1;
    }
    pfifo[1] = mmap_vata_fifo(&axi_fd, VATA_ADDRS[1]);
    if (pfifo[1] == NULL) {
        fprintf(stderr, "ERROR: could not mmap vata 1 fifo.\n");
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

    printf("Client connected.\n");

    signal(SIGINT, int_handle);
    /* 
     * sendto: echo the input back to the client 
     */
    u32 isr, rlr, rdfo, asic1_offset, j, k;
    int i, nsend, reset_required;
    u32 data_buf[NDATA_BUF];

    //u64 *time_usec = (u64 *)(data_buf+1);
    u64 time_usec;

    pfifo[0][0] = 0xFFFFFFFF;
    pfifo[0][1] = 0xFFFFFFFF;

    struct timeval now;

    while (keep_running == 1) {
        //isr = pfifo[0];
        //pfifo[0] = 0xFFFFFFFF;
        rdfo = pfifo[0][XLLF_RDFO_OFFSET/4];
        if (rdfo > 0) {
            reset_required = 0;
            rlr = pfifo[0][XLLF_RLF_OFFSET/4]/4;
            if (rlr != N_ASIC_PACKET) {
                printf("ASIC0: read length = %u (!= %d)\n", rlr, N_ASIC_PACKET);
                reset_required = 1;
            }
            for (j=0; j < rlr && (1+N_VATA+j < NDATA_BUF); j++) {
                data_buf[OFFSET0+N_VATA+j] = pfifo[0][XLLF_RDFD_OFFSET/4]; 
            }
            data_buf[OFFSET0] = j;
            asic1_offset = OFFSET0 + N_VATA + j;
            // Wait for data in second FIFO:
            for (i=0; i<FIFO_NCHECK_TIMEOUT && pfifo[1][XLLF_RDFO_OFFSET/4]==0; i++) {
                usleep(100);
            }
            rlr = pfifo[1][XLLF_RLF_OFFSET/4]/4;
            if (rlr != N_ASIC_PACKET) {
                printf("ASIC1: read length = %u (!= %d)\n", rlr, N_ASIC_PACKET);
                reset_required = 1;
            }
            for (k=0; k<rlr && k+asic1_offset<NDATA_BUF; k++) {
                data_buf[k+asic1_offset] = pfifo[1][XLLF_RDFD_OFFSET/4];
            }
            data_buf[OFFSET0+1] = k;
            data_buf[0] = OFFSET0 + N_VATA + data_buf[OFFSET0] + data_buf[OFFSET0+1];
            gettimeofday(&now, NULL);
            time_usec = (u64)now.tv_sec*1000000 + (u64)now.tv_usec;
            data_buf[1] = (u32)(time_usec & 0xFFFFFFFF);
            data_buf[2] = (u32)((time_usec >> 32) & 0xFFFFFFFF);
            printf("TIME: %lu (%lu)\n", time_usec, now.tv_sec*1000000 + now.tv_usec);
            printf("data_buf[0] = %u\n", data_buf[0]);
            printf("ndata0, ndat1 = %u %u\n", data_buf[OFFSET0], data_buf[OFFSET0+1]);
            if (data_fd >= 0) {
                write(data_fd, (void *)data_buf, data_buf[0]*sizeof(u32));
            }
            n = sendto(sockfd, data_buf, data_buf[0]*sizeof(u32), 0,
                       (struct sockaddr *)&clientaddr, clientlen);
            printf("sent: %d\n", n);
            if (reset_required == 1) {
                // Reset both FIFO's
                // Seems safer to reset both if either have issue.
                pfifo[0][XLLF_RDFR_OFFSET/4] = XLLF_RDFR_RESET_MASK;
                pfifo[1][XLLF_RDFR_OFFSET/4] = XLLF_RDFR_RESET_MASK;
            }
            //printf("Sent %d bytes to client\n", n);
        } else {
            usleep(10000); // Sleep for 10 ms
        }
    }

    if (data_fd >= 0) {
        close(data_fd);
    }

    int ret = 0;
    if (unmmap_vata_fifo(pfifo[0], VATA_ADDRS[0]) != 0) {
        printf("ERROR: munmap() failed on FIFO 0\n");
        ret = 1;
    }
    if (unmmap_vata_fifo(pfifo[1], VATA_ADDRS[1]) != 0) {
        printf("ERROR: munmap() failed on FIFO 1\n");
        ret = 1;
    }

    close(axi_fd);
    return ret;
}
// vim: set ts=4 sw=4 sts=4 et:
