#!/usr/bin/env python3
import zmq

def main():
    context = zmq.Context()
    socket = context.socket(zmq.REQ)
    socket.connect("tcp://localhost:5555")
    msg = "0 set-config /home/root/configs/test-cal-vthr20-iramp10.dat"
    print("sending: %s" % msg)
    socket.send(msg.encode())
    recv = socket.recv()
    print("Received: %s" % recv.decode())


##import socket
##
##def main():
##    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM);
##    s.connect(('localhost', 5555))
##    msg = "0 set-config /home/root/configs/test-cal-vthr20-iramp10.dat"
##    print("sending: %s" % msg)
##    sent = s.send(msg.encode())
##    print("Send %d bytes" % sent)
##    recv = s.recv(1024)
##    print("Received: %s" % (recv.decode(errors="ignore")))
##

if __name__ == '__main__':
    main()
