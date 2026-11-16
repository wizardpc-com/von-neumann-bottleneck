# Existing server Python 3.9 timeout boundary

The required Python receiver/community checks were executed with local Python
3.9.6. Receiver: 7 tests, 2 failures. Community: 16 tests, 4 failures (including
inherited receiver cases). Both slow-body tests expected HTTP 400 and received EOF.
Logs are retained verbatim in logs/test_receiver.txt and test_community.txt.

On Python 3.9, socket.timeout subclasses OSError, not TimeoutError. The existing
server catches TimeoutError for total/read timeouts; socket.timeout instead reaches
BaseHTTPRequestHandler.handle_one_request, which closes the connection. The deadline
still stops the request, but the promised HTTP status contract is not satisfied.
server/README.md advertises Python 3.9+; CI uses 3.12. This is an existing supported-
version issue, not an unsupported-runner excuse. No newer local interpreter found.

The original failing server files were byte-identical to baseline 8105b92. Offline edition exports
exclude server code, contain no receiver endpoint and require no network. This task
does not deploy the server. A bounded compatibility correction now catches both
TimeoutError and socket.timeout at the existing request boundaries, preserving all
limits, deadlines, data and HTTP status semantics. Existing Receiver 7/7 and
Community 16/16 tests now pass on Python3.9; final logs are
logs/python39-fixed-receiver.txt and logs/python39-fixed-community.txt. Original
failures remain for attribution. Storage/delivery/private-report checks also pass.
