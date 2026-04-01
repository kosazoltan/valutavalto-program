const require_chunk = require("./chunk-DyKKrNZQ.js");
//#region node_modules/@serialport/parser-byte-length/dist/index.js
var require_dist$16 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.ByteLengthParser = void 0;
	var stream_1$11 = require("stream");
	/**
	* Emit data every number of bytes
	*
	* A transform stream that emits data as a buffer after a specific number of bytes are received. Runs in O(n) time.
	*/
	var ByteLengthParser = class extends stream_1$11.Transform {
		length;
		position;
		buffer;
		constructor(options) {
			super(options);
			if (typeof options.length !== "number") throw new TypeError("\"length\" is not a number");
			if (options.length < 1) throw new TypeError("\"length\" is not greater than 0");
			this.length = options.length;
			this.position = 0;
			this.buffer = Buffer.alloc(this.length);
		}
		_transform(chunk, _encoding, cb) {
			let cursor = 0;
			while (cursor < chunk.length) {
				this.buffer[this.position] = chunk[cursor];
				cursor++;
				this.position++;
				if (this.position === this.length) {
					this.push(this.buffer);
					this.buffer = Buffer.alloc(this.length);
					this.position = 0;
				}
			}
			cb();
		}
		_flush(cb) {
			this.push(this.buffer.slice(0, this.position));
			this.buffer = Buffer.alloc(this.length);
			cb();
		}
	};
	exports.ByteLengthParser = ByteLengthParser;
}));
//#endregion
//#region node_modules/@serialport/parser-cctalk/dist/index.js
var require_dist$15 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.CCTalkParser = void 0;
	var stream_1$10 = require("stream");
	/**
	* Parse the CCTalk protocol
	* @extends Transform
	*
	* A transform stream that emits CCTalk packets as they are received.
	*/
	var CCTalkParser = class extends stream_1$10.Transform {
		array;
		cursor;
		lastByteFetchTime;
		maxDelayBetweenBytesMs;
		constructor(maxDelayBetweenBytesMs = 50) {
			super();
			this.array = [];
			this.cursor = 0;
			this.lastByteFetchTime = 0;
			this.maxDelayBetweenBytesMs = maxDelayBetweenBytesMs;
		}
		_transform(buffer, encoding, cb) {
			if (this.maxDelayBetweenBytesMs > 0) {
				const now = Date.now();
				if (now - this.lastByteFetchTime > this.maxDelayBetweenBytesMs) {
					this.array = [];
					this.cursor = 0;
				}
				this.lastByteFetchTime = now;
			}
			this.cursor += buffer.length;
			Array.from(buffer).map((byte) => this.array.push(byte));
			while (this.cursor > 1 && this.cursor >= this.array[1] + 5) {
				const FullMsgLength = this.array[1] + 5;
				const frame = Buffer.from(this.array.slice(0, FullMsgLength));
				this.array = this.array.slice(frame.length, this.array.length);
				this.cursor -= FullMsgLength;
				this.push(frame);
			}
			cb();
		}
	};
	exports.CCTalkParser = CCTalkParser;
}));
//#endregion
//#region node_modules/@serialport/parser-delimiter/dist/index.js
var require_dist$14 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.DelimiterParser = void 0;
	var stream_1$9 = require("stream");
	/**
	* A transform stream that emits data each time a byte sequence is received.
	* @extends Transform
	*
	* To use the `Delimiter` parser, provide a delimiter as a string, buffer, or array of bytes. Runs in O(n) time.
	*/
	var DelimiterParser = class extends stream_1$9.Transform {
		includeDelimiter;
		delimiter;
		buffer;
		constructor({ delimiter, includeDelimiter = false, ...options }) {
			super(options);
			if (delimiter === void 0) throw new TypeError("\"delimiter\" is not a bufferable object");
			if (delimiter.length === 0) throw new TypeError("\"delimiter\" has a 0 or undefined length");
			this.includeDelimiter = includeDelimiter;
			this.delimiter = Buffer.from(delimiter);
			this.buffer = Buffer.alloc(0);
		}
		_transform(chunk, encoding, cb) {
			let data = Buffer.concat([this.buffer, chunk]);
			let position;
			while ((position = data.indexOf(this.delimiter)) !== -1) {
				this.push(data.slice(0, position + (this.includeDelimiter ? this.delimiter.length : 0)));
				data = data.slice(position + this.delimiter.length);
			}
			this.buffer = data;
			cb();
		}
		_flush(cb) {
			this.push(this.buffer);
			this.buffer = Buffer.alloc(0);
			cb();
		}
	};
	exports.DelimiterParser = DelimiterParser;
}));
//#endregion
//#region node_modules/@serialport/parser-inter-byte-timeout/dist/index.js
var require_dist$13 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.InterByteTimeoutParser = void 0;
	var stream_1$8 = require("stream");
	/**
	* A transform stream that buffers data and emits it after not receiving any bytes for the specified amount of time or hitting a max buffer size.
	*/
	var InterByteTimeoutParser = class extends stream_1$8.Transform {
		maxBufferSize;
		currentPacket;
		interval;
		intervalID;
		constructor({ maxBufferSize = 65536, interval, ...transformOptions }) {
			super(transformOptions);
			if (!interval) throw new TypeError("\"interval\" is required");
			if (typeof interval !== "number" || Number.isNaN(interval)) throw new TypeError("\"interval\" is not a number");
			if (interval < 1) throw new TypeError("\"interval\" is not greater than 0");
			if (typeof maxBufferSize !== "number" || Number.isNaN(maxBufferSize)) throw new TypeError("\"maxBufferSize\" is not a number");
			if (maxBufferSize < 1) throw new TypeError("\"maxBufferSize\" is not greater than 0");
			this.maxBufferSize = maxBufferSize;
			this.currentPacket = [];
			this.interval = interval;
		}
		_transform(chunk, encoding, cb) {
			if (this.intervalID) clearTimeout(this.intervalID);
			for (let offset = 0; offset < chunk.length; offset++) {
				this.currentPacket.push(chunk[offset]);
				if (this.currentPacket.length >= this.maxBufferSize) this.emitPacket();
			}
			this.intervalID = setTimeout(this.emitPacket.bind(this), this.interval);
			cb();
		}
		emitPacket() {
			if (this.intervalID) clearTimeout(this.intervalID);
			if (this.currentPacket.length > 0) this.push(Buffer.from(this.currentPacket));
			this.currentPacket = [];
		}
		_flush(cb) {
			this.emitPacket();
			cb();
		}
	};
	exports.InterByteTimeoutParser = InterByteTimeoutParser;
}));
//#endregion
//#region node_modules/@serialport/parser-packet-length/dist/index.js
var require_dist$12 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.PacketLengthParser = void 0;
	var stream_1$7 = require("stream");
	/**
	* A transform stream that decodes packets with a delimiter and length of payload
	* specified within the data stream.
	* @extends Transform
	* @summary Decodes packets of the general form:
	*       [delimiter][len][payload0] ... [payload0 + len]
	*
	* The length field can be up to 4 bytes and can be at any offset within the packet
	*       [delimiter][header0][header1][len0][len1[payload0] ... [payload0 + len]
	*
	* The offset and number of bytes of the length field need to be provided in options
	* if not 1 byte immediately following the delimiter.
	*/
	var PacketLengthParser = class extends stream_1$7.Transform {
		buffer;
		start;
		opts;
		constructor(options = {}) {
			super(options);
			const { delimiter = [170], delimiterBytes = 1, packetOverhead = 2, lengthBytes = 1, lengthOffset = 1, maxLen = 255 } = options;
			this.opts = {
				delimiter: [].concat(delimiter),
				delimiterBytes,
				packetOverhead,
				lengthBytes,
				lengthOffset,
				maxLen
			};
			this.buffer = Buffer.alloc(0);
			this.start = false;
		}
		_transform(chunk, encoding, cb) {
			for (let ndx = 0; ndx < chunk.length; ndx++) {
				const byte = chunk[ndx];
				if (true === this.start) {
					this.buffer = Buffer.concat([this.buffer, Buffer.from([byte])]);
					if (this.buffer.length >= this.opts.lengthOffset + this.opts.lengthBytes) {
						const len = this.buffer.readUIntLE(this.opts.lengthOffset, this.opts.lengthBytes);
						if (this.buffer.length == len + this.opts.packetOverhead || len > this.opts.maxLen) {
							this.push(this.buffer);
							this.buffer = Buffer.alloc(0);
							this.start = false;
						}
					}
				} else {
					this.buffer = Buffer.concat([Buffer.from([byte]), this.buffer]);
					if (this.buffer.length === this.opts.delimiterBytes) {
						const delimiter = this.buffer.readUIntLE(0, this.opts.delimiterBytes);
						if (this.opts.delimiter.includes(delimiter)) {
							this.start = true;
							this.buffer = Buffer.from([...this.buffer].reverse());
						} else this.buffer = Buffer.from(this.buffer.subarray(1, this.buffer.length));
					}
				}
			}
			cb();
		}
		_flush(cb) {
			this.push(this.buffer);
			this.buffer = Buffer.alloc(0);
			cb();
		}
	};
	exports.PacketLengthParser = PacketLengthParser;
}));
//#endregion
//#region node_modules/@serialport/parser-readline/dist/index.js
var require_dist$11 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.ReadlineParser = void 0;
	var parser_delimiter_1 = require_dist$14();
	/**
	*  A transform stream that emits data after a newline delimiter is received.
	* @summary To use the `Readline` parser, provide a delimiter (defaults to `\n`). Data is emitted as string controllable by the `encoding` option (defaults to `utf8`).
	*/
	var ReadlineParser = class extends parser_delimiter_1.DelimiterParser {
		constructor(options) {
			const opts = {
				delimiter: Buffer.from("\n", "utf8"),
				encoding: "utf8",
				...options
			};
			if (typeof opts.delimiter === "string") opts.delimiter = Buffer.from(opts.delimiter, opts.encoding);
			super(opts);
		}
	};
	exports.ReadlineParser = ReadlineParser;
}));
//#endregion
//#region node_modules/@serialport/parser-ready/dist/index.js
var require_dist$10 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.ReadyParser = void 0;
	var stream_1$6 = require("stream");
	/**
	* A transform stream that waits for a sequence of "ready" bytes before emitting a ready event and emitting data events
	*
	* To use the `Ready` parser provide a byte start sequence. After the bytes have been received a ready event is fired and data events are passed through.
	*/
	var ReadyParser = class extends stream_1$6.Transform {
		delimiter;
		readOffset;
		ready;
		constructor({ delimiter, ...options }) {
			if (delimiter === void 0) throw new TypeError("\"delimiter\" is not a bufferable object");
			if (delimiter.length === 0) throw new TypeError("\"delimiter\" has a 0 or undefined length");
			super(options);
			this.delimiter = Buffer.from(delimiter);
			this.readOffset = 0;
			this.ready = false;
		}
		_transform(chunk, encoding, cb) {
			if (this.ready) {
				this.push(chunk);
				return cb();
			}
			const delimiter = this.delimiter;
			let chunkOffset = 0;
			while (this.readOffset < delimiter.length && chunkOffset < chunk.length) {
				if (delimiter[this.readOffset] === chunk[chunkOffset]) this.readOffset++;
				else this.readOffset = 0;
				chunkOffset++;
			}
			if (this.readOffset === delimiter.length) {
				this.ready = true;
				this.emit("ready");
				const chunkRest = chunk.slice(chunkOffset);
				if (chunkRest.length > 0) this.push(chunkRest);
			}
			cb();
		}
	};
	exports.ReadyParser = ReadyParser;
}));
//#endregion
//#region node_modules/@serialport/parser-regex/dist/index.js
var require_dist$9 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.RegexParser = void 0;
	var stream_1$5 = require("stream");
	/**
	* A transform stream that uses a regular expression to split the incoming text upon.
	*
	* To use the `Regex` parser provide a regular expression to split the incoming text upon. Data is emitted as string controllable by the `encoding` option (defaults to `utf8`).
	*/
	var RegexParser = class extends stream_1$5.Transform {
		regex;
		data;
		constructor({ regex, ...options }) {
			const opts = {
				encoding: "utf8",
				...options
			};
			if (regex === void 0) throw new TypeError("\"options.regex\" must be a regular expression pattern or object");
			if (!(regex instanceof RegExp)) regex = new RegExp(regex.toString());
			super(opts);
			this.regex = regex;
			this.data = "";
		}
		_transform(chunk, encoding, cb) {
			const parts = (this.data + chunk).split(this.regex);
			this.data = parts.pop() || "";
			parts.forEach((part) => {
				this.push(part);
			});
			cb();
		}
		_flush(cb) {
			this.push(this.data);
			this.data = "";
			cb();
		}
	};
	exports.RegexParser = RegexParser;
}));
//#endregion
//#region node_modules/@serialport/parser-slip-encoder/dist/decoder.js
var require_decoder = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.SlipDecoder = void 0;
	var stream_1$4 = require("stream");
	/**
	* A transform stream that decodes slip encoded data.
	* @extends Transform
	*
	* Runs in O(n) time, stripping out slip encoding and emitting decoded data. Optionally custom slip escape and delimiters can be provided.
	*/
	var SlipDecoder = class extends stream_1$4.Transform {
		opts;
		buffer;
		escape;
		start;
		constructor(options = {}) {
			super(options);
			const { START, ESC = 219, END = 192, ESC_START, ESC_END = 220, ESC_ESC = 221 } = options;
			this.opts = {
				START,
				ESC,
				END,
				ESC_START,
				ESC_END,
				ESC_ESC
			};
			this.buffer = Buffer.alloc(0);
			this.escape = false;
			this.start = false;
		}
		_transform(chunk, encoding, cb) {
			for (let ndx = 0; ndx < chunk.length; ndx++) {
				let byte = chunk[ndx];
				if (byte === this.opts.START) {
					this.start = true;
					continue;
				} else if (void 0 == this.opts.START) this.start = true;
				if (this.escape) if (byte === this.opts.ESC_START && this.opts.START) byte = this.opts.START;
				else if (byte === this.opts.ESC_ESC) byte = this.opts.ESC;
				else if (byte === this.opts.ESC_END) byte = this.opts.END;
				else {
					this.escape = false;
					this.push(this.buffer);
					this.buffer = Buffer.alloc(0);
				}
				else {
					if (byte === this.opts.ESC) {
						this.escape = true;
						continue;
					}
					if (byte === this.opts.END) {
						this.push(this.buffer);
						this.buffer = Buffer.alloc(0);
						this.escape = false;
						this.start = false;
						continue;
					}
				}
				this.escape = false;
				if (this.start) this.buffer = Buffer.concat([this.buffer, Buffer.from([byte])]);
			}
			cb();
		}
		_flush(cb) {
			this.push(this.buffer);
			this.buffer = Buffer.alloc(0);
			cb();
		}
	};
	exports.SlipDecoder = SlipDecoder;
}));
//#endregion
//#region node_modules/@serialport/parser-slip-encoder/dist/encoder.js
var require_encoder = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.SlipEncoder = void 0;
	var stream_1$3 = require("stream");
	/**
	* A transform stream that emits SLIP-encoded data for each incoming packet.
	*
	* Runs in O(n) time, adding a 0xC0 character at the end of each
	* received packet and escaping characters, according to RFC 1055.
	*/
	var SlipEncoder = class extends stream_1$3.Transform {
		opts;
		constructor(options = {}) {
			super(options);
			const { START, ESC = 219, END = 192, ESC_START, ESC_END = 220, ESC_ESC = 221, bluetoothQuirk = false } = options;
			this.opts = {
				START,
				ESC,
				END,
				ESC_START,
				ESC_END,
				ESC_ESC,
				bluetoothQuirk
			};
		}
		_transform(chunk, encoding, cb) {
			const chunkLength = chunk.length;
			if (this.opts.bluetoothQuirk && chunkLength === 0) return cb();
			const encoded = Buffer.alloc(chunkLength * 2 + 2);
			let j = 0;
			if (this.opts.bluetoothQuirk == true) encoded[j++] = this.opts.END;
			if (this.opts.START !== void 0) encoded[j++] = this.opts.START;
			for (let i = 0; i < chunkLength; i++) {
				let byte = chunk[i];
				if (byte === this.opts.START && this.opts.ESC_START) {
					encoded[j++] = this.opts.ESC;
					byte = this.opts.ESC_START;
				} else if (byte === this.opts.END) {
					encoded[j++] = this.opts.ESC;
					byte = this.opts.ESC_END;
				} else if (byte === this.opts.ESC) {
					encoded[j++] = this.opts.ESC;
					byte = this.opts.ESC_ESC;
				}
				encoded[j++] = byte;
			}
			encoded[j++] = this.opts.END;
			cb(null, encoded.slice(0, j));
		}
	};
	exports.SlipEncoder = SlipEncoder;
}));
//#endregion
//#region node_modules/@serialport/parser-slip-encoder/dist/index.js
var require_dist$8 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	var __createBinding = exports && exports.__createBinding || (Object.create ? (function(o, m, k, k2) {
		if (k2 === void 0) k2 = k;
		var desc = Object.getOwnPropertyDescriptor(m, k);
		if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) desc = {
			enumerable: true,
			get: function() {
				return m[k];
			}
		};
		Object.defineProperty(o, k2, desc);
	}) : (function(o, m, k, k2) {
		if (k2 === void 0) k2 = k;
		o[k2] = m[k];
	}));
	var __exportStar = exports && exports.__exportStar || function(m, exports$3) {
		for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports$3, p)) __createBinding(exports$3, m, p);
	};
	Object.defineProperty(exports, "__esModule", { value: true });
	__exportStar(require_decoder(), exports);
	__exportStar(require_encoder(), exports);
}));
//#endregion
//#region node_modules/@serialport/parser-spacepacket/dist/utils.js
var require_utils = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.convertHeaderBufferToObj = exports.HEADER_LENGTH = void 0;
	exports.HEADER_LENGTH = 6;
	/**
	* For numbers less than 255, will ensure that their string representation is at least 8 characters long.
	*/
	var toOctetStr = (num) => {
		let str = Number(num).toString(2);
		while (str.length < 8) str = `0${str}`;
		return str;
	};
	/**
	* Converts a Buffer of any length to an Object representation of a Space Packet header, provided
	* the received data is in the correct format.
	* @param buf - The buffer containing the Space Packet Header Data
	*/
	var convertHeaderBufferToObj = (buf) => {
		const headerStr = Array.from(buf.slice(0, exports.HEADER_LENGTH)).reduce((accum, curr) => `${accum}${toOctetStr(curr)}`, "");
		const versionNumber = headerStr.slice(0, 3) === "000" ? 1 : "UNKNOWN_VERSION";
		const type = Number(headerStr[3]);
		const secondaryHeader = Number(headerStr[4]);
		const apid = parseInt(headerStr.slice(5, 16), 2);
		const sequenceFlags = parseInt(headerStr.slice(16, 18), 2);
		const packetName = parseInt(headerStr.slice(18, 32), 2);
		const dataLength = parseInt(headerStr.slice(-16), 2) + 1;
		return {
			versionNumber,
			identification: {
				apid,
				secondaryHeader,
				type
			},
			sequenceControl: {
				packetName,
				sequenceFlags
			},
			dataLength
		};
	};
	exports.convertHeaderBufferToObj = convertHeaderBufferToObj;
}));
//#endregion
//#region node_modules/@serialport/parser-spacepacket/dist/index.js
var require_dist$7 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.SpacePacketParser = void 0;
	var stream_1$2 = require("stream");
	var utils_1 = require_utils();
	/**
	* A Transform stream that accepts a stream of octet data and converts it into an object
	* representation of a CCSDS Space Packet. See https://public.ccsds.org/Pubs/133x0b2e1.pdf for a
	* description of the Space Packet format.
	*/
	var SpacePacketParser = class extends stream_1$2.Transform {
		timeCodeFieldLength;
		ancillaryDataFieldLength;
		dataBuffer;
		headerBuffer;
		dataLength;
		expectingHeader;
		dataSlice;
		header;
		/**
		* A Transform stream that accepts a stream of octet data and emits object representations of
		* CCSDS Space Packets once a packet has been completely received.
		* @param {Object} [options] Configuration options for the stream
		* @param {Number} options.timeCodeFieldLength The length of the time code field within the data
		* @param {Number} options.ancillaryDataFieldLength The length of the ancillary data field within the data
		*/
		constructor(options = {}) {
			super({
				...options,
				objectMode: true
			});
			this.timeCodeFieldLength = options.timeCodeFieldLength || 0;
			this.ancillaryDataFieldLength = options.ancillaryDataFieldLength || 0;
			this.dataSlice = this.timeCodeFieldLength + this.ancillaryDataFieldLength;
			this.dataBuffer = Buffer.alloc(0);
			this.headerBuffer = Buffer.alloc(0);
			this.dataLength = 0;
			this.expectingHeader = true;
		}
		/**
		* Bundle the header, secondary header if present, and the data into a JavaScript object to emit.
		* If more data has been received past the current packet, begin the process of parsing the next
		* packet(s).
		*/
		pushCompletedPacket() {
			if (!this.header) throw new Error("Missing header");
			const timeCode = Buffer.from(this.dataBuffer.slice(0, this.timeCodeFieldLength));
			const ancillaryData = Buffer.from(this.dataBuffer.slice(this.timeCodeFieldLength, this.timeCodeFieldLength + this.ancillaryDataFieldLength));
			const data = Buffer.from(this.dataBuffer.slice(this.dataSlice, this.dataLength));
			const completedPacket = {
				header: { ...this.header },
				data: data.toString()
			};
			if (timeCode.length > 0 || ancillaryData.length > 0) {
				completedPacket.secondaryHeader = {};
				if (timeCode.length) completedPacket.secondaryHeader.timeCode = timeCode.toString();
				if (ancillaryData.length) completedPacket.secondaryHeader.ancillaryData = ancillaryData.toString();
			}
			this.push(completedPacket);
			const nextChunk = Buffer.from(this.dataBuffer.slice(this.dataLength));
			if (nextChunk.length >= utils_1.HEADER_LENGTH) this.extractHeader(nextChunk);
			else {
				this.headerBuffer = nextChunk;
				this.dataBuffer = Buffer.alloc(0);
				this.expectingHeader = true;
				this.dataLength = 0;
				this.header = void 0;
			}
		}
		/**
		* Build the Stream's headerBuffer property from the received Buffer chunk; extract data from it
		* if it's complete. If there's more to the chunk than just the header, initiate handling the
		* packet data.
		* @param chunk -  Build the Stream's headerBuffer property from
		*/
		extractHeader(chunk) {
			const headerAsBuffer = Buffer.concat([this.headerBuffer, chunk]);
			const startOfDataBuffer = headerAsBuffer.slice(utils_1.HEADER_LENGTH);
			if (headerAsBuffer.length >= utils_1.HEADER_LENGTH) {
				this.header = (0, utils_1.convertHeaderBufferToObj)(headerAsBuffer);
				this.dataLength = this.header.dataLength;
				this.headerBuffer = Buffer.alloc(0);
				this.expectingHeader = false;
			} else this.headerBuffer = headerAsBuffer;
			if (startOfDataBuffer.length > 0) {
				this.dataBuffer = Buffer.from(startOfDataBuffer);
				if (this.dataBuffer.length >= this.dataLength) this.pushCompletedPacket();
			}
		}
		_transform(chunk, encoding, cb) {
			if (this.expectingHeader) this.extractHeader(chunk);
			else {
				this.dataBuffer = Buffer.concat([this.dataBuffer, chunk]);
				if (this.dataBuffer.length >= this.dataLength) this.pushCompletedPacket();
			}
			cb();
		}
		_flush(cb) {
			const remaining = Buffer.concat([this.headerBuffer, this.dataBuffer]);
			const remainingArray = Array.from(remaining);
			this.push(remainingArray);
			cb();
		}
	};
	exports.SpacePacketParser = SpacePacketParser;
}));
//#endregion
//#region node_modules/ms/index.js
var require_ms = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* Helpers.
	*/
	var s = 1e3;
	var m = s * 60;
	var h = m * 60;
	var d = h * 24;
	var w = d * 7;
	var y = d * 365.25;
	/**
	* Parse or format the given `val`.
	*
	* Options:
	*
	*  - `long` verbose formatting [false]
	*
	* @param {String|Number} val
	* @param {Object} [options]
	* @throws {Error} throw an error if val is not a non-empty string or a number
	* @return {String|Number}
	* @api public
	*/
	module.exports = function(val, options) {
		options = options || {};
		var type = typeof val;
		if (type === "string" && val.length > 0) return parse(val);
		else if (type === "number" && isFinite(val)) return options.long ? fmtLong(val) : fmtShort(val);
		throw new Error("val is not a non-empty string or a valid number. val=" + JSON.stringify(val));
	};
	/**
	* Parse the given `str` and return milliseconds.
	*
	* @param {String} str
	* @return {Number}
	* @api private
	*/
	function parse(str) {
		str = String(str);
		if (str.length > 100) return;
		var match = /^(-?(?:\d+)?\.?\d+) *(milliseconds?|msecs?|ms|seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h|days?|d|weeks?|w|years?|yrs?|y)?$/i.exec(str);
		if (!match) return;
		var n = parseFloat(match[1]);
		switch ((match[2] || "ms").toLowerCase()) {
			case "years":
			case "year":
			case "yrs":
			case "yr":
			case "y": return n * y;
			case "weeks":
			case "week":
			case "w": return n * w;
			case "days":
			case "day":
			case "d": return n * d;
			case "hours":
			case "hour":
			case "hrs":
			case "hr":
			case "h": return n * h;
			case "minutes":
			case "minute":
			case "mins":
			case "min":
			case "m": return n * m;
			case "seconds":
			case "second":
			case "secs":
			case "sec":
			case "s": return n * s;
			case "milliseconds":
			case "millisecond":
			case "msecs":
			case "msec":
			case "ms": return n;
			default: return;
		}
	}
	/**
	* Short format for `ms`.
	*
	* @param {Number} ms
	* @return {String}
	* @api private
	*/
	function fmtShort(ms) {
		var msAbs = Math.abs(ms);
		if (msAbs >= d) return Math.round(ms / d) + "d";
		if (msAbs >= h) return Math.round(ms / h) + "h";
		if (msAbs >= m) return Math.round(ms / m) + "m";
		if (msAbs >= s) return Math.round(ms / s) + "s";
		return ms + "ms";
	}
	/**
	* Long format for `ms`.
	*
	* @param {Number} ms
	* @return {String}
	* @api private
	*/
	function fmtLong(ms) {
		var msAbs = Math.abs(ms);
		if (msAbs >= d) return plural(ms, msAbs, d, "day");
		if (msAbs >= h) return plural(ms, msAbs, h, "hour");
		if (msAbs >= m) return plural(ms, msAbs, m, "minute");
		if (msAbs >= s) return plural(ms, msAbs, s, "second");
		return ms + " ms";
	}
	/**
	* Pluralization helper.
	*/
	function plural(ms, msAbs, n, name) {
		var isPlural = msAbs >= n * 1.5;
		return Math.round(ms / n) + " " + name + (isPlural ? "s" : "");
	}
}));
//#endregion
//#region node_modules/@serialport/stream/node_modules/debug/src/common.js
var require_common$2 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* This is the common logic for both the Node.js and web browser
	* implementations of `debug()`.
	*/
	function setup(env) {
		createDebug.debug = createDebug;
		createDebug.default = createDebug;
		createDebug.coerce = coerce;
		createDebug.disable = disable;
		createDebug.enable = enable;
		createDebug.enabled = enabled;
		createDebug.humanize = require_ms();
		createDebug.destroy = destroy;
		Object.keys(env).forEach((key) => {
			createDebug[key] = env[key];
		});
		/**
		* The currently active debug mode names, and names to skip.
		*/
		createDebug.names = [];
		createDebug.skips = [];
		/**
		* Map of special "%n" handling functions, for the debug "format" argument.
		*
		* Valid key names are a single, lower or upper-case letter, i.e. "n" and "N".
		*/
		createDebug.formatters = {};
		/**
		* Selects a color for a debug namespace
		* @param {String} namespace The namespace string for the debug instance to be colored
		* @return {Number|String} An ANSI color code for the given namespace
		* @api private
		*/
		function selectColor(namespace) {
			let hash = 0;
			for (let i = 0; i < namespace.length; i++) {
				hash = (hash << 5) - hash + namespace.charCodeAt(i);
				hash |= 0;
			}
			return createDebug.colors[Math.abs(hash) % createDebug.colors.length];
		}
		createDebug.selectColor = selectColor;
		/**
		* Create a debugger with the given `namespace`.
		*
		* @param {String} namespace
		* @return {Function}
		* @api public
		*/
		function createDebug(namespace) {
			let prevTime;
			let enableOverride = null;
			let namespacesCache;
			let enabledCache;
			function debug(...args) {
				if (!debug.enabled) return;
				const self = debug;
				const curr = Number(/* @__PURE__ */ new Date());
				self.diff = curr - (prevTime || curr);
				self.prev = prevTime;
				self.curr = curr;
				prevTime = curr;
				args[0] = createDebug.coerce(args[0]);
				if (typeof args[0] !== "string") args.unshift("%O");
				let index = 0;
				args[0] = args[0].replace(/%([a-zA-Z%])/g, (match, format) => {
					if (match === "%%") return "%";
					index++;
					const formatter = createDebug.formatters[format];
					if (typeof formatter === "function") {
						const val = args[index];
						match = formatter.call(self, val);
						args.splice(index, 1);
						index--;
					}
					return match;
				});
				createDebug.formatArgs.call(self, args);
				(self.log || createDebug.log).apply(self, args);
			}
			debug.namespace = namespace;
			debug.useColors = createDebug.useColors();
			debug.color = createDebug.selectColor(namespace);
			debug.extend = extend;
			debug.destroy = createDebug.destroy;
			Object.defineProperty(debug, "enabled", {
				enumerable: true,
				configurable: false,
				get: () => {
					if (enableOverride !== null) return enableOverride;
					if (namespacesCache !== createDebug.namespaces) {
						namespacesCache = createDebug.namespaces;
						enabledCache = createDebug.enabled(namespace);
					}
					return enabledCache;
				},
				set: (v) => {
					enableOverride = v;
				}
			});
			if (typeof createDebug.init === "function") createDebug.init(debug);
			return debug;
		}
		function extend(namespace, delimiter) {
			const newDebug = createDebug(this.namespace + (typeof delimiter === "undefined" ? ":" : delimiter) + namespace);
			newDebug.log = this.log;
			return newDebug;
		}
		/**
		* Enables a debug mode by namespaces. This can include modes
		* separated by a colon and wildcards.
		*
		* @param {String} namespaces
		* @api public
		*/
		function enable(namespaces) {
			createDebug.save(namespaces);
			createDebug.namespaces = namespaces;
			createDebug.names = [];
			createDebug.skips = [];
			const split = (typeof namespaces === "string" ? namespaces : "").trim().replace(" ", ",").split(",").filter(Boolean);
			for (const ns of split) if (ns[0] === "-") createDebug.skips.push(ns.slice(1));
			else createDebug.names.push(ns);
		}
		/**
		* Checks if the given string matches a namespace template, honoring
		* asterisks as wildcards.
		*
		* @param {String} search
		* @param {String} template
		* @return {Boolean}
		*/
		function matchesTemplate(search, template) {
			let searchIndex = 0;
			let templateIndex = 0;
			let starIndex = -1;
			let matchIndex = 0;
			while (searchIndex < search.length) if (templateIndex < template.length && (template[templateIndex] === search[searchIndex] || template[templateIndex] === "*")) if (template[templateIndex] === "*") {
				starIndex = templateIndex;
				matchIndex = searchIndex;
				templateIndex++;
			} else {
				searchIndex++;
				templateIndex++;
			}
			else if (starIndex !== -1) {
				templateIndex = starIndex + 1;
				matchIndex++;
				searchIndex = matchIndex;
			} else return false;
			while (templateIndex < template.length && template[templateIndex] === "*") templateIndex++;
			return templateIndex === template.length;
		}
		/**
		* Disable debug output.
		*
		* @return {String} namespaces
		* @api public
		*/
		function disable() {
			const namespaces = [...createDebug.names, ...createDebug.skips.map((namespace) => "-" + namespace)].join(",");
			createDebug.enable("");
			return namespaces;
		}
		/**
		* Returns true if the given mode name is enabled, false otherwise.
		*
		* @param {String} name
		* @return {Boolean}
		* @api public
		*/
		function enabled(name) {
			for (const skip of createDebug.skips) if (matchesTemplate(name, skip)) return false;
			for (const ns of createDebug.names) if (matchesTemplate(name, ns)) return true;
			return false;
		}
		/**
		* Coerce `val`.
		*
		* @param {Mixed} val
		* @return {Mixed}
		* @api private
		*/
		function coerce(val) {
			if (val instanceof Error) return val.stack || val.message;
			return val;
		}
		/**
		* XXX DO NOT USE. This is a temporary stub function.
		* XXX It WILL be removed in the next major release.
		*/
		function destroy() {
			console.warn("Instance method `debug.destroy()` is deprecated and no longer does anything. It will be removed in the next major version of `debug`.");
		}
		createDebug.enable(createDebug.load());
		return createDebug;
	}
	module.exports = setup;
}));
//#endregion
//#region node_modules/@serialport/stream/node_modules/debug/src/browser.js
var require_browser$2 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* This is the web browser implementation of `debug()`.
	*/
	exports.formatArgs = formatArgs;
	exports.save = save;
	exports.load = load;
	exports.useColors = useColors;
	exports.storage = localstorage();
	exports.destroy = (() => {
		let warned = false;
		return () => {
			if (!warned) {
				warned = true;
				console.warn("Instance method `debug.destroy()` is deprecated and no longer does anything. It will be removed in the next major version of `debug`.");
			}
		};
	})();
	/**
	* Colors.
	*/
	exports.colors = [
		"#0000CC",
		"#0000FF",
		"#0033CC",
		"#0033FF",
		"#0066CC",
		"#0066FF",
		"#0099CC",
		"#0099FF",
		"#00CC00",
		"#00CC33",
		"#00CC66",
		"#00CC99",
		"#00CCCC",
		"#00CCFF",
		"#3300CC",
		"#3300FF",
		"#3333CC",
		"#3333FF",
		"#3366CC",
		"#3366FF",
		"#3399CC",
		"#3399FF",
		"#33CC00",
		"#33CC33",
		"#33CC66",
		"#33CC99",
		"#33CCCC",
		"#33CCFF",
		"#6600CC",
		"#6600FF",
		"#6633CC",
		"#6633FF",
		"#66CC00",
		"#66CC33",
		"#9900CC",
		"#9900FF",
		"#9933CC",
		"#9933FF",
		"#99CC00",
		"#99CC33",
		"#CC0000",
		"#CC0033",
		"#CC0066",
		"#CC0099",
		"#CC00CC",
		"#CC00FF",
		"#CC3300",
		"#CC3333",
		"#CC3366",
		"#CC3399",
		"#CC33CC",
		"#CC33FF",
		"#CC6600",
		"#CC6633",
		"#CC9900",
		"#CC9933",
		"#CCCC00",
		"#CCCC33",
		"#FF0000",
		"#FF0033",
		"#FF0066",
		"#FF0099",
		"#FF00CC",
		"#FF00FF",
		"#FF3300",
		"#FF3333",
		"#FF3366",
		"#FF3399",
		"#FF33CC",
		"#FF33FF",
		"#FF6600",
		"#FF6633",
		"#FF9900",
		"#FF9933",
		"#FFCC00",
		"#FFCC33"
	];
	/**
	* Currently only WebKit-based Web Inspectors, Firefox >= v31,
	* and the Firebug extension (any Firefox version) are known
	* to support "%c" CSS customizations.
	*
	* TODO: add a `localStorage` variable to explicitly enable/disable colors
	*/
	function useColors() {
		if (typeof window !== "undefined" && window.process && (window.process.type === "renderer" || window.process.__nwjs)) return true;
		if (typeof navigator !== "undefined" && navigator.userAgent && navigator.userAgent.toLowerCase().match(/(edge|trident)\/(\d+)/)) return false;
		let m;
		return typeof document !== "undefined" && document.documentElement && document.documentElement.style && document.documentElement.style.WebkitAppearance || typeof window !== "undefined" && window.console && (window.console.firebug || window.console.exception && window.console.table) || typeof navigator !== "undefined" && navigator.userAgent && (m = navigator.userAgent.toLowerCase().match(/firefox\/(\d+)/)) && parseInt(m[1], 10) >= 31 || typeof navigator !== "undefined" && navigator.userAgent && navigator.userAgent.toLowerCase().match(/applewebkit\/(\d+)/);
	}
	/**
	* Colorize log arguments if enabled.
	*
	* @api public
	*/
	function formatArgs(args) {
		args[0] = (this.useColors ? "%c" : "") + this.namespace + (this.useColors ? " %c" : " ") + args[0] + (this.useColors ? "%c " : " ") + "+" + module.exports.humanize(this.diff);
		if (!this.useColors) return;
		const c = "color: " + this.color;
		args.splice(1, 0, c, "color: inherit");
		let index = 0;
		let lastC = 0;
		args[0].replace(/%[a-zA-Z%]/g, (match) => {
			if (match === "%%") return;
			index++;
			if (match === "%c") lastC = index;
		});
		args.splice(lastC, 0, c);
	}
	/**
	* Invokes `console.debug()` when available.
	* No-op when `console.debug` is not a "function".
	* If `console.debug` is not available, falls back
	* to `console.log`.
	*
	* @api public
	*/
	exports.log = console.debug || console.log || (() => {});
	/**
	* Save `namespaces`.
	*
	* @param {String} namespaces
	* @api private
	*/
	function save(namespaces) {
		try {
			if (namespaces) exports.storage.setItem("debug", namespaces);
			else exports.storage.removeItem("debug");
		} catch (error) {}
	}
	/**
	* Load `namespaces`.
	*
	* @return {String} returns the previously persisted debug modes
	* @api private
	*/
	function load() {
		let r;
		try {
			r = exports.storage.getItem("debug");
		} catch (error) {}
		if (!r && typeof process !== "undefined" && "env" in process) r = process.env.DEBUG;
		return r;
	}
	/**
	* Localstorage attempts to return the localstorage.
	*
	* This is necessary because safari throws
	* when a user disables cookies/localstorage
	* and you attempt to access it.
	*
	* @return {LocalStorage}
	* @api private
	*/
	function localstorage() {
		try {
			return localStorage;
		} catch (error) {}
	}
	module.exports = require_common$2()(exports);
	var { formatters } = module.exports;
	/**
	* Map %j to `JSON.stringify()`, since no Web Inspectors do that by default.
	*/
	formatters.j = function(v) {
		try {
			return JSON.stringify(v);
		} catch (error) {
			return "[UnexpectedJSONParseError]: " + error.message;
		}
	};
}));
//#endregion
//#region node_modules/has-flag/index.js
var require_has_flag = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	module.exports = (flag, argv = process.argv) => {
		const prefix = flag.startsWith("-") ? "" : flag.length === 1 ? "-" : "--";
		const position = argv.indexOf(prefix + flag);
		const terminatorPosition = argv.indexOf("--");
		return position !== -1 && (terminatorPosition === -1 || position < terminatorPosition);
	};
}));
//#endregion
//#region node_modules/supports-color/index.js
var require_supports_color = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	var os$1 = require("os");
	var tty$3 = require("tty");
	var hasFlag = require_has_flag();
	var { env } = process;
	var forceColor;
	if (hasFlag("no-color") || hasFlag("no-colors") || hasFlag("color=false") || hasFlag("color=never")) forceColor = 0;
	else if (hasFlag("color") || hasFlag("colors") || hasFlag("color=true") || hasFlag("color=always")) forceColor = 1;
	if ("FORCE_COLOR" in env) if (env.FORCE_COLOR === "true") forceColor = 1;
	else if (env.FORCE_COLOR === "false") forceColor = 0;
	else forceColor = env.FORCE_COLOR.length === 0 ? 1 : Math.min(parseInt(env.FORCE_COLOR, 10), 3);
	function translateLevel(level) {
		if (level === 0) return false;
		return {
			level,
			hasBasic: true,
			has256: level >= 2,
			has16m: level >= 3
		};
	}
	function supportsColor(haveStream, streamIsTTY) {
		if (forceColor === 0) return 0;
		if (hasFlag("color=16m") || hasFlag("color=full") || hasFlag("color=truecolor")) return 3;
		if (hasFlag("color=256")) return 2;
		if (haveStream && !streamIsTTY && forceColor === void 0) return 0;
		const min = forceColor || 0;
		if (env.TERM === "dumb") return min;
		if (process.platform === "win32") {
			const osRelease = os$1.release().split(".");
			if (Number(osRelease[0]) >= 10 && Number(osRelease[2]) >= 10586) return Number(osRelease[2]) >= 14931 ? 3 : 2;
			return 1;
		}
		if ("CI" in env) {
			if ([
				"TRAVIS",
				"CIRCLECI",
				"APPVEYOR",
				"GITLAB_CI",
				"GITHUB_ACTIONS",
				"BUILDKITE"
			].some((sign) => sign in env) || env.CI_NAME === "codeship") return 1;
			return min;
		}
		if ("TEAMCITY_VERSION" in env) return /^(9\.(0*[1-9]\d*)\.|\d{2,}\.)/.test(env.TEAMCITY_VERSION) ? 1 : 0;
		if (env.COLORTERM === "truecolor") return 3;
		if ("TERM_PROGRAM" in env) {
			const version = parseInt((env.TERM_PROGRAM_VERSION || "").split(".")[0], 10);
			switch (env.TERM_PROGRAM) {
				case "iTerm.app": return version >= 3 ? 3 : 2;
				case "Apple_Terminal": return 2;
			}
		}
		if (/-256(color)?$/i.test(env.TERM)) return 2;
		if (/^screen|^xterm|^vt100|^vt220|^rxvt|color|ansi|cygwin|linux/i.test(env.TERM)) return 1;
		if ("COLORTERM" in env) return 1;
		return min;
	}
	function getSupportLevel(stream) {
		return translateLevel(supportsColor(stream, stream && stream.isTTY));
	}
	module.exports = {
		supportsColor: getSupportLevel,
		stdout: translateLevel(supportsColor(true, tty$3.isatty(1))),
		stderr: translateLevel(supportsColor(true, tty$3.isatty(2)))
	};
}));
//#endregion
//#region node_modules/@serialport/stream/node_modules/debug/src/node.js
var require_node$2 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* Module dependencies.
	*/
	var tty$2 = require("tty");
	var util$2 = require("util");
	/**
	* This is the Node.js implementation of `debug()`.
	*/
	exports.init = init;
	exports.log = log;
	exports.formatArgs = formatArgs;
	exports.save = save;
	exports.load = load;
	exports.useColors = useColors;
	exports.destroy = util$2.deprecate(() => {}, "Instance method `debug.destroy()` is deprecated and no longer does anything. It will be removed in the next major version of `debug`.");
	/**
	* Colors.
	*/
	exports.colors = [
		6,
		2,
		3,
		4,
		5,
		1
	];
	try {
		const supportsColor = require_supports_color();
		if (supportsColor && (supportsColor.stderr || supportsColor).level >= 2) exports.colors = [
			20,
			21,
			26,
			27,
			32,
			33,
			38,
			39,
			40,
			41,
			42,
			43,
			44,
			45,
			56,
			57,
			62,
			63,
			68,
			69,
			74,
			75,
			76,
			77,
			78,
			79,
			80,
			81,
			92,
			93,
			98,
			99,
			112,
			113,
			128,
			129,
			134,
			135,
			148,
			149,
			160,
			161,
			162,
			163,
			164,
			165,
			166,
			167,
			168,
			169,
			170,
			171,
			172,
			173,
			178,
			179,
			184,
			185,
			196,
			197,
			198,
			199,
			200,
			201,
			202,
			203,
			204,
			205,
			206,
			207,
			208,
			209,
			214,
			215,
			220,
			221
		];
	} catch (error) {}
	/**
	* Build up the default `inspectOpts` object from the environment variables.
	*
	*   $ DEBUG_COLORS=no DEBUG_DEPTH=10 DEBUG_SHOW_HIDDEN=enabled node script.js
	*/
	exports.inspectOpts = Object.keys(process.env).filter((key) => {
		return /^debug_/i.test(key);
	}).reduce((obj, key) => {
		const prop = key.substring(6).toLowerCase().replace(/_([a-z])/g, (_, k) => {
			return k.toUpperCase();
		});
		let val = process.env[key];
		if (/^(yes|on|true|enabled)$/i.test(val)) val = true;
		else if (/^(no|off|false|disabled)$/i.test(val)) val = false;
		else if (val === "null") val = null;
		else val = Number(val);
		obj[prop] = val;
		return obj;
	}, {});
	/**
	* Is stdout a TTY? Colored output is enabled when `true`.
	*/
	function useColors() {
		return "colors" in exports.inspectOpts ? Boolean(exports.inspectOpts.colors) : tty$2.isatty(process.stderr.fd);
	}
	/**
	* Adds ANSI color escape codes if enabled.
	*
	* @api public
	*/
	function formatArgs(args) {
		const { namespace: name, useColors } = this;
		if (useColors) {
			const c = this.color;
			const colorCode = "\x1B[3" + (c < 8 ? c : "8;5;" + c);
			const prefix = `  ${colorCode};1m${name} \u001B[0m`;
			args[0] = prefix + args[0].split("\n").join("\n" + prefix);
			args.push(colorCode + "m+" + module.exports.humanize(this.diff) + "\x1B[0m");
		} else args[0] = getDate() + name + " " + args[0];
	}
	function getDate() {
		if (exports.inspectOpts.hideDate) return "";
		return (/* @__PURE__ */ new Date()).toISOString() + " ";
	}
	/**
	* Invokes `util.formatWithOptions()` with the specified arguments and writes to stderr.
	*/
	function log(...args) {
		return process.stderr.write(util$2.formatWithOptions(exports.inspectOpts, ...args) + "\n");
	}
	/**
	* Save `namespaces`.
	*
	* @param {String} namespaces
	* @api private
	*/
	function save(namespaces) {
		if (namespaces) process.env.DEBUG = namespaces;
		else delete process.env.DEBUG;
	}
	/**
	* Load `namespaces`.
	*
	* @return {String} returns the previously persisted debug modes
	* @api private
	*/
	function load() {
		return process.env.DEBUG;
	}
	/**
	* Init logic for `debug` instances.
	*
	* Create a new `inspectOpts` object in case `useColors` is set
	* differently for a particular `debug` instance.
	*/
	function init(debug) {
		debug.inspectOpts = {};
		const keys = Object.keys(exports.inspectOpts);
		for (let i = 0; i < keys.length; i++) debug.inspectOpts[keys[i]] = exports.inspectOpts[keys[i]];
	}
	module.exports = require_common$2()(exports);
	var { formatters } = module.exports;
	/**
	* Map %o to `util.inspect()`, all on a single line.
	*/
	formatters.o = function(v) {
		this.inspectOpts.colors = this.useColors;
		return util$2.inspect(v, this.inspectOpts).split("\n").map((str) => str.trim()).join(" ");
	};
	/**
	* Map %O to `util.inspect()`, allowing multiple lines if needed.
	*/
	formatters.O = function(v) {
		this.inspectOpts.colors = this.useColors;
		return util$2.inspect(v, this.inspectOpts);
	};
}));
//#endregion
//#region node_modules/@serialport/stream/node_modules/debug/src/index.js
var require_src$2 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* Detect Electron renderer / nwjs process, which is node, but we should
	* treat as a browser.
	*/
	if (typeof process === "undefined" || process.type === "renderer" || process.browser === true || process.__nwjs) module.exports = require_browser$2();
	else module.exports = require_node$2();
}));
//#endregion
//#region node_modules/@serialport/stream/dist/index.js
var require_dist$6 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	var __importDefault = exports && exports.__importDefault || function(mod) {
		return mod && mod.__esModule ? mod : { "default": mod };
	};
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.SerialPortStream = exports.DisconnectedError = void 0;
	var stream_1$1 = require("stream");
	var debug = (0, __importDefault(require_src$2()).default)("serialport/stream");
	var DisconnectedError = class extends Error {
		disconnected;
		constructor(message) {
			super(message);
			this.disconnected = true;
		}
	};
	exports.DisconnectedError = DisconnectedError;
	var defaultSetFlags = {
		brk: false,
		cts: false,
		dtr: true,
		rts: true
	};
	function allocNewReadPool(poolSize) {
		const pool = Buffer.allocUnsafe(poolSize);
		pool.used = 0;
		return pool;
	}
	var SerialPortStream = class extends stream_1$1.Duplex {
		port;
		_pool;
		_kMinPoolSpace;
		opening;
		closing;
		settings;
		/**
		* Create a new serial port object for the `path`. In the case of invalid arguments or invalid options, when constructing a new SerialPort it will throw an error. The port will open automatically by default, which is the equivalent of calling `port.open(openCallback)` in the next tick. You can disable this by setting the option `autoOpen` to `false`.
		* @emits open
		* @emits data
		* @emits close
		* @emits error
		*/
		constructor(options, openCallback) {
			const settings = {
				autoOpen: true,
				endOnClose: false,
				highWaterMark: 64 * 1024,
				...options
			};
			super({ highWaterMark: settings.highWaterMark });
			if (!settings.binding) throw new TypeError("\"Bindings\" is invalid pass it as `options.binding`");
			if (!settings.path) throw new TypeError(`"path" is not defined: ${settings.path}`);
			if (typeof settings.baudRate !== "number") throw new TypeError(`"baudRate" must be a number: ${settings.baudRate}`);
			this.settings = settings;
			this.opening = false;
			this.closing = false;
			this._pool = allocNewReadPool(this.settings.highWaterMark);
			this._kMinPoolSpace = 128;
			if (this.settings.autoOpen) this.open(openCallback);
		}
		get path() {
			return this.settings.path;
		}
		get baudRate() {
			return this.settings.baudRate;
		}
		get isOpen() {
			return (this.port?.isOpen ?? false) && !this.closing;
		}
		_error(error, callback) {
			if (callback) callback.call(this, error);
			else this.emit("error", error);
		}
		_asyncError(error, callback) {
			process.nextTick(() => this._error(error, callback));
		}
		/**
		* Opens a connection to the given serial port.
		* @param {ErrorCallback=} openCallback - Called after a connection is opened. If this is not provided and an error occurs, it will be emitted on the port's `error` event.
		* @emits open
		*/
		open(openCallback) {
			if (this.isOpen) return this._asyncError(/* @__PURE__ */ new Error("Port is already open"), openCallback);
			if (this.opening) return this._asyncError(/* @__PURE__ */ new Error("Port is opening"), openCallback);
			const { highWaterMark, binding, autoOpen, endOnClose, ...openOptions } = this.settings;
			this.opening = true;
			debug("opening", `path: ${this.path}`);
			this.settings.binding.open(openOptions).then((port) => {
				debug("opened", `path: ${this.path}`);
				this.port = port;
				this.opening = false;
				this.emit("open");
				if (openCallback) openCallback.call(this, null);
			}, (err) => {
				this.opening = false;
				debug("Binding #open had an error", err);
				this._error(err, openCallback);
			});
		}
		/**
		* Changes the baud rate for an open port. Emits an error or calls the callback if the baud rate isn't supported.
		* @param {object=} options Only supports `baudRate`.
		* @param {number=} [options.baudRate] The baud rate of the port to be opened. This should match one of the commonly available baud rates, such as 110, 300, 1200, 2400, 4800, 9600, 14400, 19200, 38400, 57600, or 115200. Custom rates are supported best effort per platform. The device connected to the serial port is not guaranteed to support the requested baud rate, even if the port itself supports that baud rate.
		* @param {ErrorCallback=} [callback] Called once the port's baud rate changes. If `.update` is called without a callback, and there is an error, an error event is emitted.
		* @returns {undefined}
		*/
		update(options, callback) {
			if (!this.isOpen || !this.port) {
				debug("update attempted, but port is not open");
				return this._asyncError(/* @__PURE__ */ new Error("Port is not open"), callback);
			}
			debug("update", `baudRate: ${options.baudRate}`);
			this.port.update(options).then(() => {
				debug("binding.update", "finished");
				this.settings.baudRate = options.baudRate;
				if (callback) callback.call(this, null);
			}, (err) => {
				debug("binding.update", "error", err);
				return this._error(err, callback);
			});
		}
		write(data, encoding, callback) {
			if (Array.isArray(data)) data = Buffer.from(data);
			if (typeof encoding === "function") return super.write(data, encoding);
			return super.write(data, encoding, callback);
		}
		_write(data, encoding, callback) {
			if (!this.isOpen || !this.port) {
				this.once("open", () => {
					this._write(data, encoding, callback);
				});
				return;
			}
			debug("_write", `${data.length} bytes of data`);
			this.port.write(data).then(() => {
				debug("binding.write", "write finished");
				callback(null);
			}, (err) => {
				debug("binding.write", "error", err);
				if (!err.canceled) this._disconnected(err);
				callback(err);
			});
		}
		_writev(data, callback) {
			debug("_writev", `${data.length} chunks of data`);
			const dataV = data.map((write) => write.chunk);
			this._write(Buffer.concat(dataV), "binary", callback);
		}
		_read(bytesToRead) {
			if (!this.isOpen || !this.port) {
				debug("_read", "queueing _read for after open");
				this.once("open", () => {
					this._read(bytesToRead);
				});
				return;
			}
			if (!this._pool || this._pool.length - this._pool.used < this._kMinPoolSpace) {
				debug("_read", "discarding the read buffer pool because it is below kMinPoolSpace");
				this._pool = allocNewReadPool(this.settings.highWaterMark);
			}
			const pool = this._pool;
			const toRead = Math.min(pool.length - pool.used, bytesToRead);
			const start = pool.used;
			debug("_read", "reading", {
				start,
				toRead
			});
			this.port.read(pool, start, toRead).then(({ bytesRead }) => {
				debug("binding.read", "finished", { bytesRead });
				if (bytesRead === 0) {
					debug("binding.read", "Zero bytes read closing readable stream");
					this.push(null);
					return;
				}
				pool.used += bytesRead;
				this.push(pool.slice(start, start + bytesRead));
			}, (err) => {
				debug("binding.read", "error", err);
				if (!err.canceled) this._disconnected(err);
				this._read(bytesToRead);
			});
		}
		_disconnected(err) {
			if (!this.isOpen) {
				debug("disconnected aborted because already closed", err);
				return;
			}
			debug("disconnected", err);
			this.close(void 0, new DisconnectedError(err.message));
		}
		/**
		* Closes an open connection.
		*
		* If there are in progress writes when the port is closed the writes will error.
		* @param {ErrorCallback} callback Called once a connection is closed.
		* @param {Error} disconnectError used internally to propagate a disconnect error
		*/
		close(callback, disconnectError = null) {
			if (!this.isOpen || !this.port) {
				debug("close attempted, but port is not open");
				return this._asyncError(/* @__PURE__ */ new Error("Port is not open"), callback);
			}
			this.closing = true;
			debug("#close");
			this.port.close().then(() => {
				this.closing = false;
				debug("binding.close", "finished");
				this.emit("close", disconnectError);
				if (this.settings.endOnClose) this.emit("end");
				if (callback) callback.call(this, disconnectError);
			}, (err) => {
				this.closing = false;
				debug("binding.close", "had an error", err);
				return this._error(err, callback);
			});
		}
		/**
		* Set control flags on an open port. Uses [`SetCommMask`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa363257(v=vs.85).aspx) for Windows and [`ioctl`](http://linux.die.net/man/4/tty_ioctl) for OS X and Linux.
		*
		* All options are operating system default when the port is opened. Every flag is set on each call to the provided or default values. If options isn't provided default options is used.
		*/
		set(options, callback) {
			if (!this.isOpen || !this.port) {
				debug("set attempted, but port is not open");
				return this._asyncError(/* @__PURE__ */ new Error("Port is not open"), callback);
			}
			const settings = {
				...defaultSetFlags,
				...options
			};
			debug("#set", settings);
			this.port.set(settings).then(() => {
				debug("binding.set", "finished");
				if (callback) callback.call(this, null);
			}, (err) => {
				debug("binding.set", "had an error", err);
				return this._error(err, callback);
			});
		}
		/**
		* Returns the control flags (CTS, DSR, DCD) on the open port.
		* Uses [`GetCommModemStatus`](https://msdn.microsoft.com/en-us/library/windows/desktop/aa363258(v=vs.85).aspx) for Windows and [`ioctl`](http://linux.die.net/man/4/tty_ioctl) for mac and linux.
		*/
		get(callback) {
			if (!this.isOpen || !this.port) {
				debug("get attempted, but port is not open");
				return this._asyncError(/* @__PURE__ */ new Error("Port is not open"), callback);
			}
			debug("#get");
			this.port.get().then((status) => {
				debug("binding.get", "finished");
				callback.call(this, null, status);
			}, (err) => {
				debug("binding.get", "had an error", err);
				return this._error(err, callback);
			});
		}
		/**
		* Flush discards data received but not read, and written but not transmitted by the operating system. For more technical details, see [`tcflush(fd, TCIOFLUSH)`](http://linux.die.net/man/3/tcflush) for Mac/Linux and [`FlushFileBuffers`](http://msdn.microsoft.com/en-us/library/windows/desktop/aa364439) for Windows.
		*/
		flush(callback) {
			if (!this.isOpen || !this.port) {
				debug("flush attempted, but port is not open");
				return this._asyncError(/* @__PURE__ */ new Error("Port is not open"), callback);
			}
			debug("#flush");
			this.port.flush().then(() => {
				debug("binding.flush", "finished");
				if (callback) callback.call(this, null);
			}, (err) => {
				debug("binding.flush", "had an error", err);
				return this._error(err, callback);
			});
		}
		/**
		* Waits until all output data is transmitted to the serial port. After any pending write has completed it calls [`tcdrain()`](http://linux.die.net/man/3/tcdrain) or [FlushFileBuffers()](https://msdn.microsoft.com/en-us/library/windows/desktop/aa364439(v=vs.85).aspx) to ensure it has been written to the device.
		* @example
		Write the `data` and wait until it has finished transmitting to the target serial port before calling the callback. This will queue until the port is open and writes are finished.
		
		```js
		function writeAndDrain (data, callback) {
		port.write(data);
		port.drain(callback);
		}
		```
		*/
		drain(callback) {
			debug("drain");
			if (!this.isOpen || !this.port) {
				debug("drain queuing on port open");
				this.once("open", () => {
					this.drain(callback);
				});
				return;
			}
			this.port.drain().then(() => {
				debug("binding.drain", "finished");
				if (callback) callback.call(this, null);
			}, (err) => {
				debug("binding.drain", "had an error", err);
				return this._error(err, callback);
			});
		}
	};
	exports.SerialPortStream = SerialPortStream;
}));
/**
* The `error` event's callback is called with an error object whenever there is an error.
* @event error
*/
/**
* The `open` event's callback is called with no arguments when the port is opened and ready for writing. This happens if you have the constructor open immediately (which opens in the next tick) or if you open the port manually with `open()`. See [Useage/Opening a Port](#opening-a-port) for more information.
* @event open
*/
/**
* Request a number of bytes from the SerialPort. The `read()` method pulls some data out of the internal buffer and returns it. If no data is available to be read, null is returned. By default, the data is returned as a `Buffer` object unless an encoding has been specified using the `.setEncoding()` method.
* @method SerialPort.prototype.read
* @param {number=} size Specify how many bytes of data to return, if available
* @returns {(string|Buffer|null)} The data from internal buffers
*/
/**
* Listening for the `data` event puts the port in flowing mode. Data is emitted as soon as it's received. Data is a `Buffer` object with a varying amount of data in it. The `readLine` parser converts the data into string lines. See the [parsers](https://serialport.io/docs/api-parsers-overview) section for more information on parsers, and the [Node.js stream documentation](https://nodejs.org/api/stream.html#stream_event_data) for more information on the data event.
* @event data
*/
/**
* The `close` event's callback is called with no arguments when the port is closed. In the case of a disconnect it will be called with a Disconnect Error object (`err.disconnected == true`). In the event of a close error (unlikely), an error event is triggered.
* @event close
*/
/**
* The `pause()` method causes a stream in flowing mode to stop emitting 'data' events, switching out of flowing mode. Any data that becomes available remains in the internal buffer.
* @method SerialPort.prototype.pause
* @see resume
* @returns `this`
*/
/**
* The `resume()` method causes an explicitly paused, `Readable` stream to resume emitting 'data' events, switching the stream into flowing mode.
* @method SerialPort.prototype.resume
* @see pause
* @returns `this`
*/
//#endregion
//#region node_modules/debug/src/common.js
var require_common$1 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* This is the common logic for both the Node.js and web browser
	* implementations of `debug()`.
	*/
	function setup(env) {
		createDebug.debug = createDebug;
		createDebug.default = createDebug;
		createDebug.coerce = coerce;
		createDebug.disable = disable;
		createDebug.enable = enable;
		createDebug.enabled = enabled;
		createDebug.humanize = require_ms();
		createDebug.destroy = destroy;
		Object.keys(env).forEach((key) => {
			createDebug[key] = env[key];
		});
		/**
		* The currently active debug mode names, and names to skip.
		*/
		createDebug.names = [];
		createDebug.skips = [];
		/**
		* Map of special "%n" handling functions, for the debug "format" argument.
		*
		* Valid key names are a single, lower or upper-case letter, i.e. "n" and "N".
		*/
		createDebug.formatters = {};
		/**
		* Selects a color for a debug namespace
		* @param {String} namespace The namespace string for the debug instance to be colored
		* @return {Number|String} An ANSI color code for the given namespace
		* @api private
		*/
		function selectColor(namespace) {
			let hash = 0;
			for (let i = 0; i < namespace.length; i++) {
				hash = (hash << 5) - hash + namespace.charCodeAt(i);
				hash |= 0;
			}
			return createDebug.colors[Math.abs(hash) % createDebug.colors.length];
		}
		createDebug.selectColor = selectColor;
		/**
		* Create a debugger with the given `namespace`.
		*
		* @param {String} namespace
		* @return {Function}
		* @api public
		*/
		function createDebug(namespace) {
			let prevTime;
			let enableOverride = null;
			let namespacesCache;
			let enabledCache;
			function debug(...args) {
				if (!debug.enabled) return;
				const self = debug;
				const curr = Number(/* @__PURE__ */ new Date());
				self.diff = curr - (prevTime || curr);
				self.prev = prevTime;
				self.curr = curr;
				prevTime = curr;
				args[0] = createDebug.coerce(args[0]);
				if (typeof args[0] !== "string") args.unshift("%O");
				let index = 0;
				args[0] = args[0].replace(/%([a-zA-Z%])/g, (match, format) => {
					if (match === "%%") return "%";
					index++;
					const formatter = createDebug.formatters[format];
					if (typeof formatter === "function") {
						const val = args[index];
						match = formatter.call(self, val);
						args.splice(index, 1);
						index--;
					}
					return match;
				});
				createDebug.formatArgs.call(self, args);
				(self.log || createDebug.log).apply(self, args);
			}
			debug.namespace = namespace;
			debug.useColors = createDebug.useColors();
			debug.color = createDebug.selectColor(namespace);
			debug.extend = extend;
			debug.destroy = createDebug.destroy;
			Object.defineProperty(debug, "enabled", {
				enumerable: true,
				configurable: false,
				get: () => {
					if (enableOverride !== null) return enableOverride;
					if (namespacesCache !== createDebug.namespaces) {
						namespacesCache = createDebug.namespaces;
						enabledCache = createDebug.enabled(namespace);
					}
					return enabledCache;
				},
				set: (v) => {
					enableOverride = v;
				}
			});
			if (typeof createDebug.init === "function") createDebug.init(debug);
			return debug;
		}
		function extend(namespace, delimiter) {
			const newDebug = createDebug(this.namespace + (typeof delimiter === "undefined" ? ":" : delimiter) + namespace);
			newDebug.log = this.log;
			return newDebug;
		}
		/**
		* Enables a debug mode by namespaces. This can include modes
		* separated by a colon and wildcards.
		*
		* @param {String} namespaces
		* @api public
		*/
		function enable(namespaces) {
			createDebug.save(namespaces);
			createDebug.namespaces = namespaces;
			createDebug.names = [];
			createDebug.skips = [];
			const split = (typeof namespaces === "string" ? namespaces : "").trim().replace(/\s+/g, ",").split(",").filter(Boolean);
			for (const ns of split) if (ns[0] === "-") createDebug.skips.push(ns.slice(1));
			else createDebug.names.push(ns);
		}
		/**
		* Checks if the given string matches a namespace template, honoring
		* asterisks as wildcards.
		*
		* @param {String} search
		* @param {String} template
		* @return {Boolean}
		*/
		function matchesTemplate(search, template) {
			let searchIndex = 0;
			let templateIndex = 0;
			let starIndex = -1;
			let matchIndex = 0;
			while (searchIndex < search.length) if (templateIndex < template.length && (template[templateIndex] === search[searchIndex] || template[templateIndex] === "*")) if (template[templateIndex] === "*") {
				starIndex = templateIndex;
				matchIndex = searchIndex;
				templateIndex++;
			} else {
				searchIndex++;
				templateIndex++;
			}
			else if (starIndex !== -1) {
				templateIndex = starIndex + 1;
				matchIndex++;
				searchIndex = matchIndex;
			} else return false;
			while (templateIndex < template.length && template[templateIndex] === "*") templateIndex++;
			return templateIndex === template.length;
		}
		/**
		* Disable debug output.
		*
		* @return {String} namespaces
		* @api public
		*/
		function disable() {
			const namespaces = [...createDebug.names, ...createDebug.skips.map((namespace) => "-" + namespace)].join(",");
			createDebug.enable("");
			return namespaces;
		}
		/**
		* Returns true if the given mode name is enabled, false otherwise.
		*
		* @param {String} name
		* @return {Boolean}
		* @api public
		*/
		function enabled(name) {
			for (const skip of createDebug.skips) if (matchesTemplate(name, skip)) return false;
			for (const ns of createDebug.names) if (matchesTemplate(name, ns)) return true;
			return false;
		}
		/**
		* Coerce `val`.
		*
		* @param {Mixed} val
		* @return {Mixed}
		* @api private
		*/
		function coerce(val) {
			if (val instanceof Error) return val.stack || val.message;
			return val;
		}
		/**
		* XXX DO NOT USE. This is a temporary stub function.
		* XXX It WILL be removed in the next major release.
		*/
		function destroy() {
			console.warn("Instance method `debug.destroy()` is deprecated and no longer does anything. It will be removed in the next major version of `debug`.");
		}
		createDebug.enable(createDebug.load());
		return createDebug;
	}
	module.exports = setup;
}));
//#endregion
//#region node_modules/debug/src/browser.js
var require_browser$1 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* This is the web browser implementation of `debug()`.
	*/
	exports.formatArgs = formatArgs;
	exports.save = save;
	exports.load = load;
	exports.useColors = useColors;
	exports.storage = localstorage();
	exports.destroy = (() => {
		let warned = false;
		return () => {
			if (!warned) {
				warned = true;
				console.warn("Instance method `debug.destroy()` is deprecated and no longer does anything. It will be removed in the next major version of `debug`.");
			}
		};
	})();
	/**
	* Colors.
	*/
	exports.colors = [
		"#0000CC",
		"#0000FF",
		"#0033CC",
		"#0033FF",
		"#0066CC",
		"#0066FF",
		"#0099CC",
		"#0099FF",
		"#00CC00",
		"#00CC33",
		"#00CC66",
		"#00CC99",
		"#00CCCC",
		"#00CCFF",
		"#3300CC",
		"#3300FF",
		"#3333CC",
		"#3333FF",
		"#3366CC",
		"#3366FF",
		"#3399CC",
		"#3399FF",
		"#33CC00",
		"#33CC33",
		"#33CC66",
		"#33CC99",
		"#33CCCC",
		"#33CCFF",
		"#6600CC",
		"#6600FF",
		"#6633CC",
		"#6633FF",
		"#66CC00",
		"#66CC33",
		"#9900CC",
		"#9900FF",
		"#9933CC",
		"#9933FF",
		"#99CC00",
		"#99CC33",
		"#CC0000",
		"#CC0033",
		"#CC0066",
		"#CC0099",
		"#CC00CC",
		"#CC00FF",
		"#CC3300",
		"#CC3333",
		"#CC3366",
		"#CC3399",
		"#CC33CC",
		"#CC33FF",
		"#CC6600",
		"#CC6633",
		"#CC9900",
		"#CC9933",
		"#CCCC00",
		"#CCCC33",
		"#FF0000",
		"#FF0033",
		"#FF0066",
		"#FF0099",
		"#FF00CC",
		"#FF00FF",
		"#FF3300",
		"#FF3333",
		"#FF3366",
		"#FF3399",
		"#FF33CC",
		"#FF33FF",
		"#FF6600",
		"#FF6633",
		"#FF9900",
		"#FF9933",
		"#FFCC00",
		"#FFCC33"
	];
	/**
	* Currently only WebKit-based Web Inspectors, Firefox >= v31,
	* and the Firebug extension (any Firefox version) are known
	* to support "%c" CSS customizations.
	*
	* TODO: add a `localStorage` variable to explicitly enable/disable colors
	*/
	function useColors() {
		if (typeof window !== "undefined" && window.process && (window.process.type === "renderer" || window.process.__nwjs)) return true;
		if (typeof navigator !== "undefined" && navigator.userAgent && navigator.userAgent.toLowerCase().match(/(edge|trident)\/(\d+)/)) return false;
		let m;
		return typeof document !== "undefined" && document.documentElement && document.documentElement.style && document.documentElement.style.WebkitAppearance || typeof window !== "undefined" && window.console && (window.console.firebug || window.console.exception && window.console.table) || typeof navigator !== "undefined" && navigator.userAgent && (m = navigator.userAgent.toLowerCase().match(/firefox\/(\d+)/)) && parseInt(m[1], 10) >= 31 || typeof navigator !== "undefined" && navigator.userAgent && navigator.userAgent.toLowerCase().match(/applewebkit\/(\d+)/);
	}
	/**
	* Colorize log arguments if enabled.
	*
	* @api public
	*/
	function formatArgs(args) {
		args[0] = (this.useColors ? "%c" : "") + this.namespace + (this.useColors ? " %c" : " ") + args[0] + (this.useColors ? "%c " : " ") + "+" + module.exports.humanize(this.diff);
		if (!this.useColors) return;
		const c = "color: " + this.color;
		args.splice(1, 0, c, "color: inherit");
		let index = 0;
		let lastC = 0;
		args[0].replace(/%[a-zA-Z%]/g, (match) => {
			if (match === "%%") return;
			index++;
			if (match === "%c") lastC = index;
		});
		args.splice(lastC, 0, c);
	}
	/**
	* Invokes `console.debug()` when available.
	* No-op when `console.debug` is not a "function".
	* If `console.debug` is not available, falls back
	* to `console.log`.
	*
	* @api public
	*/
	exports.log = console.debug || console.log || (() => {});
	/**
	* Save `namespaces`.
	*
	* @param {String} namespaces
	* @api private
	*/
	function save(namespaces) {
		try {
			if (namespaces) exports.storage.setItem("debug", namespaces);
			else exports.storage.removeItem("debug");
		} catch (error) {}
	}
	/**
	* Load `namespaces`.
	*
	* @return {String} returns the previously persisted debug modes
	* @api private
	*/
	function load() {
		let r;
		try {
			r = exports.storage.getItem("debug") || exports.storage.getItem("DEBUG");
		} catch (error) {}
		if (!r && typeof process !== "undefined" && "env" in process) r = process.env.DEBUG;
		return r;
	}
	/**
	* Localstorage attempts to return the localstorage.
	*
	* This is necessary because safari throws
	* when a user disables cookies/localstorage
	* and you attempt to access it.
	*
	* @return {LocalStorage}
	* @api private
	*/
	function localstorage() {
		try {
			return localStorage;
		} catch (error) {}
	}
	module.exports = require_common$1()(exports);
	var { formatters } = module.exports;
	/**
	* Map %j to `JSON.stringify()`, since no Web Inspectors do that by default.
	*/
	formatters.j = function(v) {
		try {
			return JSON.stringify(v);
		} catch (error) {
			return "[UnexpectedJSONParseError]: " + error.message;
		}
	};
}));
//#endregion
//#region node_modules/debug/src/node.js
var require_node$1 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* Module dependencies.
	*/
	var tty$1 = require("tty");
	var util$1 = require("util");
	/**
	* This is the Node.js implementation of `debug()`.
	*/
	exports.init = init;
	exports.log = log;
	exports.formatArgs = formatArgs;
	exports.save = save;
	exports.load = load;
	exports.useColors = useColors;
	exports.destroy = util$1.deprecate(() => {}, "Instance method `debug.destroy()` is deprecated and no longer does anything. It will be removed in the next major version of `debug`.");
	/**
	* Colors.
	*/
	exports.colors = [
		6,
		2,
		3,
		4,
		5,
		1
	];
	try {
		const supportsColor = require_supports_color();
		if (supportsColor && (supportsColor.stderr || supportsColor).level >= 2) exports.colors = [
			20,
			21,
			26,
			27,
			32,
			33,
			38,
			39,
			40,
			41,
			42,
			43,
			44,
			45,
			56,
			57,
			62,
			63,
			68,
			69,
			74,
			75,
			76,
			77,
			78,
			79,
			80,
			81,
			92,
			93,
			98,
			99,
			112,
			113,
			128,
			129,
			134,
			135,
			148,
			149,
			160,
			161,
			162,
			163,
			164,
			165,
			166,
			167,
			168,
			169,
			170,
			171,
			172,
			173,
			178,
			179,
			184,
			185,
			196,
			197,
			198,
			199,
			200,
			201,
			202,
			203,
			204,
			205,
			206,
			207,
			208,
			209,
			214,
			215,
			220,
			221
		];
	} catch (error) {}
	/**
	* Build up the default `inspectOpts` object from the environment variables.
	*
	*   $ DEBUG_COLORS=no DEBUG_DEPTH=10 DEBUG_SHOW_HIDDEN=enabled node script.js
	*/
	exports.inspectOpts = Object.keys(process.env).filter((key) => {
		return /^debug_/i.test(key);
	}).reduce((obj, key) => {
		const prop = key.substring(6).toLowerCase().replace(/_([a-z])/g, (_, k) => {
			return k.toUpperCase();
		});
		let val = process.env[key];
		if (/^(yes|on|true|enabled)$/i.test(val)) val = true;
		else if (/^(no|off|false|disabled)$/i.test(val)) val = false;
		else if (val === "null") val = null;
		else val = Number(val);
		obj[prop] = val;
		return obj;
	}, {});
	/**
	* Is stdout a TTY? Colored output is enabled when `true`.
	*/
	function useColors() {
		return "colors" in exports.inspectOpts ? Boolean(exports.inspectOpts.colors) : tty$1.isatty(process.stderr.fd);
	}
	/**
	* Adds ANSI color escape codes if enabled.
	*
	* @api public
	*/
	function formatArgs(args) {
		const { namespace: name, useColors } = this;
		if (useColors) {
			const c = this.color;
			const colorCode = "\x1B[3" + (c < 8 ? c : "8;5;" + c);
			const prefix = `  ${colorCode};1m${name} \u001B[0m`;
			args[0] = prefix + args[0].split("\n").join("\n" + prefix);
			args.push(colorCode + "m+" + module.exports.humanize(this.diff) + "\x1B[0m");
		} else args[0] = getDate() + name + " " + args[0];
	}
	function getDate() {
		if (exports.inspectOpts.hideDate) return "";
		return (/* @__PURE__ */ new Date()).toISOString() + " ";
	}
	/**
	* Invokes `util.formatWithOptions()` with the specified arguments and writes to stderr.
	*/
	function log(...args) {
		return process.stderr.write(util$1.formatWithOptions(exports.inspectOpts, ...args) + "\n");
	}
	/**
	* Save `namespaces`.
	*
	* @param {String} namespaces
	* @api private
	*/
	function save(namespaces) {
		if (namespaces) process.env.DEBUG = namespaces;
		else delete process.env.DEBUG;
	}
	/**
	* Load `namespaces`.
	*
	* @return {String} returns the previously persisted debug modes
	* @api private
	*/
	function load() {
		return process.env.DEBUG;
	}
	/**
	* Init logic for `debug` instances.
	*
	* Create a new `inspectOpts` object in case `useColors` is set
	* differently for a particular `debug` instance.
	*/
	function init(debug) {
		debug.inspectOpts = {};
		const keys = Object.keys(exports.inspectOpts);
		for (let i = 0; i < keys.length; i++) debug.inspectOpts[keys[i]] = exports.inspectOpts[keys[i]];
	}
	module.exports = require_common$1()(exports);
	var { formatters } = module.exports;
	/**
	* Map %o to `util.inspect()`, all on a single line.
	*/
	formatters.o = function(v) {
		this.inspectOpts.colors = this.useColors;
		return util$1.inspect(v, this.inspectOpts).split("\n").map((str) => str.trim()).join(" ");
	};
	/**
	* Map %O to `util.inspect()`, allowing multiple lines if needed.
	*/
	formatters.O = function(v) {
		this.inspectOpts.colors = this.useColors;
		return util$1.inspect(v, this.inspectOpts);
	};
}));
//#endregion
//#region node_modules/debug/src/index.js
var require_src$1 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* Detect Electron renderer / nwjs process, which is node, but we should
	* treat as a browser.
	*/
	if (typeof process === "undefined" || process.type === "renderer" || process.browser === true || process.__nwjs) module.exports = require_browser$1();
	else module.exports = require_node$1();
}));
//#endregion
//#region node_modules/@serialport/binding-mock/dist/index.js
var require_dist$5 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	var debugFactory = require_src$1();
	function _interopDefaultLegacy(e) {
		return e && typeof e === "object" && "default" in e ? e : { "default": e };
	}
	var debug = (/* @__PURE__ */ _interopDefaultLegacy(debugFactory))["default"]("serialport/binding-mock");
	var ports = {};
	var serialNumber = 0;
	function resolveNextTick() {
		return new Promise((resolve) => process.nextTick(() => resolve()));
	}
	var CanceledError = class extends Error {
		constructor(message) {
			super(message);
			this.canceled = true;
		}
	};
	var MockBinding = {
		reset() {
			ports = {};
			serialNumber = 0;
		},
		createPort(path, options = {}) {
			serialNumber++;
			const optWithDefaults = Object.assign({
				echo: false,
				record: false,
				manufacturer: "The J5 Robotics Company",
				vendorId: void 0,
				productId: void 0,
				maxReadSize: 1024
			}, options);
			ports[path] = {
				data: Buffer.alloc(0),
				echo: optWithDefaults.echo,
				record: optWithDefaults.record,
				readyData: optWithDefaults.readyData,
				maxReadSize: optWithDefaults.maxReadSize,
				info: {
					path,
					manufacturer: optWithDefaults.manufacturer,
					serialNumber: `${serialNumber}`,
					pnpId: void 0,
					locationId: void 0,
					vendorId: optWithDefaults.vendorId,
					productId: optWithDefaults.productId
				}
			};
			debug(serialNumber, "created port", JSON.stringify({
				path,
				opt: options
			}));
		},
		async list() {
			debug(null, "list");
			return Object.values(ports).map((port) => port.info);
		},
		async open(options) {
			var _a;
			if (!options || typeof options !== "object" || Array.isArray(options)) throw new TypeError("\"options\" is not an object");
			if (!options.path) throw new TypeError("\"path\" is not a valid port");
			if (!options.baudRate) throw new TypeError("\"baudRate\" is not a valid baudRate");
			const openOptions = Object.assign({
				dataBits: 8,
				lock: true,
				stopBits: 1,
				parity: "none",
				rtscts: false,
				xon: false,
				xoff: false,
				xany: false,
				hupcl: true
			}, options);
			const { path } = openOptions;
			debug(null, `open: opening path ${path}`);
			const port = ports[path];
			await resolveNextTick();
			if (!port) throw new Error(`Port does not exist - please call MockBinding.createPort('${path}') first`);
			const serialNumber = port.info.serialNumber;
			if ((_a = port.openOpt) === null || _a === void 0 ? void 0 : _a.lock) {
				debug(serialNumber, "open: Port is locked cannot open");
				throw new Error("Port is locked cannot open");
			}
			debug(serialNumber, `open: opened path ${path}`);
			port.openOpt = Object.assign({}, openOptions);
			return new MockPortBinding(port, openOptions);
		}
	};
	/**
	* Mock bindings for pretend serialport access
	*/
	var MockPortBinding = class {
		constructor(port, openOptions) {
			this.port = port;
			this.openOptions = openOptions;
			this.pendingRead = null;
			this.isOpen = true;
			this.lastWrite = null;
			this.recording = Buffer.alloc(0);
			this.writeOperation = null;
			this.serialNumber = port.info.serialNumber;
			if (port.readyData) {
				const data = port.readyData;
				process.nextTick(() => {
					if (this.isOpen) {
						debug(this.serialNumber, "emitting ready data");
						this.emitData(data);
					}
				});
			}
		}
		emitData(data) {
			if (!this.isOpen || !this.port) throw new Error("Port must be open to pretend to receive data");
			const bufferData = Buffer.isBuffer(data) ? data : Buffer.from(data);
			debug(this.serialNumber, "emitting data - pending read:", Boolean(this.pendingRead));
			this.port.data = Buffer.concat([this.port.data, bufferData]);
			if (this.pendingRead) {
				process.nextTick(this.pendingRead);
				this.pendingRead = null;
			}
		}
		async close() {
			debug(this.serialNumber, "close");
			if (!this.isOpen) throw new Error("Port is not open");
			const port = this.port;
			if (!port) throw new Error("already closed");
			port.openOpt = void 0;
			port.data = Buffer.alloc(0);
			debug(this.serialNumber, "port is closed");
			this.serialNumber = void 0;
			this.isOpen = false;
			if (this.pendingRead) this.pendingRead(new CanceledError("port is closed"));
		}
		async read(buffer, offset, length) {
			if (!Buffer.isBuffer(buffer)) throw new TypeError("\"buffer\" is not a Buffer");
			if (typeof offset !== "number" || isNaN(offset)) throw new TypeError(`"offset" is not an integer got "${isNaN(offset) ? "NaN" : typeof offset}"`);
			if (typeof length !== "number" || isNaN(length)) throw new TypeError(`"length" is not an integer got "${isNaN(length) ? "NaN" : typeof length}"`);
			if (buffer.length < offset + length) throw new Error("buffer is too small");
			if (!this.isOpen) throw new Error("Port is not open");
			debug(this.serialNumber, "read", length, "bytes");
			await resolveNextTick();
			if (!this.isOpen || !this.port) throw new CanceledError("Read canceled");
			if (this.port.data.length <= 0) return new Promise((resolve, reject) => {
				this.pendingRead = (err) => {
					if (err) return reject(err);
					this.read(buffer, offset, length).then(resolve, reject);
				};
			});
			const lengthToRead = this.port.maxReadSize > length ? length : this.port.maxReadSize;
			const bytesRead = this.port.data.slice(0, lengthToRead).copy(buffer, offset);
			this.port.data = this.port.data.slice(lengthToRead);
			debug(this.serialNumber, "read", bytesRead, "bytes");
			return {
				bytesRead,
				buffer
			};
		}
		async write(buffer) {
			if (!Buffer.isBuffer(buffer)) throw new TypeError("\"buffer\" is not a Buffer");
			if (!this.isOpen || !this.port) {
				debug("write", "error port is not open");
				throw new Error("Port is not open");
			}
			debug(this.serialNumber, "write", buffer.length, "bytes");
			if (this.writeOperation) throw new Error("Overlapping writes are not supported and should be queued by the serialport object");
			this.writeOperation = (async () => {
				await resolveNextTick();
				if (!this.isOpen || !this.port) throw new Error("Write canceled");
				const data = this.lastWrite = Buffer.from(buffer);
				if (this.port.record) this.recording = Buffer.concat([this.recording, data]);
				if (this.port.echo) process.nextTick(() => {
					if (this.isOpen) this.emitData(data);
				});
				this.writeOperation = null;
				debug(this.serialNumber, "writing finished");
			})();
			return this.writeOperation;
		}
		async update(options) {
			if (typeof options !== "object") throw TypeError("\"options\" is not an object");
			if (typeof options.baudRate !== "number") throw new TypeError("\"options.baudRate\" is not a number");
			debug(this.serialNumber, "update");
			if (!this.isOpen || !this.port) throw new Error("Port is not open");
			await resolveNextTick();
			if (this.port.openOpt) this.port.openOpt.baudRate = options.baudRate;
		}
		async set(options) {
			if (typeof options !== "object") throw new TypeError("\"options\" is not an object");
			debug(this.serialNumber, "set");
			if (!this.isOpen) throw new Error("Port is not open");
			await resolveNextTick();
		}
		async get() {
			debug(this.serialNumber, "get");
			if (!this.isOpen) throw new Error("Port is not open");
			await resolveNextTick();
			return {
				cts: true,
				dsr: false,
				dcd: false
			};
		}
		async getBaudRate() {
			var _a;
			debug(this.serialNumber, "getBaudRate");
			if (!this.isOpen || !this.port) throw new Error("Port is not open");
			await resolveNextTick();
			if (!((_a = this.port.openOpt) === null || _a === void 0 ? void 0 : _a.baudRate)) throw new Error("Internal Error");
			return { baudRate: this.port.openOpt.baudRate };
		}
		async flush() {
			debug(this.serialNumber, "flush");
			if (!this.isOpen || !this.port) throw new Error("Port is not open");
			await resolveNextTick();
			this.port.data = Buffer.alloc(0);
		}
		async drain() {
			debug(this.serialNumber, "drain");
			if (!this.isOpen) throw new Error("Port is not open");
			await this.writeOperation;
			await resolveNextTick();
		}
	};
	exports.CanceledError = CanceledError;
	exports.MockBinding = MockBinding;
	exports.MockPortBinding = MockPortBinding;
}));
//#endregion
//#region node_modules/serialport/dist/serialport-mock.js
var require_serialport_mock = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.SerialPortMock = void 0;
	var stream_1 = require_dist$6();
	var binding_mock_1 = require_dist$5();
	var SerialPortMock = class extends stream_1.SerialPortStream {
		static list = binding_mock_1.MockBinding.list;
		static binding = binding_mock_1.MockBinding;
		constructor(options, openCallback) {
			const opts = {
				binding: binding_mock_1.MockBinding,
				...options
			};
			super(opts, openCallback);
		}
	};
	exports.SerialPortMock = SerialPortMock;
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/node_modules/debug/src/common.js
var require_common = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* This is the common logic for both the Node.js and web browser
	* implementations of `debug()`.
	*/
	function setup(env) {
		createDebug.debug = createDebug;
		createDebug.default = createDebug;
		createDebug.coerce = coerce;
		createDebug.disable = disable;
		createDebug.enable = enable;
		createDebug.enabled = enabled;
		createDebug.humanize = require_ms();
		createDebug.destroy = destroy;
		Object.keys(env).forEach((key) => {
			createDebug[key] = env[key];
		});
		/**
		* The currently active debug mode names, and names to skip.
		*/
		createDebug.names = [];
		createDebug.skips = [];
		/**
		* Map of special "%n" handling functions, for the debug "format" argument.
		*
		* Valid key names are a single, lower or upper-case letter, i.e. "n" and "N".
		*/
		createDebug.formatters = {};
		/**
		* Selects a color for a debug namespace
		* @param {String} namespace The namespace string for the debug instance to be colored
		* @return {Number|String} An ANSI color code for the given namespace
		* @api private
		*/
		function selectColor(namespace) {
			let hash = 0;
			for (let i = 0; i < namespace.length; i++) {
				hash = (hash << 5) - hash + namespace.charCodeAt(i);
				hash |= 0;
			}
			return createDebug.colors[Math.abs(hash) % createDebug.colors.length];
		}
		createDebug.selectColor = selectColor;
		/**
		* Create a debugger with the given `namespace`.
		*
		* @param {String} namespace
		* @return {Function}
		* @api public
		*/
		function createDebug(namespace) {
			let prevTime;
			let enableOverride = null;
			let namespacesCache;
			let enabledCache;
			function debug(...args) {
				if (!debug.enabled) return;
				const self = debug;
				const curr = Number(/* @__PURE__ */ new Date());
				self.diff = curr - (prevTime || curr);
				self.prev = prevTime;
				self.curr = curr;
				prevTime = curr;
				args[0] = createDebug.coerce(args[0]);
				if (typeof args[0] !== "string") args.unshift("%O");
				let index = 0;
				args[0] = args[0].replace(/%([a-zA-Z%])/g, (match, format) => {
					if (match === "%%") return "%";
					index++;
					const formatter = createDebug.formatters[format];
					if (typeof formatter === "function") {
						const val = args[index];
						match = formatter.call(self, val);
						args.splice(index, 1);
						index--;
					}
					return match;
				});
				createDebug.formatArgs.call(self, args);
				(self.log || createDebug.log).apply(self, args);
			}
			debug.namespace = namespace;
			debug.useColors = createDebug.useColors();
			debug.color = createDebug.selectColor(namespace);
			debug.extend = extend;
			debug.destroy = createDebug.destroy;
			Object.defineProperty(debug, "enabled", {
				enumerable: true,
				configurable: false,
				get: () => {
					if (enableOverride !== null) return enableOverride;
					if (namespacesCache !== createDebug.namespaces) {
						namespacesCache = createDebug.namespaces;
						enabledCache = createDebug.enabled(namespace);
					}
					return enabledCache;
				},
				set: (v) => {
					enableOverride = v;
				}
			});
			if (typeof createDebug.init === "function") createDebug.init(debug);
			return debug;
		}
		function extend(namespace, delimiter) {
			const newDebug = createDebug(this.namespace + (typeof delimiter === "undefined" ? ":" : delimiter) + namespace);
			newDebug.log = this.log;
			return newDebug;
		}
		/**
		* Enables a debug mode by namespaces. This can include modes
		* separated by a colon and wildcards.
		*
		* @param {String} namespaces
		* @api public
		*/
		function enable(namespaces) {
			createDebug.save(namespaces);
			createDebug.namespaces = namespaces;
			createDebug.names = [];
			createDebug.skips = [];
			const split = (typeof namespaces === "string" ? namespaces : "").trim().replace(" ", ",").split(",").filter(Boolean);
			for (const ns of split) if (ns[0] === "-") createDebug.skips.push(ns.slice(1));
			else createDebug.names.push(ns);
		}
		/**
		* Checks if the given string matches a namespace template, honoring
		* asterisks as wildcards.
		*
		* @param {String} search
		* @param {String} template
		* @return {Boolean}
		*/
		function matchesTemplate(search, template) {
			let searchIndex = 0;
			let templateIndex = 0;
			let starIndex = -1;
			let matchIndex = 0;
			while (searchIndex < search.length) if (templateIndex < template.length && (template[templateIndex] === search[searchIndex] || template[templateIndex] === "*")) if (template[templateIndex] === "*") {
				starIndex = templateIndex;
				matchIndex = searchIndex;
				templateIndex++;
			} else {
				searchIndex++;
				templateIndex++;
			}
			else if (starIndex !== -1) {
				templateIndex = starIndex + 1;
				matchIndex++;
				searchIndex = matchIndex;
			} else return false;
			while (templateIndex < template.length && template[templateIndex] === "*") templateIndex++;
			return templateIndex === template.length;
		}
		/**
		* Disable debug output.
		*
		* @return {String} namespaces
		* @api public
		*/
		function disable() {
			const namespaces = [...createDebug.names, ...createDebug.skips.map((namespace) => "-" + namespace)].join(",");
			createDebug.enable("");
			return namespaces;
		}
		/**
		* Returns true if the given mode name is enabled, false otherwise.
		*
		* @param {String} name
		* @return {Boolean}
		* @api public
		*/
		function enabled(name) {
			for (const skip of createDebug.skips) if (matchesTemplate(name, skip)) return false;
			for (const ns of createDebug.names) if (matchesTemplate(name, ns)) return true;
			return false;
		}
		/**
		* Coerce `val`.
		*
		* @param {Mixed} val
		* @return {Mixed}
		* @api private
		*/
		function coerce(val) {
			if (val instanceof Error) return val.stack || val.message;
			return val;
		}
		/**
		* XXX DO NOT USE. This is a temporary stub function.
		* XXX It WILL be removed in the next major release.
		*/
		function destroy() {
			console.warn("Instance method `debug.destroy()` is deprecated and no longer does anything. It will be removed in the next major version of `debug`.");
		}
		createDebug.enable(createDebug.load());
		return createDebug;
	}
	module.exports = setup;
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/node_modules/debug/src/browser.js
var require_browser = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* This is the web browser implementation of `debug()`.
	*/
	exports.formatArgs = formatArgs;
	exports.save = save;
	exports.load = load;
	exports.useColors = useColors;
	exports.storage = localstorage();
	exports.destroy = (() => {
		let warned = false;
		return () => {
			if (!warned) {
				warned = true;
				console.warn("Instance method `debug.destroy()` is deprecated and no longer does anything. It will be removed in the next major version of `debug`.");
			}
		};
	})();
	/**
	* Colors.
	*/
	exports.colors = [
		"#0000CC",
		"#0000FF",
		"#0033CC",
		"#0033FF",
		"#0066CC",
		"#0066FF",
		"#0099CC",
		"#0099FF",
		"#00CC00",
		"#00CC33",
		"#00CC66",
		"#00CC99",
		"#00CCCC",
		"#00CCFF",
		"#3300CC",
		"#3300FF",
		"#3333CC",
		"#3333FF",
		"#3366CC",
		"#3366FF",
		"#3399CC",
		"#3399FF",
		"#33CC00",
		"#33CC33",
		"#33CC66",
		"#33CC99",
		"#33CCCC",
		"#33CCFF",
		"#6600CC",
		"#6600FF",
		"#6633CC",
		"#6633FF",
		"#66CC00",
		"#66CC33",
		"#9900CC",
		"#9900FF",
		"#9933CC",
		"#9933FF",
		"#99CC00",
		"#99CC33",
		"#CC0000",
		"#CC0033",
		"#CC0066",
		"#CC0099",
		"#CC00CC",
		"#CC00FF",
		"#CC3300",
		"#CC3333",
		"#CC3366",
		"#CC3399",
		"#CC33CC",
		"#CC33FF",
		"#CC6600",
		"#CC6633",
		"#CC9900",
		"#CC9933",
		"#CCCC00",
		"#CCCC33",
		"#FF0000",
		"#FF0033",
		"#FF0066",
		"#FF0099",
		"#FF00CC",
		"#FF00FF",
		"#FF3300",
		"#FF3333",
		"#FF3366",
		"#FF3399",
		"#FF33CC",
		"#FF33FF",
		"#FF6600",
		"#FF6633",
		"#FF9900",
		"#FF9933",
		"#FFCC00",
		"#FFCC33"
	];
	/**
	* Currently only WebKit-based Web Inspectors, Firefox >= v31,
	* and the Firebug extension (any Firefox version) are known
	* to support "%c" CSS customizations.
	*
	* TODO: add a `localStorage` variable to explicitly enable/disable colors
	*/
	function useColors() {
		if (typeof window !== "undefined" && window.process && (window.process.type === "renderer" || window.process.__nwjs)) return true;
		if (typeof navigator !== "undefined" && navigator.userAgent && navigator.userAgent.toLowerCase().match(/(edge|trident)\/(\d+)/)) return false;
		let m;
		return typeof document !== "undefined" && document.documentElement && document.documentElement.style && document.documentElement.style.WebkitAppearance || typeof window !== "undefined" && window.console && (window.console.firebug || window.console.exception && window.console.table) || typeof navigator !== "undefined" && navigator.userAgent && (m = navigator.userAgent.toLowerCase().match(/firefox\/(\d+)/)) && parseInt(m[1], 10) >= 31 || typeof navigator !== "undefined" && navigator.userAgent && navigator.userAgent.toLowerCase().match(/applewebkit\/(\d+)/);
	}
	/**
	* Colorize log arguments if enabled.
	*
	* @api public
	*/
	function formatArgs(args) {
		args[0] = (this.useColors ? "%c" : "") + this.namespace + (this.useColors ? " %c" : " ") + args[0] + (this.useColors ? "%c " : " ") + "+" + module.exports.humanize(this.diff);
		if (!this.useColors) return;
		const c = "color: " + this.color;
		args.splice(1, 0, c, "color: inherit");
		let index = 0;
		let lastC = 0;
		args[0].replace(/%[a-zA-Z%]/g, (match) => {
			if (match === "%%") return;
			index++;
			if (match === "%c") lastC = index;
		});
		args.splice(lastC, 0, c);
	}
	/**
	* Invokes `console.debug()` when available.
	* No-op when `console.debug` is not a "function".
	* If `console.debug` is not available, falls back
	* to `console.log`.
	*
	* @api public
	*/
	exports.log = console.debug || console.log || (() => {});
	/**
	* Save `namespaces`.
	*
	* @param {String} namespaces
	* @api private
	*/
	function save(namespaces) {
		try {
			if (namespaces) exports.storage.setItem("debug", namespaces);
			else exports.storage.removeItem("debug");
		} catch (error) {}
	}
	/**
	* Load `namespaces`.
	*
	* @return {String} returns the previously persisted debug modes
	* @api private
	*/
	function load() {
		let r;
		try {
			r = exports.storage.getItem("debug");
		} catch (error) {}
		if (!r && typeof process !== "undefined" && "env" in process) r = process.env.DEBUG;
		return r;
	}
	/**
	* Localstorage attempts to return the localstorage.
	*
	* This is necessary because safari throws
	* when a user disables cookies/localstorage
	* and you attempt to access it.
	*
	* @return {LocalStorage}
	* @api private
	*/
	function localstorage() {
		try {
			return localStorage;
		} catch (error) {}
	}
	module.exports = require_common()(exports);
	var { formatters } = module.exports;
	/**
	* Map %j to `JSON.stringify()`, since no Web Inspectors do that by default.
	*/
	formatters.j = function(v) {
		try {
			return JSON.stringify(v);
		} catch (error) {
			return "[UnexpectedJSONParseError]: " + error.message;
		}
	};
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/node_modules/debug/src/node.js
var require_node = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* Module dependencies.
	*/
	var tty = require("tty");
	var util = require("util");
	/**
	* This is the Node.js implementation of `debug()`.
	*/
	exports.init = init;
	exports.log = log;
	exports.formatArgs = formatArgs;
	exports.save = save;
	exports.load = load;
	exports.useColors = useColors;
	exports.destroy = util.deprecate(() => {}, "Instance method `debug.destroy()` is deprecated and no longer does anything. It will be removed in the next major version of `debug`.");
	/**
	* Colors.
	*/
	exports.colors = [
		6,
		2,
		3,
		4,
		5,
		1
	];
	try {
		const supportsColor = require_supports_color();
		if (supportsColor && (supportsColor.stderr || supportsColor).level >= 2) exports.colors = [
			20,
			21,
			26,
			27,
			32,
			33,
			38,
			39,
			40,
			41,
			42,
			43,
			44,
			45,
			56,
			57,
			62,
			63,
			68,
			69,
			74,
			75,
			76,
			77,
			78,
			79,
			80,
			81,
			92,
			93,
			98,
			99,
			112,
			113,
			128,
			129,
			134,
			135,
			148,
			149,
			160,
			161,
			162,
			163,
			164,
			165,
			166,
			167,
			168,
			169,
			170,
			171,
			172,
			173,
			178,
			179,
			184,
			185,
			196,
			197,
			198,
			199,
			200,
			201,
			202,
			203,
			204,
			205,
			206,
			207,
			208,
			209,
			214,
			215,
			220,
			221
		];
	} catch (error) {}
	/**
	* Build up the default `inspectOpts` object from the environment variables.
	*
	*   $ DEBUG_COLORS=no DEBUG_DEPTH=10 DEBUG_SHOW_HIDDEN=enabled node script.js
	*/
	exports.inspectOpts = Object.keys(process.env).filter((key) => {
		return /^debug_/i.test(key);
	}).reduce((obj, key) => {
		const prop = key.substring(6).toLowerCase().replace(/_([a-z])/g, (_, k) => {
			return k.toUpperCase();
		});
		let val = process.env[key];
		if (/^(yes|on|true|enabled)$/i.test(val)) val = true;
		else if (/^(no|off|false|disabled)$/i.test(val)) val = false;
		else if (val === "null") val = null;
		else val = Number(val);
		obj[prop] = val;
		return obj;
	}, {});
	/**
	* Is stdout a TTY? Colored output is enabled when `true`.
	*/
	function useColors() {
		return "colors" in exports.inspectOpts ? Boolean(exports.inspectOpts.colors) : tty.isatty(process.stderr.fd);
	}
	/**
	* Adds ANSI color escape codes if enabled.
	*
	* @api public
	*/
	function formatArgs(args) {
		const { namespace: name, useColors } = this;
		if (useColors) {
			const c = this.color;
			const colorCode = "\x1B[3" + (c < 8 ? c : "8;5;" + c);
			const prefix = `  ${colorCode};1m${name} \u001B[0m`;
			args[0] = prefix + args[0].split("\n").join("\n" + prefix);
			args.push(colorCode + "m+" + module.exports.humanize(this.diff) + "\x1B[0m");
		} else args[0] = getDate() + name + " " + args[0];
	}
	function getDate() {
		if (exports.inspectOpts.hideDate) return "";
		return (/* @__PURE__ */ new Date()).toISOString() + " ";
	}
	/**
	* Invokes `util.formatWithOptions()` with the specified arguments and writes to stderr.
	*/
	function log(...args) {
		return process.stderr.write(util.formatWithOptions(exports.inspectOpts, ...args) + "\n");
	}
	/**
	* Save `namespaces`.
	*
	* @param {String} namespaces
	* @api private
	*/
	function save(namespaces) {
		if (namespaces) process.env.DEBUG = namespaces;
		else delete process.env.DEBUG;
	}
	/**
	* Load `namespaces`.
	*
	* @return {String} returns the previously persisted debug modes
	* @api private
	*/
	function load() {
		return process.env.DEBUG;
	}
	/**
	* Init logic for `debug` instances.
	*
	* Create a new `inspectOpts` object in case `useColors` is set
	* differently for a particular `debug` instance.
	*/
	function init(debug) {
		debug.inspectOpts = {};
		const keys = Object.keys(exports.inspectOpts);
		for (let i = 0; i < keys.length; i++) debug.inspectOpts[keys[i]] = exports.inspectOpts[keys[i]];
	}
	module.exports = require_common()(exports);
	var { formatters } = module.exports;
	/**
	* Map %o to `util.inspect()`, all on a single line.
	*/
	formatters.o = function(v) {
		this.inspectOpts.colors = this.useColors;
		return util.inspect(v, this.inspectOpts).split("\n").map((str) => str.trim()).join(" ");
	};
	/**
	* Map %O to `util.inspect()`, allowing multiple lines if needed.
	*/
	formatters.O = function(v) {
		this.inspectOpts.colors = this.useColors;
		return util.inspect(v, this.inspectOpts);
	};
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/node_modules/debug/src/index.js
var require_src = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	/**
	* Detect Electron renderer / nwjs process, which is node, but we should
	* treat as a browser.
	*/
	if (typeof process === "undefined" || process.type === "renderer" || process.browser === true || process.__nwjs) module.exports = require_browser();
	else module.exports = require_node();
}));
//#endregion
//#region node_modules/node-gyp-build/node-gyp-build.js
var require_node_gyp_build$1 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	var fs = require("fs");
	var path = require("path");
	var os = require("os");
	var runtimeRequire = typeof __webpack_require__ === "function" ? __non_webpack_require__ : require;
	var vars = process.config && process.config.variables || {};
	var prebuildsOnly = !!process.env.PREBUILDS_ONLY;
	var abi = process.versions.modules;
	var runtime = isElectron() ? "electron" : isNwjs() ? "node-webkit" : "node";
	var arch = process.env.npm_config_arch || os.arch();
	var platform = process.env.npm_config_platform || os.platform();
	var libc = process.env.LIBC || (isAlpine(platform) ? "musl" : "glibc");
	var armv = process.env.ARM_VERSION || (arch === "arm64" ? "8" : vars.arm_version) || "";
	var uv = (process.versions.uv || "").split(".")[0];
	module.exports = load;
	function load(dir) {
		return runtimeRequire(load.resolve(dir));
	}
	load.resolve = load.path = function(dir) {
		dir = path.resolve(dir || ".");
		try {
			var name = runtimeRequire(path.join(dir, "package.json")).name.toUpperCase().replace(/-/g, "_");
			if (process.env[name + "_PREBUILD"]) dir = process.env[name + "_PREBUILD"];
		} catch (err) {}
		if (!prebuildsOnly) {
			var release = getFirst(path.join(dir, "build/Release"), matchBuild);
			if (release) return release;
			var debug = getFirst(path.join(dir, "build/Debug"), matchBuild);
			if (debug) return debug;
		}
		var prebuild = resolve(dir);
		if (prebuild) return prebuild;
		var nearby = resolve(path.dirname(process.execPath));
		if (nearby) return nearby;
		var target = [
			"platform=" + platform,
			"arch=" + arch,
			"runtime=" + runtime,
			"abi=" + abi,
			"uv=" + uv,
			armv ? "armv=" + armv : "",
			"libc=" + libc,
			"node=" + process.versions.node,
			process.versions.electron ? "electron=" + process.versions.electron : "",
			typeof __webpack_require__ === "function" ? "webpack=true" : ""
		].filter(Boolean).join(" ");
		throw new Error("No native build was found for " + target + "\n    loaded from: " + dir + "\n");
		function resolve(dir) {
			var tuple = readdirSync(path.join(dir, "prebuilds")).map(parseTuple).filter(matchTuple(platform, arch)).sort(compareTuples)[0];
			if (!tuple) return;
			var prebuilds = path.join(dir, "prebuilds", tuple.name);
			var winner = readdirSync(prebuilds).map(parseTags).filter(matchTags(runtime, abi)).sort(compareTags(runtime))[0];
			if (winner) return path.join(prebuilds, winner.file);
		}
	};
	function readdirSync(dir) {
		try {
			return fs.readdirSync(dir);
		} catch (err) {
			return [];
		}
	}
	function getFirst(dir, filter) {
		var files = readdirSync(dir).filter(filter);
		return files[0] && path.join(dir, files[0]);
	}
	function matchBuild(name) {
		return /\.node$/.test(name);
	}
	function parseTuple(name) {
		var arr = name.split("-");
		if (arr.length !== 2) return;
		var platform = arr[0];
		var architectures = arr[1].split("+");
		if (!platform) return;
		if (!architectures.length) return;
		if (!architectures.every(Boolean)) return;
		return {
			name,
			platform,
			architectures
		};
	}
	function matchTuple(platform, arch) {
		return function(tuple) {
			if (tuple == null) return false;
			if (tuple.platform !== platform) return false;
			return tuple.architectures.includes(arch);
		};
	}
	function compareTuples(a, b) {
		return a.architectures.length - b.architectures.length;
	}
	function parseTags(file) {
		var arr = file.split(".");
		var extension = arr.pop();
		var tags = {
			file,
			specificity: 0
		};
		if (extension !== "node") return;
		for (var i = 0; i < arr.length; i++) {
			var tag = arr[i];
			if (tag === "node" || tag === "electron" || tag === "node-webkit") tags.runtime = tag;
			else if (tag === "napi") tags.napi = true;
			else if (tag.slice(0, 3) === "abi") tags.abi = tag.slice(3);
			else if (tag.slice(0, 2) === "uv") tags.uv = tag.slice(2);
			else if (tag.slice(0, 4) === "armv") tags.armv = tag.slice(4);
			else if (tag === "glibc" || tag === "musl") tags.libc = tag;
			else continue;
			tags.specificity++;
		}
		return tags;
	}
	function matchTags(runtime, abi) {
		return function(tags) {
			if (tags == null) return false;
			if (tags.runtime && tags.runtime !== runtime && !runtimeAgnostic(tags)) return false;
			if (tags.abi && tags.abi !== abi && !tags.napi) return false;
			if (tags.uv && tags.uv !== uv) return false;
			if (tags.armv && tags.armv !== armv) return false;
			if (tags.libc && tags.libc !== libc) return false;
			return true;
		};
	}
	function runtimeAgnostic(tags) {
		return tags.runtime === "node" && tags.napi;
	}
	function compareTags(runtime) {
		return function(a, b) {
			if (a.runtime !== b.runtime) return a.runtime === runtime ? -1 : 1;
			else if (a.abi !== b.abi) return a.abi ? -1 : 1;
			else if (a.specificity !== b.specificity) return a.specificity > b.specificity ? -1 : 1;
			else return 0;
		};
	}
	function isNwjs() {
		return !!(process.versions && process.versions.nw);
	}
	function isElectron() {
		if (process.versions && process.versions.electron) return true;
		if (process.env.ELECTRON_RUN_AS_NODE) return true;
		return typeof window !== "undefined" && window.process && window.process.type === "renderer";
	}
	function isAlpine(platform) {
		return platform === "linux" && fs.existsSync("/etc/alpine-release");
	}
	load.parseTags = parseTags;
	load.matchTags = matchTags;
	load.compareTags = compareTags;
	load.parseTuple = parseTuple;
	load.matchTuple = matchTuple;
	load.compareTuples = compareTuples;
}));
//#endregion
//#region node_modules/node-gyp-build/index.js
var require_node_gyp_build = /* @__PURE__ */ require_chunk.__commonJSMin(((exports, module) => {
	var runtimeRequire = typeof __webpack_require__ === "function" ? __non_webpack_require__ : require;
	if (typeof runtimeRequire.addon === "function") module.exports = runtimeRequire.addon.bind(runtimeRequire);
	else module.exports = require_node_gyp_build$1();
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/serialport-bindings.js
var require_serialport_bindings = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	var __importDefault = exports && exports.__importDefault || function(mod) {
		return mod && mod.__esModule ? mod : { "default": mod };
	};
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.binding = void 0;
	var path_1 = require("path");
	exports.binding = (0, __importDefault(require_node_gyp_build()).default)((0, path_1.join)(__dirname, "../"));
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/load-bindings.js
var require_load_bindings = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.asyncWrite = exports.asyncRead = exports.asyncUpdate = exports.asyncSet = exports.asyncOpen = exports.asyncList = exports.asyncGetBaudRate = exports.asyncGet = exports.asyncFlush = exports.asyncDrain = exports.asyncClose = void 0;
	var util_1$2 = require("util");
	var serialport_bindings_1 = require_serialport_bindings();
	exports.asyncClose = serialport_bindings_1.binding.close ? (0, util_1$2.promisify)(serialport_bindings_1.binding.close) : async () => {
		throw new Error("\"binding.close\" Method not implemented");
	};
	exports.asyncDrain = serialport_bindings_1.binding.drain ? (0, util_1$2.promisify)(serialport_bindings_1.binding.drain) : async () => {
		throw new Error("\"binding.drain\" Method not implemented");
	};
	exports.asyncFlush = serialport_bindings_1.binding.flush ? (0, util_1$2.promisify)(serialport_bindings_1.binding.flush) : async () => {
		throw new Error("\"binding.flush\" Method not implemented");
	};
	exports.asyncGet = serialport_bindings_1.binding.get ? (0, util_1$2.promisify)(serialport_bindings_1.binding.get) : async () => {
		throw new Error("\"binding.get\" Method not implemented");
	};
	exports.asyncGetBaudRate = serialport_bindings_1.binding.getBaudRate ? (0, util_1$2.promisify)(serialport_bindings_1.binding.getBaudRate) : async () => {
		throw new Error("\"binding.getBaudRate\" Method not implemented");
	};
	exports.asyncList = serialport_bindings_1.binding.list ? (0, util_1$2.promisify)(serialport_bindings_1.binding.list) : async () => {
		throw new Error("\"binding.list\" Method not implemented");
	};
	exports.asyncOpen = serialport_bindings_1.binding.open ? (0, util_1$2.promisify)(serialport_bindings_1.binding.open) : async () => {
		throw new Error("\"binding.open\" Method not implemented");
	};
	exports.asyncSet = serialport_bindings_1.binding.set ? (0, util_1$2.promisify)(serialport_bindings_1.binding.set) : async () => {
		throw new Error("\"binding.set\" Method not implemented");
	};
	exports.asyncUpdate = serialport_bindings_1.binding.update ? (0, util_1$2.promisify)(serialport_bindings_1.binding.update) : async () => {
		throw new Error("\"binding.update\" Method not implemented");
	};
	exports.asyncRead = serialport_bindings_1.binding.read ? (0, util_1$2.promisify)(serialport_bindings_1.binding.read) : async () => {
		throw new Error("\"binding.read\" Method not implemented");
	};
	exports.asyncWrite = serialport_bindings_1.binding.write ? (0, util_1$2.promisify)(serialport_bindings_1.binding.write) : async () => {
		throw new Error("\"binding.write\" Method not implemented");
	};
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/errors.js
var require_errors = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.BindingsError = void 0;
	var BindingsError = class extends Error {
		constructor(message, { canceled = false } = {}) {
			super(message);
			this.canceled = canceled;
		}
	};
	exports.BindingsError = BindingsError;
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/poller.js
var require_poller = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	var __importDefault = exports && exports.__importDefault || function(mod) {
		return mod && mod.__esModule ? mod : { "default": mod };
	};
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.Poller = exports.EVENTS = void 0;
	var debug_1 = __importDefault(require_src());
	var events_1 = require("events");
	var errors_1 = require_errors();
	var { Poller: PollerBindings } = require_serialport_bindings().binding;
	var logger = (0, debug_1.default)("serialport/bindings-cpp/poller");
	exports.EVENTS = {
		UV_READABLE: 1,
		UV_WRITABLE: 2,
		UV_DISCONNECT: 4
	};
	function handleEvent(error, eventFlag) {
		if (error) {
			logger("error", error);
			this.emit("readable", error);
			this.emit("writable", error);
			this.emit("disconnect", error);
			return;
		}
		if (eventFlag & exports.EVENTS.UV_READABLE) {
			logger("received \"readable\"");
			this.emit("readable", null);
		}
		if (eventFlag & exports.EVENTS.UV_WRITABLE) {
			logger("received \"writable\"");
			this.emit("writable", null);
		}
		if (eventFlag & exports.EVENTS.UV_DISCONNECT) {
			logger("received \"disconnect\"");
			this.emit("disconnect", null);
		}
	}
	/**
	* Polls unix systems for readable or writable states of a file or serialport
	*/
	var Poller = class extends events_1.EventEmitter {
		constructor(fd, FDPoller = PollerBindings) {
			logger("Creating poller");
			super();
			this.poller = new FDPoller(fd, handleEvent.bind(this));
		}
		/**
		* Wait for the next event to occur
		* @param {string} event ('readable'|'writable'|'disconnect')
		* @returns {Poller} returns itself
		*/
		once(event, callback) {
			switch (event) {
				case "readable":
					this.poll(exports.EVENTS.UV_READABLE);
					break;
				case "writable":
					this.poll(exports.EVENTS.UV_WRITABLE);
					break;
				case "disconnect":
					this.poll(exports.EVENTS.UV_DISCONNECT);
					break;
			}
			return super.once(event, callback);
		}
		/**
		* Ask the bindings to listen for an event, it is recommend to use `.once()` for easy use
		* @param {EVENTS} eventFlag polls for an event or group of events based upon a flag.
		*/
		poll(eventFlag = 0) {
			if (eventFlag & exports.EVENTS.UV_READABLE) logger("Polling for \"readable\"");
			if (eventFlag & exports.EVENTS.UV_WRITABLE) logger("Polling for \"writable\"");
			if (eventFlag & exports.EVENTS.UV_DISCONNECT) logger("Polling for \"disconnect\"");
			this.poller.poll(eventFlag);
		}
		/**
		* Stop listening for events and cancel all outstanding listening with an error
		*/
		stop() {
			logger("Stopping poller");
			this.poller.stop();
			this.emitCanceled();
		}
		destroy() {
			logger("Destroying poller");
			this.poller.destroy();
			this.emitCanceled();
		}
		emitCanceled() {
			const err = new errors_1.BindingsError("Canceled", { canceled: true });
			this.emit("readable", err);
			this.emit("writable", err);
			this.emit("disconnect", err);
		}
	};
	exports.Poller = Poller;
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/unix-read.js
var require_unix_read = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	var __importDefault = exports && exports.__importDefault || function(mod) {
		return mod && mod.__esModule ? mod : { "default": mod };
	};
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.unixRead = void 0;
	var util_1$1 = require("util");
	var fs_1$1 = require("fs");
	var errors_1 = require_errors();
	var logger = (0, __importDefault(require_src()).default)("serialport/bindings-cpp/unixRead");
	var readAsync = (0, util_1$1.promisify)(fs_1$1.read);
	var readable = (binding) => {
		return new Promise((resolve, reject) => {
			if (!binding.poller) throw new Error("No poller on bindings");
			binding.poller.once("readable", (err) => err ? reject(err) : resolve());
		});
	};
	var unixRead = async ({ binding, buffer, offset, length, fsReadAsync = readAsync }) => {
		logger("Starting read");
		if (!binding.isOpen || !binding.fd) throw new errors_1.BindingsError("Port is not open", { canceled: true });
		try {
			const { bytesRead } = await fsReadAsync(binding.fd, buffer, offset, length, null);
			if (bytesRead === 0) return (0, exports.unixRead)({
				binding,
				buffer,
				offset,
				length,
				fsReadAsync
			});
			logger("Finished read", bytesRead, "bytes");
			return {
				bytesRead,
				buffer
			};
		} catch (err) {
			logger("read error", err);
			if (err.code === "EAGAIN" || err.code === "EWOULDBLOCK" || err.code === "EINTR") {
				if (!binding.isOpen) throw new errors_1.BindingsError("Port is not open", { canceled: true });
				logger("waiting for readable because of code:", err.code);
				await readable(binding);
				return (0, exports.unixRead)({
					binding,
					buffer,
					offset,
					length,
					fsReadAsync
				});
			}
			if (err.code === "EBADF" || err.code === "ENXIO" || err.code === "UNKNOWN" || err.errno === -1) {
				err.disconnect = true;
				logger("disconnecting", err);
			}
			throw err;
		}
	};
	exports.unixRead = unixRead;
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/unix-write.js
var require_unix_write = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	var __importDefault = exports && exports.__importDefault || function(mod) {
		return mod && mod.__esModule ? mod : { "default": mod };
	};
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.unixWrite = void 0;
	var fs_1 = require("fs");
	var debug_1 = __importDefault(require_src());
	var util_1 = require("util");
	var logger = (0, debug_1.default)("serialport/bindings-cpp/unixWrite");
	var writeAsync = (0, util_1.promisify)(fs_1.write);
	var writable = (binding) => {
		return new Promise((resolve, reject) => {
			binding.poller.once("writable", (err) => err ? reject(err) : resolve());
		});
	};
	var unixWrite = async ({ binding, buffer, offset = 0, fsWriteAsync = writeAsync }) => {
		const bytesToWrite = buffer.length - offset;
		logger("Starting write", buffer.length, "bytes offset", offset, "bytesToWrite", bytesToWrite);
		if (!binding.isOpen || !binding.fd) throw new Error("Port is not open");
		try {
			const { bytesWritten } = await fsWriteAsync(binding.fd, buffer, offset, bytesToWrite);
			logger("write returned: wrote", bytesWritten, "bytes");
			if (bytesWritten + offset < buffer.length) {
				if (!binding.isOpen) throw new Error("Port is not open");
				return (0, exports.unixWrite)({
					binding,
					buffer,
					offset: bytesWritten + offset,
					fsWriteAsync
				});
			}
			logger("Finished writing", bytesWritten + offset, "bytes");
		} catch (err) {
			logger("write errored", err);
			if (err.code === "EAGAIN" || err.code === "EWOULDBLOCK" || err.code === "EINTR") {
				if (!binding.isOpen) throw new Error("Port is not open");
				logger("waiting for writable because of code:", err.code);
				await writable(binding);
				return (0, exports.unixWrite)({
					binding,
					buffer,
					offset,
					fsWriteAsync
				});
			}
			if (err.code === "EBADF" || err.code === "ENXIO" || err.code === "UNKNOWN" || err.errno === -1) {
				err.disconnect = true;
				logger("disconnecting", err);
			}
			logger("error", err);
			throw err;
		}
	};
	exports.unixWrite = unixWrite;
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/darwin.js
var require_darwin = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	var __importDefault = exports && exports.__importDefault || function(mod) {
		return mod && mod.__esModule ? mod : { "default": mod };
	};
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.DarwinPortBinding = exports.DarwinBinding = void 0;
	var debug_1 = __importDefault(require_src());
	var load_bindings_1 = require_load_bindings();
	var poller_1 = require_poller();
	var unix_read_1 = require_unix_read();
	var unix_write_1 = require_unix_write();
	var debug = (0, debug_1.default)("serialport/bindings-cpp");
	exports.DarwinBinding = {
		list() {
			debug("list");
			return (0, load_bindings_1.asyncList)();
		},
		async open(options) {
			if (!options || typeof options !== "object" || Array.isArray(options)) throw new TypeError("\"options\" is not an object");
			if (!options.path) throw new TypeError("\"path\" is not a valid port");
			if (!options.baudRate) throw new TypeError("\"baudRate\" is not a valid baudRate");
			debug("open");
			const openOptions = Object.assign({
				vmin: 1,
				vtime: 0,
				dataBits: 8,
				lock: true,
				stopBits: 1,
				parity: "none",
				rtscts: false,
				xon: false,
				xoff: false,
				xany: false,
				hupcl: true
			}, options);
			return new DarwinPortBinding(await (0, load_bindings_1.asyncOpen)(openOptions.path, openOptions), openOptions);
		}
	};
	/**
	* The Darwin binding layer for OSX
	*/
	var DarwinPortBinding = class {
		constructor(fd, options) {
			this.fd = fd;
			this.openOptions = options;
			this.poller = new poller_1.Poller(fd);
			this.writeOperation = null;
		}
		get isOpen() {
			return this.fd !== null;
		}
		async close() {
			debug("close");
			if (!this.isOpen) throw new Error("Port is not open");
			const fd = this.fd;
			this.poller.stop();
			this.poller.destroy();
			this.fd = null;
			await (0, load_bindings_1.asyncClose)(fd);
		}
		async read(buffer, offset, length) {
			if (!Buffer.isBuffer(buffer)) throw new TypeError("\"buffer\" is not a Buffer");
			if (typeof offset !== "number" || isNaN(offset)) throw new TypeError(`"offset" is not an integer got "${isNaN(offset) ? "NaN" : typeof offset}"`);
			if (typeof length !== "number" || isNaN(length)) throw new TypeError(`"length" is not an integer got "${isNaN(length) ? "NaN" : typeof length}"`);
			debug("read");
			if (buffer.length < offset + length) throw new Error("buffer is too small");
			if (!this.isOpen) throw new Error("Port is not open");
			return (0, unix_read_1.unixRead)({
				binding: this,
				buffer,
				offset,
				length
			});
		}
		async write(buffer) {
			if (!Buffer.isBuffer(buffer)) throw new TypeError("\"buffer\" is not a Buffer");
			debug("write", buffer.length, "bytes");
			if (!this.isOpen) {
				debug("write", "error port is not open");
				throw new Error("Port is not open");
			}
			this.writeOperation = (async () => {
				if (buffer.length === 0) return;
				await (0, unix_write_1.unixWrite)({
					binding: this,
					buffer
				});
				this.writeOperation = null;
			})();
			return this.writeOperation;
		}
		async update(options) {
			if (!options || typeof options !== "object" || Array.isArray(options)) throw TypeError("\"options\" is not an object");
			if (typeof options.baudRate !== "number") throw new TypeError("\"options.baudRate\" is not a number");
			debug("update");
			if (!this.isOpen) throw new Error("Port is not open");
			await (0, load_bindings_1.asyncUpdate)(this.fd, options);
		}
		async set(options) {
			if (!options || typeof options !== "object" || Array.isArray(options)) throw new TypeError("\"options\" is not an object");
			debug("set", options);
			if (!this.isOpen) throw new Error("Port is not open");
			await (0, load_bindings_1.asyncSet)(this.fd, options);
		}
		async get() {
			debug("get");
			if (!this.isOpen) throw new Error("Port is not open");
			return (0, load_bindings_1.asyncGet)(this.fd);
		}
		async getBaudRate() {
			debug("getBaudRate");
			if (!this.isOpen) throw new Error("Port is not open");
			throw new Error("getBaudRate is not implemented on darwin");
		}
		async flush() {
			debug("flush");
			if (!this.isOpen) throw new Error("Port is not open");
			await (0, load_bindings_1.asyncFlush)(this.fd);
		}
		async drain() {
			debug("drain");
			if (!this.isOpen) throw new Error("Port is not open");
			await this.writeOperation;
			await (0, load_bindings_1.asyncDrain)(this.fd);
		}
	};
	exports.DarwinPortBinding = DarwinPortBinding;
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/node_modules/@serialport/parser-delimiter/dist/index.js
var require_dist$4 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.DelimiterParser = void 0;
	var stream_1 = require("stream");
	/**
	* A transform stream that emits data each time a byte sequence is received.
	* @extends Transform
	*
	* To use the `Delimiter` parser, provide a delimiter as a string, buffer, or array of bytes. Runs in O(n) time.
	*/
	var DelimiterParser = class extends stream_1.Transform {
		includeDelimiter;
		delimiter;
		buffer;
		constructor({ delimiter, includeDelimiter = false, ...options }) {
			super(options);
			if (delimiter === void 0) throw new TypeError("\"delimiter\" is not a bufferable object");
			if (delimiter.length === 0) throw new TypeError("\"delimiter\" has a 0 or undefined length");
			this.includeDelimiter = includeDelimiter;
			this.delimiter = Buffer.from(delimiter);
			this.buffer = Buffer.alloc(0);
		}
		_transform(chunk, encoding, cb) {
			let data = Buffer.concat([this.buffer, chunk]);
			let position;
			while ((position = data.indexOf(this.delimiter)) !== -1) {
				this.push(data.slice(0, position + (this.includeDelimiter ? this.delimiter.length : 0)));
				data = data.slice(position + this.delimiter.length);
			}
			this.buffer = data;
			cb();
		}
		_flush(cb) {
			this.push(this.buffer);
			this.buffer = Buffer.alloc(0);
			cb();
		}
	};
	exports.DelimiterParser = DelimiterParser;
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/node_modules/@serialport/parser-readline/dist/index.js
var require_dist$3 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.ReadlineParser = void 0;
	var parser_delimiter_1 = require_dist$4();
	/**
	*  A transform stream that emits data after a newline delimiter is received.
	* @summary To use the `Readline` parser, provide a delimiter (defaults to `\n`). Data is emitted as string controllable by the `encoding` option (defaults to `utf8`).
	*/
	var ReadlineParser = class extends parser_delimiter_1.DelimiterParser {
		constructor(options) {
			const opts = {
				delimiter: Buffer.from("\n", "utf8"),
				encoding: "utf8",
				...options
			};
			if (typeof opts.delimiter === "string") opts.delimiter = Buffer.from(opts.delimiter, opts.encoding);
			super(opts);
		}
	};
	exports.ReadlineParser = ReadlineParser;
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/linux-list.js
var require_linux_list = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.linuxList = linuxList;
	var child_process_1 = require("child_process");
	var parser_readline_1 = require_dist$3();
	function checkPathOfDevice(path) {
		return /(tty(S|WCH|ACM|USB|AMA|MFD|O|XRUSB)|rfcomm)/.test(path) && path;
	}
	function propName(name) {
		return {
			DEVNAME: "path",
			ID_VENDOR_ENC: "manufacturer",
			ID_SERIAL_SHORT: "serialNumber",
			ID_VENDOR_ID: "vendorId",
			ID_MODEL_ID: "productId",
			DEVLINKS: "pnpId",
			ID_USB_VENDOR_ENC: "manufacturer",
			ID_USB_SERIAL_SHORT: "serialNumber",
			ID_USB_VENDOR_ID: "vendorId",
			ID_USB_MODEL_ID: "productId"
		}[name.toUpperCase()];
	}
	function decodeHexEscape(str) {
		return str.replace(/\\x([a-fA-F0-9]{2})/g, (a, b) => {
			return String.fromCharCode(parseInt(b, 16));
		});
	}
	function propVal(name, val) {
		if (name === "pnpId") {
			const match = val.match(/\/by-id\/([^\s]+)/);
			return (match === null || match === void 0 ? void 0 : match[1]) || void 0;
		}
		if (name === "manufacturer") return decodeHexEscape(val);
		if (/^0x/.test(val)) return val.substr(2);
		return val;
	}
	function linuxList(spawnCmd = child_process_1.spawn) {
		const ports = [];
		const udevadm = spawnCmd("udevadm", ["info", "-e"]);
		const lines = udevadm.stdout.pipe(new parser_readline_1.ReadlineParser());
		let skipPort = false;
		let port = {
			path: "",
			manufacturer: void 0,
			serialNumber: void 0,
			pnpId: void 0,
			locationId: void 0,
			vendorId: void 0,
			productId: void 0
		};
		lines.on("data", (line) => {
			const lineType = line.slice(0, 1);
			const data = line.slice(3);
			if (lineType === "P") {
				port = {
					path: "",
					manufacturer: void 0,
					serialNumber: void 0,
					pnpId: void 0,
					locationId: void 0,
					vendorId: void 0,
					productId: void 0
				};
				skipPort = false;
				return;
			}
			if (skipPort) return;
			if (lineType === "N") {
				if (checkPathOfDevice(data)) ports.push(port);
				else skipPort = true;
				return;
			}
			if (lineType === "E") {
				const keyValue = data.match(/^(.+)=(.*)/);
				if (!keyValue) return;
				const key = propName(keyValue[1]);
				if (!key) return;
				port[key] = propVal(key, keyValue[2]);
			}
		});
		return new Promise((resolve, reject) => {
			udevadm.on("close", (code) => {
				if (code) reject(/* @__PURE__ */ new Error(`Error listing ports udevadm exited with error code: ${code}`));
			});
			udevadm.on("error", reject);
			lines.on("error", reject);
			lines.on("finish", () => resolve(ports));
		});
	}
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/linux.js
var require_linux = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	var __importDefault = exports && exports.__importDefault || function(mod) {
		return mod && mod.__esModule ? mod : { "default": mod };
	};
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.LinuxPortBinding = exports.LinuxBinding = void 0;
	var debug_1 = __importDefault(require_src());
	var linux_list_1 = require_linux_list();
	var poller_1 = require_poller();
	var unix_read_1 = require_unix_read();
	var unix_write_1 = require_unix_write();
	var load_bindings_1 = require_load_bindings();
	var debug = (0, debug_1.default)("serialport/bindings-cpp");
	exports.LinuxBinding = {
		list() {
			debug("list");
			return (0, linux_list_1.linuxList)();
		},
		async open(options) {
			if (!options || typeof options !== "object" || Array.isArray(options)) throw new TypeError("\"options\" is not an object");
			if (!options.path) throw new TypeError("\"path\" is not a valid port");
			if (!options.baudRate) throw new TypeError("\"baudRate\" is not a valid baudRate");
			debug("open");
			const openOptions = Object.assign({
				vmin: 1,
				vtime: 0,
				dataBits: 8,
				lock: true,
				stopBits: 1,
				parity: "none",
				rtscts: false,
				xon: false,
				xoff: false,
				xany: false,
				hupcl: true
			}, options);
			const fd = await (0, load_bindings_1.asyncOpen)(openOptions.path, openOptions);
			this.fd = fd;
			return new LinuxPortBinding(fd, openOptions);
		}
	};
	/**
	* The linux binding layer
	*/
	var LinuxPortBinding = class {
		constructor(fd, openOptions) {
			this.fd = fd;
			this.openOptions = openOptions;
			this.poller = new poller_1.Poller(fd);
			this.writeOperation = null;
		}
		get isOpen() {
			return this.fd !== null;
		}
		async close() {
			debug("close");
			if (!this.isOpen) throw new Error("Port is not open");
			const fd = this.fd;
			this.poller.stop();
			this.poller.destroy();
			this.fd = null;
			await (0, load_bindings_1.asyncClose)(fd);
		}
		async read(buffer, offset, length) {
			if (!Buffer.isBuffer(buffer)) throw new TypeError("\"buffer\" is not a Buffer");
			if (typeof offset !== "number" || isNaN(offset)) throw new TypeError(`"offset" is not an integer got "${isNaN(offset) ? "NaN" : typeof offset}"`);
			if (typeof length !== "number" || isNaN(length)) throw new TypeError(`"length" is not an integer got "${isNaN(length) ? "NaN" : typeof length}"`);
			debug("read");
			if (buffer.length < offset + length) throw new Error("buffer is too small");
			if (!this.isOpen) throw new Error("Port is not open");
			return (0, unix_read_1.unixRead)({
				binding: this,
				buffer,
				offset,
				length
			});
		}
		async write(buffer) {
			if (!Buffer.isBuffer(buffer)) throw new TypeError("\"buffer\" is not a Buffer");
			debug("write", buffer.length, "bytes");
			if (!this.isOpen) {
				debug("write", "error port is not open");
				throw new Error("Port is not open");
			}
			this.writeOperation = (async () => {
				if (buffer.length === 0) return;
				await (0, unix_write_1.unixWrite)({
					binding: this,
					buffer
				});
				this.writeOperation = null;
			})();
			return this.writeOperation;
		}
		async update(options) {
			if (!options || typeof options !== "object" || Array.isArray(options)) throw TypeError("\"options\" is not an object");
			if (typeof options.baudRate !== "number") throw new TypeError("\"options.baudRate\" is not a number");
			debug("update");
			if (!this.isOpen) throw new Error("Port is not open");
			await (0, load_bindings_1.asyncUpdate)(this.fd, options);
		}
		async set(options) {
			if (!options || typeof options !== "object" || Array.isArray(options)) throw new TypeError("\"options\" is not an object");
			debug("set");
			if (!this.isOpen) throw new Error("Port is not open");
			await (0, load_bindings_1.asyncSet)(this.fd, options);
		}
		async get() {
			debug("get");
			if (!this.isOpen) throw new Error("Port is not open");
			return (0, load_bindings_1.asyncGet)(this.fd);
		}
		async getBaudRate() {
			debug("getBaudRate");
			if (!this.isOpen) throw new Error("Port is not open");
			return (0, load_bindings_1.asyncGetBaudRate)(this.fd);
		}
		async flush() {
			debug("flush");
			if (!this.isOpen) throw new Error("Port is not open");
			await (0, load_bindings_1.asyncFlush)(this.fd);
		}
		async drain() {
			debug("drain");
			if (!this.isOpen) throw new Error("Port is not open");
			await this.writeOperation;
			await (0, load_bindings_1.asyncDrain)(this.fd);
		}
	};
	exports.LinuxPortBinding = LinuxPortBinding;
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/win32-sn-parser.js
var require_win32_sn_parser = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.serialNumParser = void 0;
	var PARSERS = [/USB\\(?:.+)\\(.+)/, /FTDIBUS\\(?:.+)\+(.+?)A?\\.+/];
	var serialNumParser = (pnpId) => {
		if (!pnpId) return null;
		for (const parser of PARSERS) {
			const sn = pnpId.match(parser);
			if (sn) return sn[1];
		}
		return null;
	};
	exports.serialNumParser = serialNumParser;
}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/win32.js
var require_win32 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	var __importDefault = exports && exports.__importDefault || function(mod) {
		return mod && mod.__esModule ? mod : { "default": mod };
	};
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.WindowsPortBinding = exports.WindowsBinding = void 0;
	var debug_1 = __importDefault(require_src());
	var _1 = require_dist$1();
	var load_bindings_1 = require_load_bindings();
	var win32_sn_parser_1 = require_win32_sn_parser();
	var debug = (0, debug_1.default)("serialport/bindings-cpp");
	exports.WindowsBinding = {
		async list() {
			return (await (0, load_bindings_1.asyncList)()).map((port) => {
				if (port.pnpId && !port.serialNumber) {
					const serialNumber = (0, win32_sn_parser_1.serialNumParser)(port.pnpId);
					if (serialNumber) return Object.assign(Object.assign({}, port), { serialNumber });
				}
				return port;
			});
		},
		async open(options) {
			if (!options || typeof options !== "object" || Array.isArray(options)) throw new TypeError("\"options\" is not an object");
			if (!options.path) throw new TypeError("\"path\" is not a valid port");
			if (!options.baudRate) throw new TypeError("\"baudRate\" is not a valid baudRate");
			debug("open");
			const openOptions = Object.assign({
				dataBits: 8,
				lock: true,
				stopBits: 1,
				parity: "none",
				rtscts: false,
				rtsMode: "handshake",
				xon: false,
				xoff: false,
				xany: false,
				hupcl: true
			}, options);
			return new WindowsPortBinding(await (0, load_bindings_1.asyncOpen)(openOptions.path, openOptions), openOptions);
		}
	};
	/**
	* The Windows binding layer
	*/
	var WindowsPortBinding = class {
		constructor(fd, options) {
			this.fd = fd;
			this.openOptions = options;
			this.writeOperation = null;
		}
		get isOpen() {
			return this.fd !== null;
		}
		async close() {
			debug("close");
			if (!this.isOpen) throw new Error("Port is not open");
			const fd = this.fd;
			this.fd = null;
			await (0, load_bindings_1.asyncClose)(fd);
		}
		async read(buffer, offset, length) {
			if (!Buffer.isBuffer(buffer)) throw new TypeError("\"buffer\" is not a Buffer");
			if (typeof offset !== "number" || isNaN(offset)) throw new TypeError(`"offset" is not an integer got "${isNaN(offset) ? "NaN" : typeof offset}"`);
			if (typeof length !== "number" || isNaN(length)) throw new TypeError(`"length" is not an integer got "${isNaN(length) ? "NaN" : typeof length}"`);
			debug("read");
			if (buffer.length < offset + length) throw new Error("buffer is too small");
			if (!this.isOpen) throw new Error("Port is not open");
			try {
				return {
					bytesRead: await (0, load_bindings_1.asyncRead)(this.fd, buffer, offset, length),
					buffer
				};
			} catch (err) {
				if (!this.isOpen) throw new _1.BindingsError(err.message, { canceled: true });
				throw err;
			}
		}
		async write(buffer) {
			if (!Buffer.isBuffer(buffer)) throw new TypeError("\"buffer\" is not a Buffer");
			debug("write", buffer.length, "bytes");
			if (!this.isOpen) {
				debug("write", "error port is not open");
				throw new Error("Port is not open");
			}
			this.writeOperation = (async () => {
				if (buffer.length === 0) return;
				await (0, load_bindings_1.asyncWrite)(this.fd, buffer);
				this.writeOperation = null;
			})();
			return this.writeOperation;
		}
		async update(options) {
			if (!options || typeof options !== "object" || Array.isArray(options)) throw TypeError("\"options\" is not an object");
			if (typeof options.baudRate !== "number") throw new TypeError("\"options.baudRate\" is not a number");
			debug("update");
			if (!this.isOpen) throw new Error("Port is not open");
			await (0, load_bindings_1.asyncUpdate)(this.fd, options);
		}
		async set(options) {
			if (!options || typeof options !== "object" || Array.isArray(options)) throw new TypeError("\"options\" is not an object");
			debug("set", options);
			if (!this.isOpen) throw new Error("Port is not open");
			await (0, load_bindings_1.asyncSet)(this.fd, options);
		}
		async get() {
			debug("get");
			if (!this.isOpen) throw new Error("Port is not open");
			return (0, load_bindings_1.asyncGet)(this.fd);
		}
		async getBaudRate() {
			debug("getBaudRate");
			if (!this.isOpen) throw new Error("Port is not open");
			return (0, load_bindings_1.asyncGetBaudRate)(this.fd);
		}
		async flush() {
			debug("flush");
			if (!this.isOpen) throw new Error("Port is not open");
			await (0, load_bindings_1.asyncFlush)(this.fd);
		}
		async drain() {
			debug("drain");
			if (!this.isOpen) throw new Error("Port is not open");
			await this.writeOperation;
			await (0, load_bindings_1.asyncDrain)(this.fd);
		}
	};
	exports.WindowsPortBinding = WindowsPortBinding;
}));
//#endregion
//#region node_modules/@serialport/bindings-interface/dist/index.js
var require_dist$2 = /* @__PURE__ */ require_chunk.__commonJSMin((() => {}));
//#endregion
//#region node_modules/@serialport/bindings-cpp/dist/index.js
var require_dist$1 = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	var __createBinding = exports && exports.__createBinding || (Object.create ? (function(o, m, k, k2) {
		if (k2 === void 0) k2 = k;
		var desc = Object.getOwnPropertyDescriptor(m, k);
		if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) desc = {
			enumerable: true,
			get: function() {
				return m[k];
			}
		};
		Object.defineProperty(o, k2, desc);
	}) : (function(o, m, k, k2) {
		if (k2 === void 0) k2 = k;
		o[k2] = m[k];
	}));
	var __exportStar = exports && exports.__exportStar || function(m, exports$2) {
		for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports$2, p)) __createBinding(exports$2, m, p);
	};
	var __importDefault = exports && exports.__importDefault || function(mod) {
		return mod && mod.__esModule ? mod : { "default": mod };
	};
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.autoDetect = autoDetect;
	var debug_1 = __importDefault(require_src());
	var darwin_1 = require_darwin();
	var linux_1 = require_linux();
	var win32_1 = require_win32();
	var debug = (0, debug_1.default)("serialport/bindings-cpp");
	__exportStar(require_dist$2(), exports);
	__exportStar(require_darwin(), exports);
	__exportStar(require_linux(), exports);
	__exportStar(require_win32(), exports);
	__exportStar(require_errors(), exports);
	/**
	* This is an auto detected binding for your current platform
	*/
	function autoDetect() {
		switch (process.platform) {
			case "win32":
				debug("loading WindowsBinding");
				return win32_1.WindowsBinding;
			case "darwin":
				debug("loading DarwinBinding");
				return darwin_1.DarwinBinding;
			default:
				debug("loading LinuxBinding");
				return linux_1.LinuxBinding;
		}
	}
}));
//#endregion
//#region node_modules/serialport/dist/serialport.js
var require_serialport = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	Object.defineProperty(exports, "__esModule", { value: true });
	exports.SerialPort = void 0;
	var stream_1 = require_dist$6();
	var DetectedBinding = (0, require_dist$1().autoDetect)();
	var SerialPort = class extends stream_1.SerialPortStream {
		static list = DetectedBinding.list;
		static binding = DetectedBinding;
		constructor(options, openCallback) {
			const opts = {
				binding: DetectedBinding,
				...options
			};
			super(opts, openCallback);
		}
	};
	exports.SerialPort = SerialPort;
}));
//#endregion
//#region node_modules/serialport/dist/index.js
var require_dist = /* @__PURE__ */ require_chunk.__commonJSMin(((exports) => {
	var __createBinding = exports && exports.__createBinding || (Object.create ? (function(o, m, k, k2) {
		if (k2 === void 0) k2 = k;
		var desc = Object.getOwnPropertyDescriptor(m, k);
		if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) desc = {
			enumerable: true,
			get: function() {
				return m[k];
			}
		};
		Object.defineProperty(o, k2, desc);
	}) : (function(o, m, k, k2) {
		if (k2 === void 0) k2 = k;
		o[k2] = m[k];
	}));
	var __exportStar = exports && exports.__exportStar || function(m, exports$1) {
		for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports$1, p)) __createBinding(exports$1, m, p);
	};
	Object.defineProperty(exports, "__esModule", { value: true });
	__exportStar(require_dist$16(), exports);
	__exportStar(require_dist$15(), exports);
	__exportStar(require_dist$14(), exports);
	__exportStar(require_dist$13(), exports);
	__exportStar(require_dist$12(), exports);
	__exportStar(require_dist$11(), exports);
	__exportStar(require_dist$10(), exports);
	__exportStar(require_dist$9(), exports);
	__exportStar(require_dist$8(), exports);
	__exportStar(require_dist$7(), exports);
	__exportStar(require_serialport_mock(), exports);
	__exportStar(require_serialport(), exports);
}));
//#endregion
Object.defineProperty(exports, "default", {
	enumerable: true,
	get: function() {
		return require_dist();
	}
});
