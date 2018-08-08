ltm rule /Common/tcp_stream_stats {
when CLIENT_CLOSED {
        log local0. "Connection from [IP::remote_addr]:[TCP::remote_port] closed. [IP::stats bytes in] bytes in, [IP::stats bytes out] bytes out, [IP::stats pkts in] pkts in, [IP::stats pkts out] pkts out."
    }
}
