import { IncomingHttpHeaders, ServerHttp2Stream, constants as HTTP_CONST } from 'http2';
import type {promises as FsPromises} from 'fs';
/** HTTP constants */
const {
	HTTP2_HEADER_METHOD,
	HTTP2_HEADER_PATH,
	HTTP2_HEADER_SCHEME,
	HTTP2_HEADER_CONTENT_TYPE
}= HTTP_CONST;

//* Types
type VoidCallback= (...args: any[])=> void

/**
 * Context file
 */
class Context{
	// Unlerlining Http2Stream
	readonly stream: ServerHttp2Stream;
	/** Incomming headers */
	readonly headers: IncomingHttpHeaders;
	readonly flags: number
	/** Incomming raw headers */
	readonly rawHeaders: string[];

	constructor(stream: ServerHttp2Stream, headers: IncomingHttpHeaders, flags: number, rawHeaders: string[]){
		this.stream= stream;
		this.headers= headers;
		this.flags= flags;
		this.rawHeaders= rawHeaders;
	}

	/** If the stream aborted */
	get aborted(){ return this.stream.aborted }
	/** If stream closed */
	get closed(){ return this.stream.closed }
	/** If desctroyed */
	get destroyed(){ return this.stream.destroyed }
	/** If headers sent */
	get headersSent(){ return this.stream.headersSent }
	/** Get stream id */
	get id(){ return this.stream.id; }

	/** Get Method */
	get method(){ return this.headers[HTTP2_HEADER_METHOD] }
	get path(){ return this.headers[HTTP2_HEADER_PATH] }
	get scheme(){ return this.headers[HTTP2_HEADER_SCHEME] }
	get contentType(){ return this.headers[HTTP2_HEADER_CONTENT_TYPE]}
	
	/** HTTP version */
	get httpVersion(){ return '2.0' }

	/** Sent header: outbound headers */
	get sentHeaders(){ return this.stream.sentHeaders; }


	/** Close stream */
	close(code?: number){
		this.stream.close(code);
		return this;
	}

	/** Stream timeout */
	setTimeout(msecs: number, callback?: VoidCallback){ this.stream.setTimeout(msecs, callback); }

	
	/** Listeners on stream */
	on(event: string|symbol, listener: VoidCallback): this{
		this.stream.on(event, listener);
		return this;
	}
	/** Listen once */
	once(event: string|symbol, listener: VoidCallback): this{
		this.stream.once(event, listener);
		return this;
	}
	/** Emit event */
	emit(event: string | symbol, ...args: any[]): boolean{
		return this.stream.emit(event, ...args);
	}
	/** Await for event once */
	awaitOnce(event: string|symbol){
		return new Promise((res, rej)=>{
			this.stream.once(event, res);
		});
	}

	/** Send file to client */
	async sendFile(fd: number|FsPromises.FileHandle): Promise<void>;
	async sendFile(buffer: Buffer): Promise<void>;
	async sendFile(path: string): Promise<void>;
	async sendFile(): Promise<void>{
		//TODO
	}

	/** Send data to the client */
	async send(data: string): Promise<void>;
	async send(data: Buffer): Promise<void>;
	async send(data: any): Promise<void>;
	async send(data: any): Promise<void>{
		
	}
}