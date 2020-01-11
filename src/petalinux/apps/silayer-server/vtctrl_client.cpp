#include <zmq.hpp>
#include <string>
#include <iostream>

int main () {
    zmq::context_t context(1);
    zmq::socket_t socket (context, ZMQ_REQ);

    std::cout << "Connecting to vtctrl_server..." << std::endl;
    socket.connect("tcp://localhost:5555");
    const char msg[] =
        "0 set-config /home/root/configs/test-cal-vthr20-iramp10.dat";

    // 10 requests...
    //for (int n=0; n < 10; n++) {
        zmq::message_t request (sizeof(msg));
        std::memcpy(request.data(), msg, sizeof(msg));
        std::cout << "Sending: " << msg << std::endl;
        socket.send(request);

        zmq::message_t reply;
        socket.recv(&reply);

        std::string msg_recv(' ', reply.size());
        std::memcpy((void *)msg_recv.data(), reply.data(), reply.size());
        std::cout << "received: " << msg_recv << std::endl;
    //}

}
// vim: set ts=4 sw=4 sts=4 et:
