#!/usr/bin/env python 

import time
import zmq
import silayer
import sys
from datetime import timedelta

from timeloop import Timeloop

tl = Timeloop()



if __name__ == "__main__":

    if len(sys.argv) != 3:
        print(f"Usage: python {sys.argv[0]} <packet rate in Hz> <path to data file to send>")
        exit(0)
       
    faux_data_iterator = silayer.raw2hdf.lame_byte_iterator(sys.argv[2])
    nominal_rate = float(sys.argv[1])

    context = zmq.Context()
    socket = context.socket(zmq.PUB)
    socket.setsockopt(zmq.LINGER, 1)

    socket.bind('tcp://*:9998')

    print("Binded to socket. Running")

    # faux_data_iterator = silayer.raw2hdf.lame_byte_iterator(sys.argv[1])

    # t0 = time.time()
    # i = 0

    # try:
    #     while True:
    #         tnow = time.time()
    #         deltaT = tnow- t0
            
    #         if deltaT > 1. / nominal_rate:
                
    #             i+=1

    #             instant_rate = 1. / (deltaT)
    #             if i%rate == 0 and i > 0:
    #                 print(f"DeltaT: {deltaT:f} -- Rate: {instant_rate:.3f} Hz -- Pakcets sent: {i:g}")
    #             socket.send(next(faux_data_iterator), flags=zmq.NOBLOCK, copy=False)
                
    #             t0 = tnow
    # except KeyboardInterrupt:
    #     print("Exiting...")
    #     socket.close()
    #     exit()
            	

# =======
#     socket.bind("tcp://*:9998")    

    t0 = time.time()
    i = 0

    @tl.job(interval=timedelta(seconds=1./nominal_rate))
    def send_packet():
        global i, t0
    
        test_data = next(faux_data_iterator)
    
        i += 1
    
        tnow = time.time()
    
        if i % 10 == 0 and i > 0:
            deltaT = tnow - t0
            rate = 1.0 / (deltaT)
            print(f"DeltaT: {deltaT:.3f} -- Rate: {rate:.2f} Hz -- Nbytes: {len(test_data)}")
    
        socket.send(test_data, flags=zmq.NOBLOCK, copy=False)
    
        t0 = tnow
    
    tl.start()
    while True:
        try:
            time.sleep(1)
        except KeyboardInterrupt:
            tl.stop()
            break
