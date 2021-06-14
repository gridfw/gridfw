/// <reference path="files.ts" />
import { constants as HTTP_CONST } from 'http2';
/** HTTP constants */
const { HTTP2_HEADER_METHOD, HTTP2_HEADER_PATH, HTTP2_HEADER_SCHEME, HTTP2_HEADER_CONTENT_TYPE } = HTTP_CONST;
/**
 * Context file
 */
class Context {
    constructor(stream, headers, flags, rawHeaders) {
        this.stream = stream;
        this.headers = headers;
        this.flags = flags;
        this.rawHeaders = rawHeaders;
    }
    /** If the stream aborted */
    get aborted() { return this.stream.aborted; }
    /** If stream closed */
    get closed() { return this.stream.closed; }
    /** If desctroyed */
    get destroyed() { return this.stream.destroyed; }
    /** If headers sent */
    get headersSent() { return this.stream.headersSent; }
    /** Get stream id */
    get id() { return this.stream.id; }
    /** Get Method */
    get method() { return this.headers[HTTP2_HEADER_METHOD]; }
    get path() { return this.headers[HTTP2_HEADER_PATH]; }
    get scheme() { return this.headers[HTTP2_HEADER_SCHEME]; }
    get contentType() { return this.headers[HTTP2_HEADER_CONTENT_TYPE]; }
    /** Sent header: outbound headers */
    get sentHeaders() { return this.stream.sentHeaders; }
    /** Close stream */
    close(code) {
        this.stream.close(code);
        return this;
    }
    /** Stream timeout */
    setTimeout(msecs, callback) { this.stream.setTimeout(msecs, callback); }
    /** Listeners on stream */
    on(event, listener) {
        this.stream.on(event, listener);
        return this;
    }
    /** Listen once */
    once(event, listener) {
        this.stream.once(event, listener);
        return this;
    }
    /** Emit event */
    emit(event, ...args) {
        return this.stream.emit(event, ...args);
    }
    /** Await for event once */
    awaitOnce(event) {
        return new Promise((res, rej) => {
            this.stream.once(event, res);
        });
    }
}

//# sourceMappingURL=index.js.map
