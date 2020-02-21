#
#   Hello World server in Python
#   Binds REP socket to tcp://*:5555
#   Expects b"Hello" from client, replies with b"World"
#

import time
import zmq

context = zmq.Context()
socket = context.socket(zmq.REP)
socket.bind("tcp://*:5555")

start_keyword = "GO"

while True:
    #  Wait for next request from client
    message = socket.recv()
    print("Received request: %s" % message)

    if message == start_keyword:

	    #  Do some 'work'
	    time.sleep(1)

	    #  Send reply back to client
	    socket.send(b"World")

	
		