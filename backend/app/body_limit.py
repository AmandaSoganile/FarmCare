from uuid import uuid4

from starlette.responses import JSONResponse


class BodyLimit:
    """Bound JSON request buffering, including requests using chunked encoding."""
    def __init__(self, app, maximum=1048576):
        self.app, self.maximum = app, maximum

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            return await self.app(scope, receive, send)
        parts, size = [], 0
        while True:
            message = await receive()
            if message["type"] == "http.disconnect":
                return
            size += len(message.get("body", b""))
            if size > self.maximum:
                request_id = str(uuid4())
                response = JSONResponse({"error": {"code": "PAYLOAD_TOO_LARGE", "message": "Request is too large.",
                                        "request_id": request_id}}, status_code=413,
                                        headers={"X-Request-ID": request_id, "Cache-Control": "no-store"})
                return await response(scope, receive, send)
            parts.append(message)
            if not message.get("more_body", False):
                break
        index = 0

        async def replay():
            nonlocal index
            if index < len(parts):
                message = parts[index]
                index += 1
                return message
            return await receive()

        return await self.app(scope, replay, send)
