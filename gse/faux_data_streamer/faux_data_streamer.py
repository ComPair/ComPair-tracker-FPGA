import time
import zmq
import silayer
import sys



if __name__ == "__main__":

    '''
    This is an extrel
    '''


    if len(sys.argv) != 3:
        print(f"Usage: python {sys.argv[0]} <path to data file to send> <rate>")
        exit(0)
       

    context = zmq.Context()
    socket = context.socket(zmq.PUB)
    socket.setsockopt(zmq.LINGER, 1)
    socket.bind('tcp://*:9998')

    print("Binded to socket. Running")

    faux_data_iterator = silayer.raw2hdf.lame_byte_iterator(sys.argv[1])

    t0 = time.time()
    i = 0
    rate = float(sys.argv[2]) #Hz
    try:
        while True:
            tnow = time.time()
            deltaT = tnow- t0
            
            if deltaT > 1. / rate:
                
                i+=1

                instant_rate = 1. / (deltaT)
                if i%rate == 0 and i > 0:
                    print(f"DeltaT: {deltaT:f} -- Rate: {instant_rate:.3f} Hz -- Pakcets sent: {i:g}")
                socket.send(next(faux_data_iterator), flags=zmq.NOBLOCK, copy=False)
                
                t0 = tnow
    except KeyboardInterrupt:
        print("Exiting...")
        socket.close()
        exit()
            	


