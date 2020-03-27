import time
import zmq
import silayer
import sys

if __name__ == "__main__":

    if len(sys.argv) != 2:
        print(f"Usage: python {sys.argv[0]} <path to data file to send> <rate>")
        exit(0)
       

    context = zmq.Context()
    socket = context.socket(zmq.PUB)
    socket.setsockopt(zmq.LINGER, 1)
    socket.bind('tcp://*:9998')



    faux_data_iterator = silayer.raw2hdf.lame_byte_iterator(sys.argv[1])

    t0 = time.time()
    i = 0
    rate = sys.arvg[2] #Hz
    while True:
        tnow = time.time()
        deltaT = tnow- t0
        
        if deltaT > 1. / rate:
            
            i+=1

            rate = 1. / (deltaT)
            if i%10 == 0 and i > 0:
                print(f"DeltaT: {deltaT:.2f} -- Rate: {rate:.2f} Hz")
            socket.send(next(faux_data_iterator), flags=zmq.NOBLOCK, copy=False)
            
            t0 = tnow

        	


