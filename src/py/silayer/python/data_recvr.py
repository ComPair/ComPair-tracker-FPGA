#!/usr/bin/env python3
import multiprocessing as mp
import zmq

def data_recv_loop(ctrl_socket, data_socket, data_file):
    poller = zmq.Poller()
    poller.register(ctrl_socket, zmq.POLLIN)
    poller.register(data_socket, zmq.POLLIN)
    while True:
        socks = dict(poller.poll())
        if data_socket in socks:
            data_file.write(data_socket.recv())
        if ctrl_socket in socks:
            msg = ctrl_socket.recv().decode()
            if msg == "stop":
                ctrl_socket.send(b"ok")
                break

def main(ctrl_port, host="si-layer.local", data_port=9998):
    ctx = zmq.Context()
    ctrl_socket = ctx.socket(zmq.REP)
    ctrl_socket.connect(f"tcp://localhost:{ctrl_port}")
    data_addr = f"tcp://{host}:{data_port}"
    while True:
        msg = ctrl_socket.recv().decode()
        if msg.startswith("start"):
            fname = msg.split(" ")[-1]
            data_socket = ctx.socket(zmq.SUB)
            data_socket.setsockopt_string(zmq.SUBSCRIBE, "")
            data_socket.connect(data_addr)
            ctrl_socket.send(b"ok")
            with open(fname, "wb", 0) as f:
                data_recv_loop(ctrl_socket, data_socket, f)
        elif msg == "exit":
            ctrl_socket.send(b"ok")
            break

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description="Run the data receiver")
    parser.add_argument("port", type=int, help="Port number to use for command socket")
    parser.add_argument("--host", type=str, default="si-layer.local", help="Silicon layer host name")
    parser.add_argument("--data-port", type=int, dest="dport", default=9998, help="Port number to use for data socket")
    args = parser.parse_args()

    main(args.port, host=args.host, data_port=args.dhost)

