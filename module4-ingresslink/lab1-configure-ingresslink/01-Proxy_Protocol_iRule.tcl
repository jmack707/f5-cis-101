# PROXY Protocol Receiver iRule  (name on BIG-IP: Proxy_Protocol_iRule)
# Used by F5 IngressLink. Layer 4 - BIG-IP is pass-through; it prepends the
# PROXY header so NGINX can recover the original client IP (X-Real-IP).
# Create under Local Traffic > iRules with this exact name (the IngressLink
# resource references /Common/Proxy_Protocol_iRule).

when CLIENT_ACCEPTED {
    set proxyheader "PROXY "
    if {[IP::version] eq 4} {
        append proxyheader "TCP4 "
    } else {
        append proxyheader "TCP6 "
    }
    append proxyheader "[IP::remote_addr] [IP::local_addr] [TCP::remote_port] [TCP::local_port]\r\n"
}

when SERVER_CONNECTED {
    TCP::respond $proxyheader
}
