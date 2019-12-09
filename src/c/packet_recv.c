#include <stdio.h> 
#include <stdlib.h> 
#include <unistd.h> 
#include <string.h> 
#include <signal.h>
#include <sys/types.h> 
#include <sys/socket.h> 
#include <arpa/inet.h> 
#include <netinet/in.h> 
  
#define SERVER   "192.168.1.11"
#define PORT     5000 
#define NDATA    256

#define DEFAULT_DATA_FILE "data.hex"
  
static volatile int keep_running = 1;
void int_handle(int dummy) {
    keep_running = 0;
}

int main(int argc, char **argv) { 

    FILE *data_fp;
    if (argc == 1) {
        if ( (data_fp = fopen(DEFAULT_DATA_FILE, "a")) == NULL ) {
            printf("ERROR: could not open data file: %s.\n", DEFAULT_DATA_FILE);
            return 1;
        }
    } else if (argc == 2) {
        if ( (data_fp = fopen(argv[1], "a")) == NULL ) {
            printf("ERROR: could not open data file: %s.\n", argv[1]);
            return 1;
        }
    } else {
        printf("Usage: packet_recv [DATAFILE]\n");
        return 1;
    }

    signal(SIGINT, int_handle);

    int sockfd; 
    int buflen = NDATA * 4; // 4 is size of u32 in bytes
    char buffer[buflen]; 

    struct sockaddr_in servaddr, cliaddr; 
      
    // Creating socket file descriptor 
    if ( (sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0 ) { 
        perror("socket creation failed"); 
        exit(EXIT_FAILURE); 
    } 
      
    memset(&servaddr, 0, sizeof(servaddr)); 
    memset(&cliaddr, 0, sizeof(cliaddr)); 
      
    // Filling server information 
    servaddr.sin_family    = AF_INET; // IPv4 
    servaddr.sin_port = htons(PORT); 
    //servaddr.sin_addr.s_addr = INADDR_ANY; 
    if (inet_aton(SERVER, &servaddr.sin_addr) == 0) {
        perror("Invalid address.\n");
        exit(EXIT_FAILURE);
    }
      
    // Bind the socket with the server address 
    if ( bind(sockfd, (const struct sockaddr *)&servaddr,  
              sizeof(servaddr) ) < 0 ) { 
        perror("bind failed"); 
        exit(EXIT_FAILURE); 
    } 
      
    int len, n, i; 
    while (keep_running == 1) {
        n = recvfrom(sockfd, (char *)buffer, buflen,  
                     MSG_WAITALL, ( struct sockaddr *) &cliaddr, 
                     &len); 
        for (i=0; i<n; i++) {
            fprintf(data_fp, "%02x", buffer[i]);
        }
        fprintf(data_fp, "\n");
    }
     
    return 0; 
}
// vim: set ts=4 sw=4 sts=4 et:
