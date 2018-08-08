ltm rule /Common/http_test {
when HTTP_REQUEST {
    HTTP::respond 200 content "<html><p>Works!</p></html>"
    event disable
    TCP::close
}
}
