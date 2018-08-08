ltm rule /Common/http_response_time {
when HTTP_REQUEST {
            set req_rcv_ms [clock clicks -milliseconds]
            set req_uri [HTTP::uri]
    }
    when HTTP_RESPONSE {
            log local0. "$req_uri required [expr {[clock clicks -milliseconds] - $req_rcv_ms}] ms"
            unset req-rcv_ms req_uri
    }
}
