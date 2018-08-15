ltm rule /Common/ssl_debugging {
    when CLIENTSSL_HANDSHAKE {
        HSL::send [HSL::open -proto UDP -pool hsl_endpoint] "<191> Client [IP::client_addr] negotiated [SSL::cipher version] [SSL::cipher name]"
    }
}

