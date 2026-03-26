//#region \0rolldown/runtime.js
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __esmMin = (fn, res) => () => (fn && (res = fn(fn = 0)), res);
var __commonJSMin = (cb, mod) => () => (mod || cb((mod = { exports: {} }).exports, mod), mod.exports);
var __exportAll = (all, no_symbols) => {
	let target = {};
	for (var name in all) __defProp(target, name, {
		get: all[name],
		enumerable: true
	});
	if (!no_symbols) __defProp(target, Symbol.toStringTag, { value: "Module" });
	return target;
};
var __copyProps = (to, from, except, desc) => {
	if (from && typeof from === "object" || typeof from === "function") for (var keys = __getOwnPropNames(from), i = 0, n = keys.length, key; i < n; i++) {
		key = keys[i];
		if (!__hasOwnProp.call(to, key) && key !== except) __defProp(to, key, {
			get: ((k) => from[k]).bind(null, key),
			enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable
		});
	}
	return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", {
	value: mod,
	enumerable: true
}) : target, mod));
var __toCommonJS = (mod) => __hasOwnProp.call(mod, "module.exports") ? mod["module.exports"] : __copyProps(__defProp({}, "__esModule", { value: true }), mod);
//#endregion
let electron = require("electron");
let node_path = require("node:path");
node_path = __toESM(node_path);
let node_url = require("node:url");
let sql_js = require("sql.js");
sql_js = __toESM(sql_js);
let node_fs = require("node:fs");
node_fs = __toESM(node_fs);
let node_crypto = require("node:crypto");
node_crypto = __toESM(node_crypto);
//#region node_modules/dotenv/package.json
var package_exports = /* @__PURE__ */ __exportAll({
	browser: () => browser,
	default: () => package_default,
	description: () => description,
	devDependencies: () => devDependencies,
	engines: () => engines,
	exports: () => exports$1,
	funding: () => funding,
	homepage: () => homepage,
	keywords: () => keywords,
	license: () => license,
	main: () => main,
	name: () => name,
	readmeFilename: () => readmeFilename,
	repository: () => repository,
	scripts: () => scripts,
	types: () => types,
	version: () => version
});
var name, version, description, main, types, exports$1, scripts, repository, homepage, funding, keywords, readmeFilename, license, devDependencies, engines, browser, package_default;
var init_package = __esmMin((() => {
	name = "dotenv";
	version = "17.3.1";
	description = "Loads environment variables from .env file";
	main = "lib/main.js";
	types = "lib/main.d.ts";
	exports$1 = {
		".": {
			"types": "./lib/main.d.ts",
			"require": "./lib/main.js",
			"default": "./lib/main.js"
		},
		"./config": "./config.js",
		"./config.js": "./config.js",
		"./lib/env-options": "./lib/env-options.js",
		"./lib/env-options.js": "./lib/env-options.js",
		"./lib/cli-options": "./lib/cli-options.js",
		"./lib/cli-options.js": "./lib/cli-options.js",
		"./package.json": "./package.json"
	};
	scripts = {
		"dts-check": "tsc --project tests/types/tsconfig.json",
		"lint": "standard",
		"pretest": "npm run lint && npm run dts-check",
		"test": "tap run tests/**/*.js --allow-empty-coverage --disable-coverage --timeout=60000",
		"test:coverage": "tap run tests/**/*.js --show-full-coverage --timeout=60000 --coverage-report=text --coverage-report=lcov",
		"prerelease": "npm test",
		"release": "standard-version"
	};
	repository = {
		"type": "git",
		"url": "git://github.com/motdotla/dotenv.git"
	};
	homepage = "https://github.com/motdotla/dotenv#readme";
	funding = "https://dotenvx.com";
	keywords = [
		"dotenv",
		"env",
		".env",
		"environment",
		"variables",
		"config",
		"settings"
	];
	readmeFilename = "README.md";
	license = "BSD-2-Clause";
	devDependencies = {
		"@types/node": "^18.11.3",
		"decache": "^4.6.2",
		"sinon": "^14.0.1",
		"standard": "^17.0.0",
		"standard-version": "^9.5.0",
		"tap": "^19.2.0",
		"typescript": "^4.8.4"
	};
	engines = { "node": ">=12" };
	browser = { "fs": false };
	package_default = {
		name,
		version,
		description,
		main,
		types,
		exports: exports$1,
		scripts,
		repository,
		homepage,
		funding,
		keywords,
		readmeFilename,
		license,
		devDependencies,
		engines,
		browser
	};
}));
//#endregion
//#region node_modules/dotenv/lib/main.js
var require_main$2 = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var fs$8 = require("fs");
	var path$10 = require("path");
	var os$4 = require("os");
	var crypto$3 = require("crypto");
	var version = (init_package(), __toCommonJS(package_exports).default).version;
	var TIPS = [
		"🔐 encrypt with Dotenvx: https://dotenvx.com",
		"🔐 prevent committing .env to code: https://dotenvx.com/precommit",
		"🔐 prevent building .env in docker: https://dotenvx.com/prebuild",
		"🤖 agentic secret storage: https://dotenvx.com/as2",
		"⚡️ secrets for agents: https://dotenvx.com/as2",
		"🛡️ auth for agents: https://vestauth.com",
		"🛠️  run anywhere with `dotenvx run -- yourcommand`",
		"⚙️  specify custom .env file path with { path: '/custom/path/.env' }",
		"⚙️  enable debug logging with { debug: true }",
		"⚙️  override existing env vars with { override: true }",
		"⚙️  suppress all logs with { quiet: true }",
		"⚙️  write to custom object with { processEnv: myObject }",
		"⚙️  load multiple .env files with { path: ['.env.local', '.env'] }"
	];
	function _getRandomTip() {
		return TIPS[Math.floor(Math.random() * TIPS.length)];
	}
	function parseBoolean(value) {
		if (typeof value === "string") return ![
			"false",
			"0",
			"no",
			"off",
			""
		].includes(value.toLowerCase());
		return Boolean(value);
	}
	function supportsAnsi() {
		return process.stdout.isTTY;
	}
	function dim(text) {
		return supportsAnsi() ? `\x1b[2m${text}\x1b[0m` : text;
	}
	var LINE = /(?:^|^)\s*(?:export\s+)?([\w.-]+)(?:\s*=\s*?|:\s+?)(\s*'(?:\\'|[^'])*'|\s*"(?:\\"|[^"])*"|\s*`(?:\\`|[^`])*`|[^#\r\n]+)?\s*(?:#.*)?(?:$|$)/gm;
	function parse(src) {
		const obj = {};
		let lines = src.toString();
		lines = lines.replace(/\r\n?/gm, "\n");
		let match;
		while ((match = LINE.exec(lines)) != null) {
			const key = match[1];
			let value = match[2] || "";
			value = value.trim();
			const maybeQuote = value[0];
			value = value.replace(/^(['"`])([\s\S]*)\1$/gm, "$2");
			if (maybeQuote === "\"") {
				value = value.replace(/\\n/g, "\n");
				value = value.replace(/\\r/g, "\r");
			}
			obj[key] = value;
		}
		return obj;
	}
	function _parseVault(options) {
		options = options || {};
		const vaultPath = _vaultPath(options);
		options.path = vaultPath;
		const result = DotenvModule.configDotenv(options);
		if (!result.parsed) {
			const err = /* @__PURE__ */ new Error(`MISSING_DATA: Cannot parse ${vaultPath} for an unknown reason`);
			err.code = "MISSING_DATA";
			throw err;
		}
		const keys = _dotenvKey(options).split(",");
		const length = keys.length;
		let decrypted;
		for (let i = 0; i < length; i++) try {
			const attrs = _instructions(result, keys[i].trim());
			decrypted = DotenvModule.decrypt(attrs.ciphertext, attrs.key);
			break;
		} catch (error) {
			if (i + 1 >= length) throw error;
		}
		return DotenvModule.parse(decrypted);
	}
	function _warn(message) {
		console.error(`[dotenv@${version}][WARN] ${message}`);
	}
	function _debug(message) {
		console.log(`[dotenv@${version}][DEBUG] ${message}`);
	}
	function _log(message) {
		console.log(`[dotenv@${version}] ${message}`);
	}
	function _dotenvKey(options) {
		if (options && options.DOTENV_KEY && options.DOTENV_KEY.length > 0) return options.DOTENV_KEY;
		if (process.env.DOTENV_KEY && process.env.DOTENV_KEY.length > 0) return process.env.DOTENV_KEY;
		return "";
	}
	function _instructions(result, dotenvKey) {
		let uri;
		try {
			uri = new URL(dotenvKey);
		} catch (error) {
			if (error.code === "ERR_INVALID_URL") {
				const err = /* @__PURE__ */ new Error("INVALID_DOTENV_KEY: Wrong format. Must be in valid uri format like dotenv://:key_1234@dotenvx.com/vault/.env.vault?environment=development");
				err.code = "INVALID_DOTENV_KEY";
				throw err;
			}
			throw error;
		}
		const key = uri.password;
		if (!key) {
			const err = /* @__PURE__ */ new Error("INVALID_DOTENV_KEY: Missing key part");
			err.code = "INVALID_DOTENV_KEY";
			throw err;
		}
		const environment = uri.searchParams.get("environment");
		if (!environment) {
			const err = /* @__PURE__ */ new Error("INVALID_DOTENV_KEY: Missing environment part");
			err.code = "INVALID_DOTENV_KEY";
			throw err;
		}
		const environmentKey = `DOTENV_VAULT_${environment.toUpperCase()}`;
		const ciphertext = result.parsed[environmentKey];
		if (!ciphertext) {
			const err = /* @__PURE__ */ new Error(`NOT_FOUND_DOTENV_ENVIRONMENT: Cannot locate environment ${environmentKey} in your .env.vault file.`);
			err.code = "NOT_FOUND_DOTENV_ENVIRONMENT";
			throw err;
		}
		return {
			ciphertext,
			key
		};
	}
	function _vaultPath(options) {
		let possibleVaultPath = null;
		if (options && options.path && options.path.length > 0) if (Array.isArray(options.path)) {
			for (const filepath of options.path) if (fs$8.existsSync(filepath)) possibleVaultPath = filepath.endsWith(".vault") ? filepath : `${filepath}.vault`;
		} else possibleVaultPath = options.path.endsWith(".vault") ? options.path : `${options.path}.vault`;
		else possibleVaultPath = path$10.resolve(process.cwd(), ".env.vault");
		if (fs$8.existsSync(possibleVaultPath)) return possibleVaultPath;
		return null;
	}
	function _resolveHome(envPath) {
		return envPath[0] === "~" ? path$10.join(os$4.homedir(), envPath.slice(1)) : envPath;
	}
	function _configVault(options) {
		const debug = parseBoolean(process.env.DOTENV_CONFIG_DEBUG || options && options.debug);
		const quiet = parseBoolean(process.env.DOTENV_CONFIG_QUIET || options && options.quiet);
		if (debug || !quiet) _log("Loading env from encrypted .env.vault");
		const parsed = DotenvModule._parseVault(options);
		let processEnv = process.env;
		if (options && options.processEnv != null) processEnv = options.processEnv;
		DotenvModule.populate(processEnv, parsed, options);
		return { parsed };
	}
	function configDotenv(options) {
		const dotenvPath = path$10.resolve(process.cwd(), ".env");
		let encoding = "utf8";
		let processEnv = process.env;
		if (options && options.processEnv != null) processEnv = options.processEnv;
		let debug = parseBoolean(processEnv.DOTENV_CONFIG_DEBUG || options && options.debug);
		let quiet = parseBoolean(processEnv.DOTENV_CONFIG_QUIET || options && options.quiet);
		if (options && options.encoding) encoding = options.encoding;
		else if (debug) _debug("No encoding is specified. UTF-8 is used by default");
		let optionPaths = [dotenvPath];
		if (options && options.path) if (!Array.isArray(options.path)) optionPaths = [_resolveHome(options.path)];
		else {
			optionPaths = [];
			for (const filepath of options.path) optionPaths.push(_resolveHome(filepath));
		}
		let lastError;
		const parsedAll = {};
		for (const path of optionPaths) try {
			const parsed = DotenvModule.parse(fs$8.readFileSync(path, { encoding }));
			DotenvModule.populate(parsedAll, parsed, options);
		} catch (e) {
			if (debug) _debug(`Failed to load ${path} ${e.message}`);
			lastError = e;
		}
		const populated = DotenvModule.populate(processEnv, parsedAll, options);
		debug = parseBoolean(processEnv.DOTENV_CONFIG_DEBUG || debug);
		quiet = parseBoolean(processEnv.DOTENV_CONFIG_QUIET || quiet);
		if (debug || !quiet) {
			const keysCount = Object.keys(populated).length;
			const shortPaths = [];
			for (const filePath of optionPaths) try {
				const relative = path$10.relative(process.cwd(), filePath);
				shortPaths.push(relative);
			} catch (e) {
				if (debug) _debug(`Failed to load ${filePath} ${e.message}`);
				lastError = e;
			}
			_log(`injecting env (${keysCount}) from ${shortPaths.join(",")} ${dim(`-- tip: ${_getRandomTip()}`)}`);
		}
		if (lastError) return {
			parsed: parsedAll,
			error: lastError
		};
		else return { parsed: parsedAll };
	}
	function config(options) {
		if (_dotenvKey(options).length === 0) return DotenvModule.configDotenv(options);
		const vaultPath = _vaultPath(options);
		if (!vaultPath) {
			_warn(`You set DOTENV_KEY but you are missing a .env.vault file at ${vaultPath}. Did you forget to build it?`);
			return DotenvModule.configDotenv(options);
		}
		return DotenvModule._configVault(options);
	}
	function decrypt(encrypted, keyStr) {
		const key = Buffer.from(keyStr.slice(-64), "hex");
		let ciphertext = Buffer.from(encrypted, "base64");
		const nonce = ciphertext.subarray(0, 12);
		const authTag = ciphertext.subarray(-16);
		ciphertext = ciphertext.subarray(12, -16);
		try {
			const aesgcm = crypto$3.createDecipheriv("aes-256-gcm", key, nonce);
			aesgcm.setAuthTag(authTag);
			return `${aesgcm.update(ciphertext)}${aesgcm.final()}`;
		} catch (error) {
			const isRange = error instanceof RangeError;
			const invalidKeyLength = error.message === "Invalid key length";
			const decryptionFailed = error.message === "Unsupported state or unable to authenticate data";
			if (isRange || invalidKeyLength) {
				const err = /* @__PURE__ */ new Error("INVALID_DOTENV_KEY: It must be 64 characters long (or more)");
				err.code = "INVALID_DOTENV_KEY";
				throw err;
			} else if (decryptionFailed) {
				const err = /* @__PURE__ */ new Error("DECRYPTION_FAILED: Please check your DOTENV_KEY");
				err.code = "DECRYPTION_FAILED";
				throw err;
			} else throw error;
		}
	}
	function populate(processEnv, parsed, options = {}) {
		const debug = Boolean(options && options.debug);
		const override = Boolean(options && options.override);
		const populated = {};
		if (typeof parsed !== "object") {
			const err = /* @__PURE__ */ new Error("OBJECT_REQUIRED: Please check the processEnv argument being passed to populate");
			err.code = "OBJECT_REQUIRED";
			throw err;
		}
		for (const key of Object.keys(parsed)) if (Object.prototype.hasOwnProperty.call(processEnv, key)) {
			if (override === true) {
				processEnv[key] = parsed[key];
				populated[key] = parsed[key];
			}
			if (debug) if (override === true) _debug(`"${key}" is already defined and WAS overwritten`);
			else _debug(`"${key}" is already defined and was NOT overwritten`);
		} else {
			processEnv[key] = parsed[key];
			populated[key] = parsed[key];
		}
		return populated;
	}
	var DotenvModule = {
		configDotenv,
		_configVault,
		_parseVault,
		config,
		decrypt,
		parse,
		populate
	};
	module.exports.configDotenv = DotenvModule.configDotenv;
	module.exports._configVault = DotenvModule._configVault;
	module.exports._parseVault = DotenvModule._parseVault;
	module.exports.config = DotenvModule.config;
	module.exports.decrypt = DotenvModule.decrypt;
	module.exports.parse = DotenvModule.parse;
	module.exports.populate = DotenvModule.populate;
	module.exports = DotenvModule;
}));
//#endregion
//#region node_modules/dotenv/lib/env-options.js
var require_env_options = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var options = {};
	if (process.env.DOTENV_CONFIG_ENCODING != null) options.encoding = process.env.DOTENV_CONFIG_ENCODING;
	if (process.env.DOTENV_CONFIG_PATH != null) options.path = process.env.DOTENV_CONFIG_PATH;
	if (process.env.DOTENV_CONFIG_QUIET != null) options.quiet = process.env.DOTENV_CONFIG_QUIET;
	if (process.env.DOTENV_CONFIG_DEBUG != null) options.debug = process.env.DOTENV_CONFIG_DEBUG;
	if (process.env.DOTENV_CONFIG_OVERRIDE != null) options.override = process.env.DOTENV_CONFIG_OVERRIDE;
	if (process.env.DOTENV_CONFIG_DOTENV_KEY != null) options.DOTENV_KEY = process.env.DOTENV_CONFIG_DOTENV_KEY;
	module.exports = options;
}));
//#endregion
//#region node_modules/dotenv/lib/cli-options.js
var require_cli_options = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var re = /^dotenv_config_(encoding|path|quiet|debug|override|DOTENV_KEY)=(.+)$/;
	module.exports = function optionMatcher(args) {
		const options = args.reduce(function(acc, cur) {
			const matches = cur.match(re);
			if (matches) acc[matches[1]] = matches[2];
			return acc;
		}, {});
		if (!("quiet" in options)) options.quiet = "true";
		return options;
	};
}));
//#endregion
//#region node_modules/dotenv/config.js
(function() {
	require_main$2().config(Object.assign({}, require_env_options(), require_cli_options()(process.argv)));
})();
//#endregion
//#region node_modules/electron-log/src/node/packageJson.js
var require_packageJson = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var fs$7 = require("fs");
	var path$9 = require("path");
	module.exports = {
		findAndReadPackageJson,
		tryReadJsonAt
	};
	/**
	* @return {{ name?: string, version?: string}}
	*/
	function findAndReadPackageJson() {
		return tryReadJsonAt(getMainModulePath()) || tryReadJsonAt(extractPathFromArgs()) || tryReadJsonAt(process.resourcesPath, "app.asar") || tryReadJsonAt(process.resourcesPath, "app") || tryReadJsonAt(process.cwd()) || {
			name: void 0,
			version: void 0
		};
	}
	/**
	* @param {...string} searchPaths
	* @return {{ name?: string, version?: string } | undefined}
	*/
	function tryReadJsonAt(...searchPaths) {
		if (!searchPaths[0]) return;
		try {
			const fileName = findUp("package.json", path$9.join(...searchPaths));
			if (!fileName) return;
			const json = JSON.parse(fs$7.readFileSync(fileName, "utf8"));
			const name = json?.productName || json?.name;
			if (!name || name.toLowerCase() === "electron") return;
			if (name) return {
				name,
				version: json?.version
			};
			return;
		} catch (e) {
			return;
		}
	}
	/**
	* @param {string} fileName
	* @param {string} [cwd]
	* @return {string | null}
	*/
	function findUp(fileName, cwd) {
		let currentPath = cwd;
		while (true) {
			const parsedPath = path$9.parse(currentPath);
			const root = parsedPath.root;
			const dir = parsedPath.dir;
			if (fs$7.existsSync(path$9.join(currentPath, fileName))) return path$9.resolve(path$9.join(currentPath, fileName));
			if (currentPath === root) return null;
			currentPath = dir;
		}
	}
	/**
	* Get app path from --user-data-dir cmd arg, passed to a renderer process
	* @return {string|null}
	*/
	function extractPathFromArgs() {
		const matchedArgs = process.argv.filter((arg) => {
			return arg.indexOf("--user-data-dir=") === 0;
		});
		if (matchedArgs.length === 0 || typeof matchedArgs[0] !== "string") return null;
		return matchedArgs[0].replace("--user-data-dir=", "");
	}
	function getMainModulePath() {
		try {
			return require.main?.filename;
		} catch {
			return;
		}
	}
}));
//#endregion
//#region node_modules/electron-log/src/node/NodeExternalApi.js
var require_NodeExternalApi = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var childProcess = require("child_process");
	var os$3 = require("os");
	var path$8 = require("path");
	var packageJson = require_packageJson();
	var NodeExternalApi = class {
		appName = void 0;
		appPackageJson = void 0;
		platform = process.platform;
		getAppLogPath(appName = this.getAppName()) {
			if (this.platform === "darwin") return path$8.join(this.getSystemPathHome(), "Library/Logs", appName);
			return path$8.join(this.getAppUserDataPath(appName), "logs");
		}
		getAppName() {
			const appName = this.appName || this.getAppPackageJson()?.name;
			if (!appName) throw new Error("electron-log can't determine the app name. It tried these methods:\n1. Use `electron.app.name`\n2. Use productName or name from the nearest package.json`\nYou can also set it through log.transports.file.setAppName()");
			return appName;
		}
		/**
		* @private
		* @returns {undefined}
		*/
		getAppPackageJson() {
			if (typeof this.appPackageJson !== "object") this.appPackageJson = packageJson.findAndReadPackageJson();
			return this.appPackageJson;
		}
		getAppUserDataPath(appName = this.getAppName()) {
			return appName ? path$8.join(this.getSystemPathAppData(), appName) : void 0;
		}
		getAppVersion() {
			return this.getAppPackageJson()?.version;
		}
		getElectronLogPath() {
			return this.getAppLogPath();
		}
		getMacOsVersion() {
			const release = Number(os$3.release().split(".")[0]);
			if (release <= 19) return `10.${release - 4}`;
			return release - 9;
		}
		/**
		* @protected
		* @returns {string}
		*/
		getOsVersion() {
			let osName = os$3.type().replace("_", " ");
			let osVersion = os$3.release();
			if (osName === "Darwin") {
				osName = "macOS";
				osVersion = this.getMacOsVersion();
			}
			return `${osName} ${osVersion}`;
		}
		/**
		* @return {PathVariables}
		*/
		getPathVariables() {
			const appName = this.getAppName();
			const appVersion = this.getAppVersion();
			const self = this;
			return {
				appData: this.getSystemPathAppData(),
				appName,
				appVersion,
				get electronDefaultDir() {
					return self.getElectronLogPath();
				},
				home: this.getSystemPathHome(),
				libraryDefaultDir: this.getAppLogPath(appName),
				libraryTemplate: this.getAppLogPath("{appName}"),
				temp: this.getSystemPathTemp(),
				userData: this.getAppUserDataPath(appName)
			};
		}
		getSystemPathAppData() {
			const home = this.getSystemPathHome();
			switch (this.platform) {
				case "darwin": return path$8.join(home, "Library/Application Support");
				case "win32": return process.env.APPDATA || path$8.join(home, "AppData/Roaming");
				default: return process.env.XDG_CONFIG_HOME || path$8.join(home, ".config");
			}
		}
		getSystemPathHome() {
			return os$3.homedir?.() || process.env.HOME;
		}
		getSystemPathTemp() {
			return os$3.tmpdir();
		}
		getVersions() {
			return {
				app: `${this.getAppName()} ${this.getAppVersion()}`,
				electron: void 0,
				os: this.getOsVersion()
			};
		}
		isDev() {
			return process.env.NODE_ENV === "development" || process.env.ELECTRON_IS_DEV === "1";
		}
		isElectron() {
			return Boolean(process.versions.electron);
		}
		onAppEvent(_eventName, _handler) {}
		onAppReady(handler) {
			handler();
		}
		onEveryWebContentsEvent(eventName, handler) {}
		/**
		* Listen to async messages sent from opposite process
		* @param {string} channel
		* @param {function} listener
		*/
		onIpc(channel, listener) {}
		onIpcInvoke(channel, listener) {}
		/**
		* @param {string} url
		* @param {Function} [logFunction]
		*/
		openUrl(url, logFunction = console.error) {
			const start = {
				darwin: "open",
				win32: "start",
				linux: "xdg-open"
			}[process.platform] || "xdg-open";
			childProcess.exec(`${start} ${url}`, {}, (err) => {
				if (err) logFunction(err);
			});
		}
		setAppName(appName) {
			this.appName = appName;
		}
		setPlatform(platform) {
			this.platform = platform;
		}
		setPreloadFileForSessions({ filePath, includeFutureSession = true, getSessions = () => [] }) {}
		/**
		* Sent a message to opposite process
		* @param {string} channel
		* @param {any} message
		*/
		sendIpc(channel, message) {}
		showErrorBox(title, message) {}
	};
	module.exports = NodeExternalApi;
}));
//#endregion
//#region node_modules/electron-log/src/main/ElectronExternalApi.js
var require_ElectronExternalApi = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var path$7 = require("path");
	var NodeExternalApi = require_NodeExternalApi();
	var ElectronExternalApi = class extends NodeExternalApi {
		/**
		* @type {typeof Electron}
		*/
		electron = void 0;
		/**
		* @param {object} options
		* @param {typeof Electron} [options.electron]
		*/
		constructor({ electron } = {}) {
			super();
			this.electron = electron;
		}
		getAppName() {
			let appName;
			try {
				appName = this.appName || this.electron.app?.name || this.electron.app?.getName();
			} catch {}
			return appName || super.getAppName();
		}
		getAppUserDataPath(appName) {
			return this.getPath("userData") || super.getAppUserDataPath(appName);
		}
		getAppVersion() {
			let appVersion;
			try {
				appVersion = this.electron.app?.getVersion();
			} catch {}
			return appVersion || super.getAppVersion();
		}
		getElectronLogPath() {
			return this.getPath("logs") || super.getElectronLogPath();
		}
		/**
		* @private
		* @param {any} name
		* @returns {string|undefined}
		*/
		getPath(name) {
			try {
				return this.electron.app?.getPath(name);
			} catch {
				return;
			}
		}
		getVersions() {
			return {
				app: `${this.getAppName()} ${this.getAppVersion()}`,
				electron: `Electron ${process.versions.electron}`,
				os: this.getOsVersion()
			};
		}
		getSystemPathAppData() {
			return this.getPath("appData") || super.getSystemPathAppData();
		}
		isDev() {
			if (this.electron.app?.isPackaged !== void 0) return !this.electron.app.isPackaged;
			if (typeof process.execPath === "string") return path$7.basename(process.execPath).toLowerCase().startsWith("electron");
			return super.isDev();
		}
		onAppEvent(eventName, handler) {
			this.electron.app?.on(eventName, handler);
			return () => {
				this.electron.app?.off(eventName, handler);
			};
		}
		onAppReady(handler) {
			if (this.electron.app?.isReady()) handler();
			else if (this.electron.app?.once) this.electron.app?.once("ready", handler);
			else handler();
		}
		onEveryWebContentsEvent(eventName, handler) {
			this.electron.webContents?.getAllWebContents()?.forEach((webContents) => {
				webContents.on(eventName, handler);
			});
			this.electron.app?.on("web-contents-created", onWebContentsCreated);
			return () => {
				this.electron.webContents?.getAllWebContents().forEach((webContents) => {
					webContents.off(eventName, handler);
				});
				this.electron.app?.off("web-contents-created", onWebContentsCreated);
			};
			function onWebContentsCreated(_, webContents) {
				webContents.on(eventName, handler);
			}
		}
		/**
		* Listen to async messages sent from opposite process
		* @param {string} channel
		* @param {function} listener
		*/
		onIpc(channel, listener) {
			this.electron.ipcMain?.on(channel, listener);
		}
		onIpcInvoke(channel, listener) {
			this.electron.ipcMain?.handle?.(channel, listener);
		}
		/**
		* @param {string} url
		* @param {Function} [logFunction]
		*/
		openUrl(url, logFunction = console.error) {
			this.electron.shell?.openExternal(url).catch(logFunction);
		}
		setPreloadFileForSessions({ filePath, includeFutureSession = true, getSessions = () => [this.electron.session?.defaultSession] }) {
			for (const session of getSessions().filter(Boolean)) setPreload(session);
			if (includeFutureSession) this.onAppEvent("session-created", (session) => {
				setPreload(session);
			});
			/**
			* @param {Session} session
			*/
			function setPreload(session) {
				if (typeof session.registerPreloadScript === "function") session.registerPreloadScript({
					filePath,
					id: "electron-log-preload",
					type: "frame"
				});
				else session.setPreloads([...session.getPreloads(), filePath]);
			}
		}
		/**
		* Sent a message to opposite process
		* @param {string} channel
		* @param {any} message
		*/
		sendIpc(channel, message) {
			this.electron.BrowserWindow?.getAllWindows()?.forEach((wnd) => {
				if (wnd.webContents?.isDestroyed() === false && wnd.webContents?.isCrashed() === false) wnd.webContents.send(channel, message);
			});
		}
		showErrorBox(title, message) {
			this.electron.dialog?.showErrorBox(title, message);
		}
	};
	module.exports = ElectronExternalApi;
}));
//#endregion
//#region node_modules/electron-log/src/renderer/electron-log-preload.js
var require_electron_log_preload = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var electron = {};
	try {
		electron = require("electron");
	} catch (e) {}
	if (electron.ipcRenderer) initialize(electron);
	if (typeof module === "object") module.exports = initialize;
	/**
	* @param {Electron.ContextBridge} contextBridge
	* @param {Electron.IpcRenderer} ipcRenderer
	*/
	function initialize({ contextBridge, ipcRenderer }) {
		if (!ipcRenderer) return;
		ipcRenderer.on("__ELECTRON_LOG_IPC__", (_, message) => {
			window.postMessage({
				cmd: "message",
				...message
			});
		});
		ipcRenderer.invoke("__ELECTRON_LOG__", { cmd: "getOptions" }).catch((e) => console.error(/* @__PURE__ */ new Error(`electron-log isn't initialized in the main process. Please call log.initialize() before. ${e.message}`)));
		const electronLog = {
			sendToMain(message) {
				try {
					ipcRenderer.send("__ELECTRON_LOG__", message);
				} catch (e) {
					console.error("electronLog.sendToMain ", e, "data:", message);
					ipcRenderer.send("__ELECTRON_LOG__", {
						cmd: "errorHandler",
						error: {
							message: e?.message,
							stack: e?.stack
						},
						errorName: "sendToMain"
					});
				}
			},
			log(...data) {
				electronLog.sendToMain({
					data,
					level: "info"
				});
			}
		};
		for (const level of [
			"error",
			"warn",
			"info",
			"verbose",
			"debug",
			"silly"
		]) electronLog[level] = (...data) => electronLog.sendToMain({
			data,
			level
		});
		if (contextBridge && process.contextIsolated) try {
			contextBridge.exposeInMainWorld("__electronLog", electronLog);
		} catch {}
		if (typeof window === "object") window.__electronLog = electronLog;
		else __electronLog = electronLog;
	}
}));
//#endregion
//#region node_modules/electron-log/src/main/initialize.js
var require_initialize = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var fs$6 = require("fs");
	var os$2 = require("os");
	var path$6 = require("path");
	var preloadInitializeFn = require_electron_log_preload();
	var preloadInitialized = false;
	var spyConsoleInitialized = false;
	module.exports = { initialize({ externalApi, getSessions, includeFutureSession, logger, preload = true, spyRendererConsole = false }) {
		externalApi.onAppReady(() => {
			try {
				if (preload) initializePreload({
					externalApi,
					getSessions,
					includeFutureSession,
					logger,
					preloadOption: preload
				});
				if (spyRendererConsole) initializeSpyRendererConsole({
					externalApi,
					logger
				});
			} catch (err) {
				logger.warn(err);
			}
		});
	} };
	function initializePreload({ externalApi, getSessions, includeFutureSession, logger, preloadOption }) {
		let preloadPath = typeof preloadOption === "string" ? preloadOption : void 0;
		if (preloadInitialized) {
			logger.warn((/* @__PURE__ */ new Error("log.initialize({ preload }) already called")).stack);
			return;
		}
		preloadInitialized = true;
		try {
			preloadPath = path$6.resolve(__dirname, "../renderer/electron-log-preload.js");
		} catch {}
		if (!preloadPath || !fs$6.existsSync(preloadPath)) {
			preloadPath = path$6.join(externalApi.getAppUserDataPath() || os$2.tmpdir(), "electron-log-preload.js");
			const preloadCode = `
      try {
        (${preloadInitializeFn.toString()})(require('electron'));
      } catch(e) {
        console.error(e);
      }
    `;
			fs$6.writeFileSync(preloadPath, preloadCode, "utf8");
		}
		externalApi.setPreloadFileForSessions({
			filePath: preloadPath,
			includeFutureSession,
			getSessions
		});
	}
	function initializeSpyRendererConsole({ externalApi, logger }) {
		if (spyConsoleInitialized) {
			logger.warn((/* @__PURE__ */ new Error("log.initialize({ spyRendererConsole }) already called")).stack);
			return;
		}
		spyConsoleInitialized = true;
		const levels = [
			"debug",
			"info",
			"warn",
			"error"
		];
		externalApi.onEveryWebContentsEvent("console-message", (event, level, message) => {
			logger.processMessage({
				data: [message],
				level: levels[level],
				variables: { processType: "renderer" }
			});
		});
	}
}));
//#endregion
//#region node_modules/electron-log/src/core/scope.js
var require_scope = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	module.exports = scopeFactory;
	function scopeFactory(logger) {
		return Object.defineProperties(scope, {
			defaultLabel: {
				value: "",
				writable: true
			},
			labelPadding: {
				value: true,
				writable: true
			},
			maxLabelLength: {
				value: 0,
				writable: true
			},
			labelLength: { get() {
				switch (typeof scope.labelPadding) {
					case "boolean": return scope.labelPadding ? scope.maxLabelLength : 0;
					case "number": return scope.labelPadding;
					default: return 0;
				}
			} }
		});
		function scope(label) {
			scope.maxLabelLength = Math.max(scope.maxLabelLength, label.length);
			const newScope = {};
			for (const level of logger.levels) newScope[level] = (...d) => logger.logData(d, {
				level,
				scope: label
			});
			newScope.log = newScope.info;
			return newScope;
		}
	}
}));
//#endregion
//#region node_modules/electron-log/src/core/Buffering.js
var require_Buffering = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var Buffering = class {
		constructor({ processMessage }) {
			this.processMessage = processMessage;
			this.buffer = [];
			this.enabled = false;
			this.begin = this.begin.bind(this);
			this.commit = this.commit.bind(this);
			this.reject = this.reject.bind(this);
		}
		addMessage(message) {
			this.buffer.push(message);
		}
		begin() {
			this.enabled = [];
		}
		commit() {
			this.enabled = false;
			this.buffer.forEach((item) => this.processMessage(item));
			this.buffer = [];
		}
		reject() {
			this.enabled = false;
			this.buffer = [];
		}
	};
	module.exports = Buffering;
}));
//#endregion
//#region node_modules/electron-log/src/core/Logger.js
var require_Logger = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var scopeFactory = require_scope();
	var Buffering = require_Buffering();
	module.exports = class Logger {
		static instances = {};
		dependencies = {};
		errorHandler = null;
		eventLogger = null;
		functions = {};
		hooks = [];
		isDev = false;
		levels = null;
		logId = null;
		scope = null;
		transports = {};
		variables = {};
		constructor({ allowUnknownLevel = false, dependencies = {}, errorHandler, eventLogger, initializeFn, isDev = false, levels = [
			"error",
			"warn",
			"info",
			"verbose",
			"debug",
			"silly"
		], logId, transportFactories = {}, variables } = {}) {
			this.addLevel = this.addLevel.bind(this);
			this.create = this.create.bind(this);
			this.initialize = this.initialize.bind(this);
			this.logData = this.logData.bind(this);
			this.processMessage = this.processMessage.bind(this);
			this.allowUnknownLevel = allowUnknownLevel;
			this.buffering = new Buffering(this);
			this.dependencies = dependencies;
			this.initializeFn = initializeFn;
			this.isDev = isDev;
			this.levels = levels;
			this.logId = logId;
			this.scope = scopeFactory(this);
			this.transportFactories = transportFactories;
			this.variables = variables || {};
			for (const name of this.levels) this.addLevel(name, false);
			this.log = this.info;
			this.functions.log = this.log;
			this.errorHandler = errorHandler;
			errorHandler?.setOptions({
				...dependencies,
				logFn: this.error
			});
			this.eventLogger = eventLogger;
			eventLogger?.setOptions({
				...dependencies,
				logger: this
			});
			for (const [name, factory] of Object.entries(transportFactories)) this.transports[name] = factory(this, dependencies);
			Logger.instances[logId] = this;
		}
		static getInstance({ logId }) {
			return this.instances[logId] || this.instances.default;
		}
		addLevel(level, index = this.levels.length) {
			if (index !== false) this.levels.splice(index, 0, level);
			this[level] = (...args) => this.logData(args, { level });
			this.functions[level] = this[level];
		}
		catchErrors(options) {
			this.processMessage({
				data: ["log.catchErrors is deprecated. Use log.errorHandler instead"],
				level: "warn"
			}, { transports: ["console"] });
			return this.errorHandler.startCatching(options);
		}
		create(options) {
			if (typeof options === "string") options = { logId: options };
			return new Logger({
				dependencies: this.dependencies,
				errorHandler: this.errorHandler,
				initializeFn: this.initializeFn,
				isDev: this.isDev,
				transportFactories: this.transportFactories,
				variables: { ...this.variables },
				...options
			});
		}
		compareLevels(passLevel, checkLevel, levels = this.levels) {
			const pass = levels.indexOf(passLevel);
			const check = levels.indexOf(checkLevel);
			if (check === -1 || pass === -1) return true;
			return check <= pass;
		}
		initialize(options = {}) {
			this.initializeFn({
				logger: this,
				...this.dependencies,
				...options
			});
		}
		logData(data, options = {}) {
			if (this.buffering.enabled) this.buffering.addMessage({
				data,
				date: /* @__PURE__ */ new Date(),
				...options
			});
			else this.processMessage({
				data,
				...options
			});
		}
		processMessage(message, { transports = this.transports } = {}) {
			if (message.cmd === "errorHandler") {
				this.errorHandler.handle(message.error, {
					errorName: message.errorName,
					processType: "renderer",
					showDialog: Boolean(message.showDialog)
				});
				return;
			}
			let level = message.level;
			if (!this.allowUnknownLevel) level = this.levels.includes(message.level) ? message.level : "info";
			const normalizedMessage = {
				date: /* @__PURE__ */ new Date(),
				logId: this.logId,
				...message,
				level,
				variables: {
					...this.variables,
					...message.variables
				}
			};
			for (const [transName, transFn] of this.transportEntries(transports)) {
				if (typeof transFn !== "function" || transFn.level === false) continue;
				if (!this.compareLevels(transFn.level, message.level)) continue;
				try {
					const transformedMsg = this.hooks.reduce((msg, hook) => {
						return msg ? hook(msg, transFn, transName) : msg;
					}, normalizedMessage);
					if (transformedMsg) transFn({
						...transformedMsg,
						data: [...transformedMsg.data]
					});
				} catch (e) {
					this.processInternalErrorFn(e);
				}
			}
		}
		processInternalErrorFn(_e) {}
		transportEntries(transports = this.transports) {
			return (Array.isArray(transports) ? transports : Object.entries(transports)).map((item) => {
				switch (typeof item) {
					case "string": return this.transports[item] ? [item, this.transports[item]] : null;
					case "function": return [item.name, item];
					default: return Array.isArray(item) ? item : null;
				}
			}).filter(Boolean);
		}
	};
}));
//#endregion
//#region node_modules/electron-log/src/node/ErrorHandler.js
var require_ErrorHandler = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var ErrorHandler = class {
		externalApi = void 0;
		isActive = false;
		logFn = void 0;
		onError = void 0;
		showDialog = true;
		constructor({ externalApi, logFn = void 0, onError = void 0, showDialog = void 0 } = {}) {
			this.createIssue = this.createIssue.bind(this);
			this.handleError = this.handleError.bind(this);
			this.handleRejection = this.handleRejection.bind(this);
			this.setOptions({
				externalApi,
				logFn,
				onError,
				showDialog
			});
			this.startCatching = this.startCatching.bind(this);
			this.stopCatching = this.stopCatching.bind(this);
		}
		handle(error, { logFn = this.logFn, onError = this.onError, processType = "browser", showDialog = this.showDialog, errorName = "" } = {}) {
			error = normalizeError(error);
			try {
				if (typeof onError === "function") {
					const versions = this.externalApi?.getVersions() || {};
					const createIssue = this.createIssue;
					if (onError({
						createIssue,
						error,
						errorName,
						processType,
						versions
					}) === false) return;
				}
				errorName ? logFn(errorName, error) : logFn(error);
				if (showDialog && !errorName.includes("rejection") && this.externalApi) this.externalApi.showErrorBox(`A JavaScript error occurred in the ${processType} process`, error.stack);
			} catch {
				console.error(error);
			}
		}
		setOptions({ externalApi, logFn, onError, showDialog }) {
			if (typeof externalApi === "object") this.externalApi = externalApi;
			if (typeof logFn === "function") this.logFn = logFn;
			if (typeof onError === "function") this.onError = onError;
			if (typeof showDialog === "boolean") this.showDialog = showDialog;
		}
		startCatching({ onError, showDialog } = {}) {
			if (this.isActive) return;
			this.isActive = true;
			this.setOptions({
				onError,
				showDialog
			});
			process.on("uncaughtException", this.handleError);
			process.on("unhandledRejection", this.handleRejection);
		}
		stopCatching() {
			this.isActive = false;
			process.removeListener("uncaughtException", this.handleError);
			process.removeListener("unhandledRejection", this.handleRejection);
		}
		createIssue(pageUrl, queryParams) {
			this.externalApi?.openUrl(`${pageUrl}?${new URLSearchParams(queryParams).toString()}`);
		}
		handleError(error) {
			this.handle(error, { errorName: "Unhandled" });
		}
		handleRejection(reason) {
			const error = reason instanceof Error ? reason : new Error(JSON.stringify(reason));
			this.handle(error, { errorName: "Unhandled rejection" });
		}
	};
	function normalizeError(e) {
		if (e instanceof Error) return e;
		if (e && typeof e === "object") {
			if (e.message) return Object.assign(new Error(e.message), e);
			try {
				return new Error(JSON.stringify(e));
			} catch (serErr) {
				return /* @__PURE__ */ new Error(`Couldn't normalize error ${String(e)}: ${serErr}`);
			}
		}
		return /* @__PURE__ */ new Error(`Can't normalize error ${String(e)}`);
	}
	module.exports = ErrorHandler;
}));
//#endregion
//#region node_modules/electron-log/src/node/EventLogger.js
var require_EventLogger = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var EventLogger = class {
		disposers = [];
		format = "{eventSource}#{eventName}:";
		formatters = {
			app: {
				"certificate-error": ({ args }) => {
					return this.arrayToObject(args.slice(1, 4), [
						"url",
						"error",
						"certificate"
					]);
				},
				"child-process-gone": ({ args }) => {
					return args.length === 1 ? args[0] : args;
				},
				"render-process-gone": ({ args: [webContents, details] }) => {
					return details && typeof details === "object" ? {
						...details,
						...this.getWebContentsDetails(webContents)
					} : [];
				}
			},
			webContents: {
				"console-message": ({ args: [level, message, line, sourceId] }) => {
					if (level < 3) return;
					return {
						message,
						source: `${sourceId}:${line}`
					};
				},
				"did-fail-load": ({ args }) => {
					return this.arrayToObject(args, [
						"errorCode",
						"errorDescription",
						"validatedURL",
						"isMainFrame",
						"frameProcessId",
						"frameRoutingId"
					]);
				},
				"did-fail-provisional-load": ({ args }) => {
					return this.arrayToObject(args, [
						"errorCode",
						"errorDescription",
						"validatedURL",
						"isMainFrame",
						"frameProcessId",
						"frameRoutingId"
					]);
				},
				"plugin-crashed": ({ args }) => {
					return this.arrayToObject(args, ["name", "version"]);
				},
				"preload-error": ({ args }) => {
					return this.arrayToObject(args, ["preloadPath", "error"]);
				}
			}
		};
		events = {
			app: {
				"certificate-error": true,
				"child-process-gone": true,
				"render-process-gone": true
			},
			webContents: {
				"did-fail-load": true,
				"did-fail-provisional-load": true,
				"plugin-crashed": true,
				"preload-error": true,
				"unresponsive": true
			}
		};
		externalApi = void 0;
		level = "error";
		scope = "";
		constructor(options = {}) {
			this.setOptions(options);
		}
		setOptions({ events, externalApi, level, logger, format, formatters, scope }) {
			if (typeof events === "object") this.events = events;
			if (typeof externalApi === "object") this.externalApi = externalApi;
			if (typeof level === "string") this.level = level;
			if (typeof logger === "object") this.logger = logger;
			if (typeof format === "string" || typeof format === "function") this.format = format;
			if (typeof formatters === "object") this.formatters = formatters;
			if (typeof scope === "string") this.scope = scope;
		}
		startLogging(options = {}) {
			this.setOptions(options);
			this.disposeListeners();
			for (const eventName of this.getEventNames(this.events.app)) this.disposers.push(this.externalApi.onAppEvent(eventName, (...handlerArgs) => {
				this.handleEvent({
					eventSource: "app",
					eventName,
					handlerArgs
				});
			}));
			for (const eventName of this.getEventNames(this.events.webContents)) this.disposers.push(this.externalApi.onEveryWebContentsEvent(eventName, (...handlerArgs) => {
				this.handleEvent({
					eventSource: "webContents",
					eventName,
					handlerArgs
				});
			}));
		}
		stopLogging() {
			this.disposeListeners();
		}
		arrayToObject(array, fieldNames) {
			const obj = {};
			fieldNames.forEach((fieldName, index) => {
				obj[fieldName] = array[index];
			});
			if (array.length > fieldNames.length) obj.unknownArgs = array.slice(fieldNames.length);
			return obj;
		}
		disposeListeners() {
			this.disposers.forEach((disposer) => disposer());
			this.disposers = [];
		}
		formatEventLog({ eventName, eventSource, handlerArgs }) {
			const [event, ...args] = handlerArgs;
			if (typeof this.format === "function") return this.format({
				args,
				event,
				eventName,
				eventSource
			});
			const formatter = this.formatters[eventSource]?.[eventName];
			let formattedArgs = args;
			if (typeof formatter === "function") formattedArgs = formatter({
				args,
				event,
				eventName,
				eventSource
			});
			if (!formattedArgs) return;
			const eventData = {};
			if (Array.isArray(formattedArgs)) eventData.args = formattedArgs;
			else if (typeof formattedArgs === "object") Object.assign(eventData, formattedArgs);
			if (eventSource === "webContents") Object.assign(eventData, this.getWebContentsDetails(event?.sender));
			return [this.format.replace("{eventSource}", eventSource === "app" ? "App" : "WebContents").replace("{eventName}", eventName), eventData];
		}
		getEventNames(eventMap) {
			if (!eventMap || typeof eventMap !== "object") return [];
			return Object.entries(eventMap).filter(([_, listen]) => listen).map(([eventName]) => eventName);
		}
		getWebContentsDetails(webContents) {
			if (!webContents?.loadURL) return {};
			try {
				return { webContents: {
					id: webContents.id,
					url: webContents.getURL()
				} };
			} catch {
				return {};
			}
		}
		handleEvent({ eventName, eventSource, handlerArgs }) {
			const log = this.formatEventLog({
				eventName,
				eventSource,
				handlerArgs
			});
			if (log) (this.scope ? this.logger.scope(this.scope) : this.logger)?.[this.level]?.(...log);
		}
	};
	module.exports = EventLogger;
}));
//#endregion
//#region node_modules/electron-log/src/core/transforms/transform.js
var require_transform = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	module.exports = { transform };
	function transform({ logger, message, transport, initialData = message?.data || [], transforms = transport?.transforms }) {
		return transforms.reduce((data, trans) => {
			if (typeof trans === "function") return trans({
				data,
				logger,
				message,
				transport
			});
			return data;
		}, initialData);
	}
}));
//#endregion
//#region node_modules/electron-log/src/core/transforms/format.js
var require_format = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var { transform } = require_transform();
	module.exports = {
		concatFirstStringElements,
		formatScope,
		formatText,
		formatVariables,
		timeZoneFromOffset,
		format({ message, logger, transport, data = message?.data }) {
			switch (typeof transport.format) {
				case "string": return transform({
					message,
					logger,
					transforms: [
						formatVariables,
						formatScope,
						formatText
					],
					transport,
					initialData: [transport.format, ...data]
				});
				case "function": return transport.format({
					data,
					level: message?.level || "info",
					logger,
					message,
					transport
				});
				default: return data;
			}
		}
	};
	/**
	* The first argument of console.log may contain a template. In the library
	* the first element is a string related to transports.console.format. So
	* this function concatenates first two elements to make templates like %d
	* work
	* @param {*[]} data
	* @return {*[]}
	*/
	function concatFirstStringElements({ data }) {
		if (typeof data[0] !== "string" || typeof data[1] !== "string") return data;
		if (data[0].match(/%[1cdfiOos]/)) return data;
		return [`${data[0]} ${data[1]}`, ...data.slice(2)];
	}
	function timeZoneFromOffset(minutesOffset) {
		const minutesPositive = Math.abs(minutesOffset);
		return `${minutesOffset > 0 ? "-" : "+"}${Math.floor(minutesPositive / 60).toString().padStart(2, "0")}:${(minutesPositive % 60).toString().padStart(2, "0")}`;
	}
	function formatScope({ data, logger, message }) {
		const { defaultLabel, labelLength } = logger?.scope || {};
		const template = data[0];
		let label = message.scope;
		if (!label) label = defaultLabel;
		let scopeText;
		if (label === "") scopeText = labelLength > 0 ? "".padEnd(labelLength + 3) : "";
		else if (typeof label === "string") scopeText = ` (${label})`.padEnd(labelLength + 3);
		else scopeText = "";
		data[0] = template.replace("{scope}", scopeText);
		return data;
	}
	function formatVariables({ data, message }) {
		let template = data[0];
		if (typeof template !== "string") return data;
		template = template.replace("{level}]", `${message.level}]`.padEnd(6, " "));
		const date = message.date || /* @__PURE__ */ new Date();
		data[0] = template.replace(/\{(\w+)}/g, (substring, name) => {
			switch (name) {
				case "level": return message.level || "info";
				case "logId": return message.logId;
				case "y": return date.getFullYear().toString(10);
				case "m": return (date.getMonth() + 1).toString(10).padStart(2, "0");
				case "d": return date.getDate().toString(10).padStart(2, "0");
				case "h": return date.getHours().toString(10).padStart(2, "0");
				case "i": return date.getMinutes().toString(10).padStart(2, "0");
				case "s": return date.getSeconds().toString(10).padStart(2, "0");
				case "ms": return date.getMilliseconds().toString(10).padStart(3, "0");
				case "z": return timeZoneFromOffset(date.getTimezoneOffset());
				case "iso": return date.toISOString();
				default: return message.variables?.[name] || substring;
			}
		}).trim();
		return data;
	}
	function formatText({ data }) {
		const template = data[0];
		if (typeof template !== "string") return data;
		if (template.lastIndexOf("{text}") === template.length - 6) {
			data[0] = template.replace(/\s?{text}/, "");
			if (data[0] === "") data.shift();
			return data;
		}
		const templatePieces = template.split("{text}");
		let result = [];
		if (templatePieces[0] !== "") result.push(templatePieces[0]);
		result = result.concat(data.slice(1));
		if (templatePieces[1] !== "") result.push(templatePieces[1]);
		return result;
	}
}));
//#endregion
//#region node_modules/electron-log/src/node/transforms/object.js
var require_object = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var util = require("util");
	module.exports = {
		serialize,
		maxDepth({ data, transport, depth = transport?.depth ?? 6 }) {
			if (!data) return data;
			if (depth < 1) {
				if (Array.isArray(data)) return "[array]";
				if (typeof data === "object" && data) return "[object]";
				return data;
			}
			if (Array.isArray(data)) return data.map((child) => module.exports.maxDepth({
				data: child,
				depth: depth - 1
			}));
			if (typeof data !== "object") return data;
			if (data && typeof data.toISOString === "function") return data;
			if (data === null) return null;
			if (data instanceof Error) return data;
			const newJson = {};
			for (const i in data) {
				if (!Object.prototype.hasOwnProperty.call(data, i)) continue;
				newJson[i] = module.exports.maxDepth({
					data: data[i],
					depth: depth - 1
				});
			}
			return newJson;
		},
		toJSON({ data }) {
			return JSON.parse(JSON.stringify(data, createSerializer()));
		},
		toString({ data, transport }) {
			const inspectOptions = transport?.inspectOptions || {};
			const simplifiedData = data.map((item) => {
				if (item === void 0) return;
				try {
					const str = JSON.stringify(item, createSerializer(), "  ");
					return str === void 0 ? void 0 : JSON.parse(str);
				} catch (e) {
					return item;
				}
			});
			return util.formatWithOptions(inspectOptions, ...simplifiedData);
		}
	};
	/**
	* @param {object} options?
	* @param {boolean} options.serializeMapAndSet?
	* @return {function}
	*/
	function createSerializer(options = {}) {
		const seen = /* @__PURE__ */ new WeakSet();
		return function(key, value) {
			if (typeof value === "object" && value !== null) {
				if (seen.has(value)) return;
				seen.add(value);
			}
			return serialize(key, value, options);
		};
	}
	/**
	* @param {string} key
	* @param {any} value
	* @param {object} options?
	* @return {any}
	*/
	function serialize(key, value, options = {}) {
		const serializeMapAndSet = options?.serializeMapAndSet !== false;
		if (value instanceof Error) return value.stack;
		if (!value) return value;
		if (typeof value === "function") return `[function] ${value.toString()}`;
		if (value instanceof Date) return value.toISOString();
		if (serializeMapAndSet && value instanceof Map && Object.fromEntries) return Object.fromEntries(value);
		if (serializeMapAndSet && value instanceof Set && Array.from) return Array.from(value);
		return value;
	}
}));
//#endregion
//#region node_modules/electron-log/src/core/transforms/style.js
var require_style = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	module.exports = {
		transformStyles,
		applyAnsiStyles({ data }) {
			return transformStyles(data, styleToAnsi, resetAnsiStyle);
		},
		removeStyles({ data }) {
			return transformStyles(data, () => "");
		}
	};
	var ANSI_COLORS = {
		unset: "\x1B[0m",
		black: "\x1B[30m",
		red: "\x1B[31m",
		green: "\x1B[32m",
		yellow: "\x1B[33m",
		blue: "\x1B[34m",
		magenta: "\x1B[35m",
		cyan: "\x1B[36m",
		white: "\x1B[37m",
		gray: "\x1B[90m"
	};
	function styleToAnsi(style) {
		return ANSI_COLORS[style.replace(/color:\s*(\w+).*/, "$1").toLowerCase()] || "";
	}
	function resetAnsiStyle(string) {
		return string + ANSI_COLORS.unset;
	}
	function transformStyles(data, onStyleFound, onStyleApplied) {
		const foundStyles = {};
		return data.reduce((result, item, index, array) => {
			if (foundStyles[index]) return result;
			if (typeof item === "string") {
				let valueIndex = index;
				let styleApplied = false;
				item = item.replace(/%[1cdfiOos]/g, (match) => {
					valueIndex += 1;
					if (match !== "%c") return match;
					const style = array[valueIndex];
					if (typeof style === "string") {
						foundStyles[valueIndex] = true;
						styleApplied = true;
						return onStyleFound(style, item);
					}
					return match;
				});
				if (styleApplied && onStyleApplied) item = onStyleApplied(item);
			}
			result.push(item);
			return result;
		}, []);
	}
}));
//#endregion
//#region node_modules/electron-log/src/node/transports/console.js
var require_console = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var { concatFirstStringElements, format } = require_format();
	var { maxDepth, toJSON } = require_object();
	var { applyAnsiStyles, removeStyles } = require_style();
	var { transform } = require_transform();
	var consoleMethods = {
		error: console.error,
		warn: console.warn,
		info: console.info,
		verbose: console.info,
		debug: console.debug,
		silly: console.debug,
		log: console.log
	};
	module.exports = consoleTransportFactory;
	var DEFAULT_FORMAT = `%c{h}:{i}:{s}.{ms}{scope}%c ${process.platform === "win32" ? ">" : "›"} {text}`;
	Object.assign(consoleTransportFactory, { DEFAULT_FORMAT });
	function consoleTransportFactory(logger) {
		return Object.assign(transport, {
			colorMap: {
				error: "red",
				warn: "yellow",
				info: "cyan",
				verbose: "unset",
				debug: "gray",
				silly: "gray",
				default: "unset"
			},
			format: DEFAULT_FORMAT,
			level: "silly",
			transforms: [
				addTemplateColors,
				format,
				formatStyles,
				concatFirstStringElements,
				maxDepth,
				toJSON
			],
			useStyles: process.env.FORCE_STYLES,
			writeFn({ message }) {
				(consoleMethods[message.level] || consoleMethods.info)(...message.data);
			}
		});
		function transport(message) {
			const data = transform({
				logger,
				message,
				transport
			});
			transport.writeFn({ message: {
				...message,
				data
			} });
		}
	}
	function addTemplateColors({ data, message, transport }) {
		if (typeof transport.format !== "string" || !transport.format.includes("%c")) return data;
		return [
			`color:${levelToStyle(message.level, transport)}`,
			"color:unset",
			...data
		];
	}
	function canUseStyles(useStyleValue, level) {
		if (typeof useStyleValue === "boolean") return useStyleValue;
		const stream = level === "error" || level === "warn" ? process.stderr : process.stdout;
		return stream && stream.isTTY;
	}
	function formatStyles(args) {
		const { message, transport } = args;
		return (canUseStyles(transport.useStyles, message.level) ? applyAnsiStyles : removeStyles)(args);
	}
	function levelToStyle(level, transport) {
		return transport.colorMap[level] || transport.colorMap.default;
	}
}));
//#endregion
//#region node_modules/electron-log/src/node/transports/file/File.js
var require_File = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var EventEmitter$1 = require("events");
	var fs$5 = require("fs");
	var os$1 = require("os");
	var File = class extends EventEmitter$1 {
		asyncWriteQueue = [];
		bytesWritten = 0;
		hasActiveAsyncWriting = false;
		path = null;
		initialSize = void 0;
		writeOptions = null;
		writeAsync = false;
		constructor({ path, writeOptions = {
			encoding: "utf8",
			flag: "a",
			mode: 438
		}, writeAsync = false }) {
			super();
			this.path = path;
			this.writeOptions = writeOptions;
			this.writeAsync = writeAsync;
		}
		get size() {
			return this.getSize();
		}
		clear() {
			try {
				fs$5.writeFileSync(this.path, "", {
					mode: this.writeOptions.mode,
					flag: "w"
				});
				this.reset();
				return true;
			} catch (e) {
				if (e.code === "ENOENT") return true;
				this.emit("error", e, this);
				return false;
			}
		}
		crop(bytesAfter) {
			try {
				const content = readFileSyncFromEnd(this.path, bytesAfter || 4096);
				this.clear();
				this.writeLine(`[log cropped]${os$1.EOL}${content}`);
			} catch (e) {
				this.emit("error", /* @__PURE__ */ new Error(`Couldn't crop file ${this.path}. ${e.message}`), this);
			}
		}
		getSize() {
			if (this.initialSize === void 0) try {
				this.initialSize = fs$5.statSync(this.path).size;
			} catch (e) {
				this.initialSize = 0;
			}
			return this.initialSize + this.bytesWritten;
		}
		increaseBytesWrittenCounter(text) {
			this.bytesWritten += Buffer.byteLength(text, this.writeOptions.encoding);
		}
		isNull() {
			return false;
		}
		nextAsyncWrite() {
			const file = this;
			if (this.hasActiveAsyncWriting || this.asyncWriteQueue.length === 0) return;
			const text = this.asyncWriteQueue.join("");
			this.asyncWriteQueue = [];
			this.hasActiveAsyncWriting = true;
			fs$5.writeFile(this.path, text, this.writeOptions, (e) => {
				file.hasActiveAsyncWriting = false;
				if (e) file.emit("error", /* @__PURE__ */ new Error(`Couldn't write to ${file.path}. ${e.message}`), this);
				else file.increaseBytesWrittenCounter(text);
				file.nextAsyncWrite();
			});
		}
		reset() {
			this.initialSize = void 0;
			this.bytesWritten = 0;
		}
		toString() {
			return this.path;
		}
		writeLine(text) {
			text += os$1.EOL;
			if (this.writeAsync) {
				this.asyncWriteQueue.push(text);
				this.nextAsyncWrite();
				return;
			}
			try {
				fs$5.writeFileSync(this.path, text, this.writeOptions);
				this.increaseBytesWrittenCounter(text);
			} catch (e) {
				this.emit("error", /* @__PURE__ */ new Error(`Couldn't write to ${this.path}. ${e.message}`), this);
			}
		}
	};
	module.exports = File;
	function readFileSyncFromEnd(filePath, bytesCount) {
		const buffer = Buffer.alloc(bytesCount);
		const stats = fs$5.statSync(filePath);
		const readLength = Math.min(stats.size, bytesCount);
		const offset = Math.max(0, stats.size - bytesCount);
		const fd = fs$5.openSync(filePath, "r");
		const totalBytes = fs$5.readSync(fd, buffer, 0, readLength, offset);
		fs$5.closeSync(fd);
		return buffer.toString("utf8", 0, totalBytes);
	}
}));
//#endregion
//#region node_modules/electron-log/src/node/transports/file/NullFile.js
var require_NullFile = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var File = require_File();
	var NullFile = class extends File {
		clear() {}
		crop() {}
		getSize() {
			return 0;
		}
		isNull() {
			return true;
		}
		writeLine() {}
	};
	module.exports = NullFile;
}));
//#endregion
//#region node_modules/electron-log/src/node/transports/file/FileRegistry.js
var require_FileRegistry = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var EventEmitter = require("events");
	var fs$4 = require("fs");
	var path$5 = require("path");
	var File = require_File();
	var NullFile = require_NullFile();
	var FileRegistry = class extends EventEmitter {
		store = {};
		constructor() {
			super();
			this.emitError = this.emitError.bind(this);
		}
		/**
		* Provide a File object corresponding to the filePath
		* @param {string} filePath
		* @param {WriteOptions} [writeOptions]
		* @param {boolean} [writeAsync]
		* @return {File}
		*/
		provide({ filePath, writeOptions = {}, writeAsync = false }) {
			let file;
			try {
				filePath = path$5.resolve(filePath);
				if (this.store[filePath]) return this.store[filePath];
				file = this.createFile({
					filePath,
					writeOptions,
					writeAsync
				});
			} catch (e) {
				file = new NullFile({ path: filePath });
				this.emitError(e, file);
			}
			file.on("error", this.emitError);
			this.store[filePath] = file;
			return file;
		}
		/**
		* @param {string} filePath
		* @param {WriteOptions} writeOptions
		* @param {boolean} async
		* @return {File}
		* @private
		*/
		createFile({ filePath, writeOptions, writeAsync }) {
			this.testFileWriting({
				filePath,
				writeOptions
			});
			return new File({
				path: filePath,
				writeOptions,
				writeAsync
			});
		}
		/**
		* @param {Error} error
		* @param {File} file
		* @private
		*/
		emitError(error, file) {
			this.emit("error", error, file);
		}
		/**
		* @param {string} filePath
		* @param {WriteOptions} writeOptions
		* @private
		*/
		testFileWriting({ filePath, writeOptions }) {
			fs$4.mkdirSync(path$5.dirname(filePath), { recursive: true });
			fs$4.writeFileSync(filePath, "", {
				flag: "a",
				mode: writeOptions.mode
			});
		}
	};
	module.exports = FileRegistry;
}));
//#endregion
//#region node_modules/electron-log/src/node/transports/file/index.js
var require_file = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var fs$3 = require("fs");
	var os = require("os");
	var path$4 = require("path");
	var FileRegistry = require_FileRegistry();
	var { transform } = require_transform();
	var { removeStyles } = require_style();
	var { format, concatFirstStringElements } = require_format();
	var { toString } = require_object();
	module.exports = fileTransportFactory;
	var globalRegistry = new FileRegistry();
	function fileTransportFactory(logger, { registry = globalRegistry, externalApi } = {}) {
		/** @type {PathVariables} */
		let pathVariables;
		if (registry.listenerCount("error") < 1) registry.on("error", (e, file) => {
			logConsole(`Can't write to ${file}`, e);
		});
		return Object.assign(transport, {
			fileName: getDefaultFileName(logger.variables.processType),
			format: "[{y}-{m}-{d} {h}:{i}:{s}.{ms}] [{level}]{scope} {text}",
			getFile,
			inspectOptions: { depth: 5 },
			level: "silly",
			maxSize: 1024 ** 2,
			readAllLogs,
			sync: true,
			transforms: [
				removeStyles,
				format,
				concatFirstStringElements,
				toString
			],
			writeOptions: {
				flag: "a",
				mode: 438,
				encoding: "utf8"
			},
			archiveLogFn(file) {
				const oldPath = file.toString();
				const inf = path$4.parse(oldPath);
				try {
					fs$3.renameSync(oldPath, path$4.join(inf.dir, `${inf.name}.old${inf.ext}`));
				} catch (e) {
					logConsole("Could not rotate log", e);
					const quarterOfMaxSize = Math.round(transport.maxSize / 4);
					file.crop(Math.min(quarterOfMaxSize, 256 * 1024));
				}
			},
			resolvePathFn(vars) {
				return path$4.join(vars.libraryDefaultDir, vars.fileName);
			},
			setAppName(name) {
				logger.dependencies.externalApi.setAppName(name);
			}
		});
		function transport(message) {
			const file = getFile(message);
			if (transport.maxSize > 0 && file.size > transport.maxSize) {
				transport.archiveLogFn(file);
				file.reset();
			}
			const content = transform({
				logger,
				message,
				transport
			});
			file.writeLine(content);
		}
		function initializeOnFirstAccess() {
			if (pathVariables) return;
			pathVariables = Object.create(Object.prototype, {
				...Object.getOwnPropertyDescriptors(externalApi.getPathVariables()),
				fileName: {
					get() {
						return transport.fileName;
					},
					enumerable: true
				}
			});
			if (typeof transport.archiveLog === "function") {
				transport.archiveLogFn = transport.archiveLog;
				logConsole("archiveLog is deprecated. Use archiveLogFn instead");
			}
			if (typeof transport.resolvePath === "function") {
				transport.resolvePathFn = transport.resolvePath;
				logConsole("resolvePath is deprecated. Use resolvePathFn instead");
			}
		}
		function logConsole(message, error = null, level = "error") {
			const data = [`electron-log.transports.file: ${message}`];
			if (error) data.push(error);
			logger.transports.console({
				data,
				date: /* @__PURE__ */ new Date(),
				level
			});
		}
		function getFile(msg) {
			initializeOnFirstAccess();
			const filePath = transport.resolvePathFn(pathVariables, msg);
			return registry.provide({
				filePath,
				writeAsync: !transport.sync,
				writeOptions: transport.writeOptions
			});
		}
		function readAllLogs({ fileFilter = (f) => f.endsWith(".log") } = {}) {
			initializeOnFirstAccess();
			const logsPath = path$4.dirname(transport.resolvePathFn(pathVariables));
			if (!fs$3.existsSync(logsPath)) return [];
			return fs$3.readdirSync(logsPath).map((fileName) => path$4.join(logsPath, fileName)).filter(fileFilter).map((logPath) => {
				try {
					return {
						path: logPath,
						lines: fs$3.readFileSync(logPath, "utf8").split(os.EOL)
					};
				} catch {
					return null;
				}
			}).filter(Boolean);
		}
	}
	function getDefaultFileName(processType = process.type) {
		switch (processType) {
			case "renderer": return "renderer.log";
			case "worker": return "worker.log";
			default: return "main.log";
		}
	}
}));
//#endregion
//#region node_modules/electron-log/src/node/transports/ipc.js
var require_ipc = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var { maxDepth, toJSON } = require_object();
	var { transform } = require_transform();
	module.exports = ipcTransportFactory;
	/**
	* @param logger
	* @param {ElectronExternalApi} externalApi
	* @returns {transport|null}
	*/
	function ipcTransportFactory(logger, { externalApi }) {
		Object.assign(transport, {
			depth: 3,
			eventId: "__ELECTRON_LOG_IPC__",
			level: logger.isDev ? "silly" : false,
			transforms: [toJSON, maxDepth]
		});
		return externalApi?.isElectron() ? transport : void 0;
		function transport(message) {
			if (message?.variables?.processType === "renderer") return;
			externalApi?.sendIpc(transport.eventId, {
				...message,
				data: transform({
					logger,
					message,
					transport
				})
			});
		}
	}
}));
//#endregion
//#region node_modules/electron-log/src/node/transports/remote.js
var require_remote = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var http = require("http");
	var https = require("https");
	var { transform } = require_transform();
	var { removeStyles } = require_style();
	var { toJSON, maxDepth } = require_object();
	module.exports = remoteTransportFactory;
	function remoteTransportFactory(logger) {
		return Object.assign(transport, {
			client: { name: "electron-application" },
			depth: 6,
			level: false,
			requestOptions: {},
			transforms: [
				removeStyles,
				toJSON,
				maxDepth
			],
			makeBodyFn({ message }) {
				return JSON.stringify({
					client: transport.client,
					data: message.data,
					date: message.date.getTime(),
					level: message.level,
					scope: message.scope,
					variables: message.variables
				});
			},
			processErrorFn({ error }) {
				logger.processMessage({
					data: [`electron-log: can't POST ${transport.url}`, error],
					level: "warn"
				}, { transports: ["console", "file"] });
			},
			sendRequestFn({ serverUrl, requestOptions, body }) {
				const request = (serverUrl.startsWith("https:") ? https : http).request(serverUrl, {
					method: "POST",
					...requestOptions,
					headers: {
						"Content-Type": "application/json",
						"Content-Length": body.length,
						...requestOptions.headers
					}
				});
				request.write(body);
				request.end();
				return request;
			}
		});
		function transport(message) {
			if (!transport.url) return;
			const body = transport.makeBodyFn({
				logger,
				message: {
					...message,
					data: transform({
						logger,
						message,
						transport
					})
				},
				transport
			});
			const request = transport.sendRequestFn({
				serverUrl: transport.url,
				requestOptions: transport.requestOptions,
				body: Buffer.from(body, "utf8")
			});
			request.on("error", (error) => transport.processErrorFn({
				error,
				logger,
				message,
				request,
				transport
			}));
		}
	}
}));
//#endregion
//#region node_modules/electron-log/src/node/createDefaultLogger.js
var require_createDefaultLogger = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var Logger = require_Logger();
	var ErrorHandler = require_ErrorHandler();
	var EventLogger = require_EventLogger();
	var transportConsole = require_console();
	var transportFile = require_file();
	var transportIpc = require_ipc();
	var transportRemote = require_remote();
	module.exports = createDefaultLogger;
	function createDefaultLogger({ dependencies, initializeFn }) {
		const defaultLogger = new Logger({
			dependencies,
			errorHandler: new ErrorHandler(),
			eventLogger: new EventLogger(),
			initializeFn,
			isDev: dependencies.externalApi?.isDev(),
			logId: "default",
			transportFactories: {
				console: transportConsole,
				file: transportFile,
				ipc: transportIpc,
				remote: transportRemote
			},
			variables: { processType: "main" }
		});
		defaultLogger.default = defaultLogger;
		defaultLogger.Logger = Logger;
		defaultLogger.processInternalErrorFn = (e) => {
			defaultLogger.transports.console.writeFn({ message: {
				data: ["Unhandled electron-log error", e],
				level: "error"
			} });
		};
		return defaultLogger;
	}
}));
//#endregion
//#region node_modules/electron-log/src/main/index.js
var require_main$1 = /* @__PURE__ */ __commonJSMin(((exports, module) => {
	var electron$1 = require("electron");
	var ElectronExternalApi = require_ElectronExternalApi();
	var { initialize } = require_initialize();
	var createDefaultLogger = require_createDefaultLogger();
	var externalApi = new ElectronExternalApi({ electron: electron$1 });
	var defaultLogger = createDefaultLogger({
		dependencies: { externalApi },
		initializeFn: initialize
	});
	module.exports = defaultLogger;
	externalApi.onIpc("__ELECTRON_LOG__", (_, message) => {
		if (message.scope) defaultLogger.Logger.getInstance(message).scope(message.scope);
		const date = new Date(message.date);
		processMessage({
			...message,
			date: date.getTime() ? date : /* @__PURE__ */ new Date()
		});
	});
	externalApi.onIpcInvoke("__ELECTRON_LOG__", (_, { cmd = "", logId }) => {
		switch (cmd) {
			case "getOptions": return {
				levels: defaultLogger.Logger.getInstance({ logId }).levels,
				logId
			};
			default:
				processMessage({
					data: [`Unknown cmd '${cmd}'`],
					level: "error"
				});
				return {};
		}
	});
	function processMessage(message) {
		defaultLogger.Logger.getInstance(message)?.processMessage(message);
	}
}));
//#endregion
//#region electron/sqlite.ts
var import_main = /* @__PURE__ */ __toESM((/* @__PURE__ */ __commonJSMin(((exports, module) => {
	module.exports = require_main$1();
})))());
var db = null;
var dbPath = "";
function getDbPath() {
	const userDir = electron.app.getPath("home");
	const valutaDir = node_path.default.join(userDir, ".valuta");
	if (!node_fs.default.existsSync(valutaDir)) try {
		node_fs.default.mkdirSync(valutaDir, { recursive: true });
	} catch (err) {
		const message = err instanceof Error ? err.message : String(err);
		throw new Error(`Nem sikerült létrehozni a valuta mappát: ${valutaDir}. ${message}`, { cause: err });
	}
	return node_path.default.join(valutaDir, "local.db");
}
function resolveWasmPath() {
	const candidates = [];
	if (electron.app.isPackaged) {
		candidates.push(node_path.default.join(process.resourcesPath, "sql-wasm.wasm"));
		candidates.push(node_path.default.join(electron.app.getAppPath(), "resources", "sql-wasm.wasm"));
		candidates.push(node_path.default.join(electron.app.getAppPath(), "sql-wasm.wasm"));
		candidates.push(node_path.default.join(__dirname, "sql-wasm.wasm"));
	} else {
		candidates.push(node_path.default.join(__dirname, "../node_modules/sql.js/dist/sql-wasm.wasm"));
		candidates.push(node_path.default.join(process.cwd(), "node_modules/sql.js/dist/sql-wasm.wasm"));
	}
	for (const candidate of candidates) if (node_fs.default.existsSync(candidate)) return candidate;
	throw new Error(`sql-wasm.wasm nem található. Próbált útvonalak: ${candidates.join(" | ")}`);
}
async function initDatabase() {
	try {
		dbPath = getDbPath();
		const wasmPath = resolveWasmPath();
		const SQL = await (0, sql_js.default)({ wasmBinary: node_fs.default.readFileSync(wasmPath) });
		if (node_fs.default.existsSync(dbPath)) {
			const buffer = node_fs.default.readFileSync(dbPath);
			db = new SQL.Database(buffer);
		} else db = new SQL.Database();
		db.run("PRAGMA foreign_keys = ON;");
		db.run(`
      CREATE TABLE IF NOT EXISTS config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT DEFAULT (datetime('now'))
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS cached_rates (
        currency_code TEXT PRIMARY KEY,
        buy_rate REAL NOT NULL,
        sell_rate REAL NOT NULL,
        unit INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL,
        official_rate REAL,
        limit1_amount REAL,
        limit1_buy_rate REAL,
        limit1_sell_rate REAL,
        limit2_amount REAL,
        limit2_buy_rate REAL,
        limit2_sell_rate REAL,
        limit3_amount REAL,
        limit3_buy_rate REAL,
        limit3_sell_rate REAL
      );
    `);
		for (const col of [
			"official_rate",
			"limit1_amount",
			"limit1_buy_rate",
			"limit1_sell_rate",
			"limit2_amount",
			"limit2_buy_rate",
			"limit2_sell_rate",
			"limit3_amount",
			"limit3_buy_rate",
			"limit3_sell_rate"
		]) try {
			db.run(`ALTER TABLE cached_rates ADD COLUMN ${col} REAL`);
		} catch {}
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('SELL', 'BUY')),
        currency_code TEXT NOT NULL,
        foreign_amount REAL NOT NULL,
        huf_amount REAL NOT NULL,
        rounded_huf_amount REAL NOT NULL,
        rate REAL NOT NULL,
        handling_fee REAL,
        discount_percent REAL,
        customer_id INTEGER,
        customer_identifier TEXT,
        customer_name TEXT,
        customer_document_number TEXT,
        customer_address TEXT,
        denominations TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_conversions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_currency_id INTEGER,
        from_currency_code TEXT NOT NULL,
        to_currency_id INTEGER,
        to_currency_code TEXT NOT NULL,
        from_amount REAL NOT NULL,
        calculated_huf_amount REAL NOT NULL,
        calculated_to_amount REAL NOT NULL,
        conversion_rate REAL NOT NULL,
        handling_fee REAL,
        customer_id TEXT,
        customer_name TEXT,
        customer_document_number TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_bank_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_type TEXT NOT NULL CHECK(transaction_type IN ('BUY', 'SELL')),
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        exchange_rate REAL NOT NULL,
        huf_amount REAL NOT NULL,
        vault_territory_id INTEGER,
        bank_name TEXT,
        bank_reference TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_stornos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        original_receipt_number TEXT NOT NULL,
        original_transaction_type TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        foreign_amount REAL,
        huf_amount REAL NOT NULL,
        exchange_rate REAL,
        reason TEXT NOT NULL,
        approval_id TEXT,
        custom_exchange_rate REAL,
        payment_method TEXT,
        customer_name TEXT,
        customer_document_number TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_handover_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL CHECK(operation_type IN ('GENERATE', 'PRINT', 'COMPLETE')),
        sheet_id TEXT,
        from_cash_desk_id TEXT,
        to_cash_desk_id TEXT,
        transfer_date TEXT,
        amounts_json TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS local_audit_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        event_type TEXT NOT NULL,
        reference_number TEXT,
        entity_id TEXT,
        payload_json TEXT NOT NULL,
        customer_snapshot_json TEXT,
        identification_snapshot_json TEXT,
        rate_snapshot_json TEXT,
        status TEXT NOT NULL DEFAULT 'LOCAL_RECORDED',
        retention_until TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now'))
      );
    `);
		try {
			db.run("ALTER TABLE pending_transactions ADD COLUMN idempotency_key TEXT");
		} catch {}
		for (const colDef of [
			"handling_fee REAL",
			"discount_percent REAL",
			"customer_identifier TEXT",
			"customer_name TEXT",
			"customer_document_number TEXT",
			"customer_address TEXT",
			"local_reference_number TEXT"
		]) try {
			db.run(`ALTER TABLE pending_transactions ADD COLUMN ${colDef}`);
		} catch {}
		db.run(`
      CREATE TABLE IF NOT EXISTS cached_customers (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        document_type TEXT NOT NULL,
        document_number TEXT NOT NULL,
        nationality TEXT,
        birth_date TEXT,
        cached_at TEXT DEFAULT (datetime('now'))
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_branch_id TEXT,
        target_branch_code TEXT NOT NULL,
        currency_id INTEGER,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        huf_value REAL,
        transfer_type TEXT,
        denominations TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_distributions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_branch_code TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        denominations TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS cached_branch_status (
        branch_code TEXT PRIMARY KEY,
        branch_name TEXT NOT NULL,
        company_id INTEGER,
        last_sync_at TEXT,
        online_status TEXT DEFAULT 'offline',
        total_huf_value REAL DEFAULT 0,
        daily_turnover REAL DEFAULT 0,
        cash_balances TEXT,
        cached_at TEXT DEFAULT (datetime('now'))
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS cached_cash_desks (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        company_id TEXT,
        city TEXT,
        is_active INTEGER DEFAULT 1,
        cached_at TEXT DEFAULT (datetime('now'))
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS cached_workers (
        id INTEGER PRIMARY KEY,
        worker_code TEXT,
        full_name TEXT NOT NULL,
        role TEXT,
        branch_id TEXT,
        branch_code TEXT,
        branch_name TEXT,
        company_id TEXT,
        company_code TEXT,
        active INTEGER DEFAULT 1,
        cached_at TEXT DEFAULT (datetime('now'))
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_branch_code TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		for (const colDef of [
			"target_branch_id TEXT",
			"currency_id INTEGER",
			"huf_value REAL",
			"transfer_type TEXT",
			"local_reference_number TEXT",
			"idempotency_key TEXT"
		]) try {
			db.run(`ALTER TABLE pending_transfers ADD COLUMN ${colDef}`);
		} catch {}
		for (const colDef of ["local_reference_number TEXT", "idempotency_key TEXT"]) try {
			db.run(`ALTER TABLE pending_distributions ADD COLUMN ${colDef}`);
		} catch {}
		for (const colDef of ["local_reference_number TEXT", "idempotency_key TEXT"]) try {
			db.run(`ALTER TABLE pending_collections ADD COLUMN ${colDef}`);
		} catch {}
		for (const colDef of [
			"approval_id TEXT",
			"custom_exchange_rate REAL",
			"payment_method TEXT",
			"customer_name TEXT",
			"customer_document_number TEXT",
			"local_reference_number TEXT",
			"idempotency_key TEXT"
		]) try {
			db.run(`ALTER TABLE pending_stornos ADD COLUMN ${colDef}`);
		} catch {}
		for (const colDef of [
			"sheet_id TEXT",
			"from_cash_desk_id TEXT",
			"to_cash_desk_id TEXT",
			"transfer_date TEXT",
			"amounts_json TEXT",
			"note TEXT",
			"local_reference_number TEXT",
			"idempotency_key TEXT"
		]) try {
			db.run(`ALTER TABLE pending_handover_operations ADD COLUMN ${colDef}`);
		} catch {}
		cleanupLocalAuditEvents();
		saveDatabase();
	} catch (err) {
		const error = err;
		const errorCode = "code" in error && error.code ? String(error.code) : "unknown";
		const errorMessage = error instanceof Error ? error.message : String(error);
		const wasmPath = (() => {
			try {
				return resolveWasmPath();
			} catch (resolveErr) {
				return `resolve error: ${resolveErr instanceof Error ? resolveErr.message : String(resolveErr)}`;
			}
		})();
		const details = [
			`dbPath=${dbPath || "n/a"}`,
			`wasmPath=${wasmPath}`,
			`resourcesPath=${process.resourcesPath}`,
			`appPath=${electron.app.getAppPath()}`,
			`isPackaged=${electron.app.isPackaged}`,
			`errorCode=${errorCode}`,
			`errorMessage=${errorMessage}`
		].join("\n");
		throw new Error(`Database init failed:\n${details}`, { cause: err });
	}
}
/**
* Atomi adatbázis mentés — temp fájl + rename pattern.
*
* Ez véd az áramszünet/crash közbeni korrupció ellen:
* 1. Írás temp fájlba (dbPath + '.tmp')
* 2. Rename temp → végleges (atomi művelet a legtöbb fájlrendszeren)
* Ha a rename sikertelen, a temp fájl marad, az eredeti DB érintetlen.
*/
function saveDatabase() {
	if (!db) return;
	const data = db.export();
	const buffer = Buffer.from(data);
	const tmpPath = dbPath + ".tmp";
	try {
		node_fs.default.writeFileSync(tmpPath, buffer);
		node_fs.default.renameSync(tmpPath, dbPath);
	} catch (err) {
		try {
			node_fs.default.unlinkSync(tmpPath);
		} catch {}
		node_fs.default.writeFileSync(dbPath, buffer);
	}
}
function computeRetentionUntil(days = 31) {
	const retentionDate = /* @__PURE__ */ new Date();
	retentionDate.setDate(retentionDate.getDate() + days);
	return retentionDate.toISOString();
}
function generateLocalReference(prefix) {
	return `${prefix}-${(/* @__PURE__ */ new Date()).toISOString().replace(/\D/g, "").slice(0, 14)}-${node_crypto.default.randomBytes(2).toString("hex").toUpperCase()}`;
}
function toJsonOrNull(value) {
	if (value === null || value === void 0) return null;
	return JSON.stringify(value);
}
function saveLocalAuditEvent(params) {
	if (!db) throw new Error("Database not initialized");
	db.run(`INSERT INTO local_audit_events (
      entity_type,
      event_type,
      reference_number,
      entity_id,
      payload_json,
      customer_snapshot_json,
      identification_snapshot_json,
      rate_snapshot_json,
      status,
      retention_until
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		params.entityType,
		params.eventType,
		params.referenceNumber ?? null,
		params.entityId ?? null,
		JSON.stringify(params.payload),
		toJsonOrNull(params.customerSnapshot),
		toJsonOrNull(params.identificationSnapshot),
		toJsonOrNull(params.rateSnapshot),
		params.status ?? "LOCAL_RECORDED",
		computeRetentionUntil(params.retentionDays ?? 31)
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	return row["id"] ?? 0;
}
function getLocalAuditEvents(limit = 200) {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM local_audit_events ORDER BY created_at DESC LIMIT ?");
	stmt.bind([limit]);
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function cleanupLocalAuditEvents(retentionDays = 31) {
	if (!db) return;
	db.run(`DELETE FROM local_audit_events
     WHERE datetime(created_at) < datetime('now', ?)`, [`-${retentionDays} days`]);
}
function getConfig(key) {
	if (!db) return null;
	const stmt = db.prepare("SELECT value FROM config WHERE key = ?");
	stmt.bind([key]);
	if (stmt.step()) {
		const row = stmt.getAsObject();
		stmt.free();
		return row["value"] ?? null;
	}
	stmt.free();
	return null;
}
function setConfig(key, value) {
	if (!db) return;
	if (key.length > 100) throw new Error(`Config key too long: ${key.length} chars (max 100)`);
	if (value.length > 1e4) throw new Error(`Config value too long: ${value.length} chars (max 10000)`);
	db.run(`INSERT INTO config (key, value, updated_at) VALUES (?, ?, datetime('now'))
     ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at`, [key, value]);
	saveDatabase();
}
function deleteConfig(key) {
	if (!db) return;
	db.run("DELETE FROM config WHERE key = ?", [key]);
	saveDatabase();
}
function savePendingTransaction(type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, handlingFee, discountPercent, customerIdentifier, customerName, customerDocumentNumber, customerAddress, denominations) {
	if (!db) throw new Error("Database not initialized");
	const idempotencyKey = node_crypto.default.randomUUID();
	const localReferenceNumber = generateLocalReference(type === "BUY" ? "LB" : "LS");
	const normalizedCustomerIdentifier = customerIdentifier?.trim() || null;
	const normalizedCustomerName = customerName?.trim() || null;
	const normalizedCustomerDocumentNumber = customerDocumentNumber?.trim() || null;
	const normalizedCustomerAddress = customerAddress?.trim() || null;
	db.run(`INSERT INTO pending_transactions (
      type,
      currency_code,
      foreign_amount,
      huf_amount,
      rounded_huf_amount,
      rate,
      handling_fee,
      discount_percent,
      customer_id,
      customer_identifier,
      customer_name,
      customer_document_number,
      customer_address,
      denominations,
      local_reference_number,
      idempotency_key
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		type,
		currencyCode,
		foreignAmount,
		hufAmount,
		roundedHufAmount,
		rate,
		handlingFee,
		discountPercent,
		null,
		normalizedCustomerIdentifier,
		normalizedCustomerName,
		normalizedCustomerDocumentNumber,
		normalizedCustomerAddress,
		denominations,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "TRANSACTION",
		eventType: type,
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			type,
			currencyCode,
			foreignAmount,
			hufAmount,
			roundedHufAmount,
			rate,
			handlingFee,
			discountPercent,
			denominations,
			idempotencyKey
		},
		customerSnapshot: {
			customerIdentifier: normalizedCustomerIdentifier,
			customerName: normalizedCustomerName,
			customerDocumentNumber: normalizedCustomerDocumentNumber,
			customerAddress: normalizedCustomerAddress
		},
		identificationSnapshot: {
			customerIdentifier: normalizedCustomerIdentifier,
			customerDocumentNumber: normalizedCustomerDocumentNumber
		},
		rateSnapshot: {
			currencyCode,
			rate,
			roundedHufAmount
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingTransactions() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_transactions WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) {
		const row = stmt.getAsObject();
		results.push(row);
	}
	stmt.free();
	return results;
}
function savePendingConversion(fromCurrencyId, fromCurrencyCode, toCurrencyId, toCurrencyCode, fromAmount, calculatedHufAmount, calculatedToAmount, conversionRate, handlingFee, customerId, customerName, customerDocumentNumber, note) {
	if (!db) throw new Error("Database not initialized");
	const idempotencyKey = node_crypto.default.randomUUID();
	const localReferenceNumber = generateLocalReference("LC");
	db.run(`INSERT INTO pending_conversions (
      from_currency_id,
      from_currency_code,
      to_currency_id,
      to_currency_code,
      from_amount,
      calculated_huf_amount,
      calculated_to_amount,
      conversion_rate,
      handling_fee,
      customer_id,
      customer_name,
      customer_document_number,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		fromCurrencyId,
		fromCurrencyCode,
		toCurrencyId,
		toCurrencyCode,
		fromAmount,
		calculatedHufAmount,
		calculatedToAmount,
		conversionRate,
		handlingFee,
		customerId?.trim() || null,
		customerName?.trim() || null,
		customerDocumentNumber?.trim() || null,
		note?.trim() || null,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "CONVERSION",
		eventType: "CREATE",
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			fromCurrencyId,
			fromCurrencyCode,
			toCurrencyId,
			toCurrencyCode,
			fromAmount,
			calculatedHufAmount,
			calculatedToAmount,
			conversionRate,
			handlingFee,
			note: note?.trim() || null,
			idempotencyKey
		},
		customerSnapshot: {
			customerId: customerId?.trim() || null,
			customerName: customerName?.trim() || null,
			customerDocumentNumber: customerDocumentNumber?.trim() || null
		},
		identificationSnapshot: {
			customerId: customerId?.trim() || null,
			customerDocumentNumber: customerDocumentNumber?.trim() || null
		},
		rateSnapshot: {
			fromCurrencyCode,
			toCurrencyCode,
			conversionRate,
			calculatedHufAmount,
			calculatedToAmount
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingConversions() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_conversions WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) {
		const row = stmt.getAsObject();
		results.push(row);
	}
	stmt.free();
	return results;
}
function markConversionSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_conversions SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function markTransactionSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_transactions SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function getPendingTransactionCount() {
	if (!db) return 0;
	const stmt = db.prepare("SELECT COUNT(*) as cnt FROM pending_transactions WHERE synced = 0");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	return row["cnt"] ?? 0;
}
function getDb() {
	return db;
}
function savePendingDistribution(targetBranchCode, currencyCode, amount, denominations, note) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference("LD");
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_distributions (
      target_branch_code,
      currency_code,
      amount,
      denominations,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?)`, [
		targetBranchCode,
		currencyCode,
		amount,
		denominations,
		note,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "TREASURY_DISTRIBUTION",
		eventType: "CREATE",
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			targetBranchCode,
			currencyCode,
			amount,
			denominations,
			note,
			idempotencyKey
		},
		rateSnapshot: { currencyCode },
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingDistributions() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_distributions WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markDistributionSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_distributions SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function savePendingTransfer(targetBranchId, targetBranchCode, currencyId, currencyCode, amount, hufValue, transferType, denominations, note) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference("LT");
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_transfers (
      target_branch_id,
      target_branch_code,
      currency_id,
      currency_code,
      amount,
      huf_value,
      transfer_type,
      denominations,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		targetBranchId,
		targetBranchCode,
		currencyId,
		currencyCode,
		amount,
		hufValue,
		transferType,
		denominations,
		note,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "TRANSFER",
		eventType: transferType ?? "CREATE",
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			targetBranchId,
			targetBranchCode,
			currencyId,
			currencyCode,
			amount,
			hufValue,
			transferType,
			denominations,
			note,
			idempotencyKey
		},
		rateSnapshot: {
			currencyCode,
			hufValue
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingTransfers() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_transfers WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markTransferSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_transfers SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function savePendingCollection(sourceBranchCode, currencyCode, amount, note) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference("LCOL");
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_collections (
      source_branch_code,
      currency_code,
      amount,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?)`, [
		sourceBranchCode,
		currencyCode,
		amount,
		note,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "TREASURY_COLLECTION",
		eventType: "CREATE",
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			sourceBranchCode,
			currencyCode,
			amount,
			note,
			idempotencyKey
		},
		rateSnapshot: { currencyCode },
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function savePendingBankTransaction(transactionType, currencyCode, amount, exchangeRate, hufAmount, vaultTerritoryId, bankName, bankReference, note) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference("LBANK");
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_bank_transactions (
      transaction_type,
      currency_code,
      amount,
      exchange_rate,
      huf_amount,
      vault_territory_id,
      bank_name,
      bank_reference,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		transactionType,
		currencyCode,
		amount,
		exchangeRate,
		hufAmount,
		vaultTerritoryId,
		bankName?.trim() || null,
		bankReference?.trim() || null,
		note?.trim() || null,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "BANK_TRANSACTION",
		eventType: transactionType,
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			transactionType,
			currencyCode,
			amount,
			exchangeRate,
			hufAmount,
			vaultTerritoryId,
			bankName: bankName?.trim() || null,
			bankReference: bankReference?.trim() || null,
			note: note?.trim() || null,
			idempotencyKey
		},
		rateSnapshot: {
			currencyCode,
			exchangeRate,
			hufAmount
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingBankTransactions() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_bank_transactions WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markBankTransactionSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_bank_transactions SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function savePendingStorno(params) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference("LST");
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_stornos (
      transaction_id,
      original_receipt_number,
      original_transaction_type,
      currency_code,
      foreign_amount,
      huf_amount,
      exchange_rate,
      reason,
      approval_id,
      custom_exchange_rate,
      payment_method,
      customer_name,
      customer_document_number,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		params.transactionId,
		params.originalReceiptNumber,
		params.originalTransactionType,
		params.currencyCode,
		params.foreignAmount,
		params.hufAmount,
		params.exchangeRate,
		params.reason.trim(),
		params.approvalId ?? null,
		params.customExchangeRate ?? null,
		params.paymentMethod ?? null,
		params.customerName?.trim() || null,
		params.customerDocumentNumber?.trim() || null,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "STORNO",
		eventType: "EXECUTE",
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			transactionId: params.transactionId,
			originalReceiptNumber: params.originalReceiptNumber,
			originalTransactionType: params.originalTransactionType,
			currencyCode: params.currencyCode,
			foreignAmount: params.foreignAmount,
			hufAmount: params.hufAmount,
			exchangeRate: params.exchangeRate,
			reason: params.reason.trim(),
			approvalId: params.approvalId ?? null,
			customExchangeRate: params.customExchangeRate ?? null,
			paymentMethod: params.paymentMethod ?? null,
			idempotencyKey
		},
		customerSnapshot: {
			customerName: params.customerName?.trim() || null,
			customerDocumentNumber: params.customerDocumentNumber?.trim() || null
		},
		identificationSnapshot: { customerDocumentNumber: params.customerDocumentNumber?.trim() || null },
		rateSnapshot: {
			currencyCode: params.currencyCode,
			exchangeRate: params.customExchangeRate ?? params.exchangeRate,
			hufAmount: params.hufAmount
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingStornos() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_stornos WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markStornoSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_stornos SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function savePendingHandoverOperation(params) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference(params.operationType === "GENERATE" ? "LHS" : `LHS-${params.operationType}`);
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_handover_operations (
      operation_type,
      sheet_id,
      from_cash_desk_id,
      to_cash_desk_id,
      transfer_date,
      amounts_json,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		params.operationType,
		params.sheetId ?? null,
		params.fromCashDeskId ?? null,
		params.toCashDeskId ?? null,
		params.transferDate ?? null,
		toJsonOrNull(params.amounts),
		params.note?.trim() || null,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "HANDOVER_SHEET",
		eventType: params.operationType,
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			sheetId: params.sheetId ?? null,
			fromCashDeskId: params.fromCashDeskId ?? null,
			toCashDeskId: params.toCashDeskId ?? null,
			transferDate: params.transferDate ?? null,
			amounts: params.amounts ?? null,
			note: params.note?.trim() || null,
			idempotencyKey
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingHandoverOperations() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_handover_operations WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markHandoverOperationSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_handover_operations SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function getPendingCollections() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_collections WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markCollectionSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_collections SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function saveCachedBranchStatus(branchCode, branchName, companyId, lastSyncAt, onlineStatus, totalHufValue, dailyTurnover, cashBalances) {
	if (!db) return;
	db.run(`INSERT INTO cached_branch_status (branch_code, branch_name, company_id, last_sync_at, online_status, total_huf_value, daily_turnover, cash_balances, cached_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(branch_code) DO UPDATE SET
       branch_name = excluded.branch_name,
       company_id = excluded.company_id,
       last_sync_at = excluded.last_sync_at,
       online_status = excluded.online_status,
       total_huf_value = excluded.total_huf_value,
       daily_turnover = excluded.daily_turnover,
       cash_balances = excluded.cash_balances,
       cached_at = excluded.cached_at`, [
		branchCode,
		branchName,
		companyId,
		lastSyncAt,
		onlineStatus,
		totalHufValue,
		dailyTurnover,
		cashBalances
	]);
	saveDatabase();
}
function getCachedBranchStatuses() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM cached_branch_status ORDER BY branch_code ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function getCachedBranchStatusTimestamp() {
	if (!db) return null;
	const stmt = db.prepare("SELECT MAX(cached_at) as last_cached FROM cached_branch_status");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	return row["last_cached"] ?? null;
}
function saveCachedCashDesk(id, code, name, companyId, city, isActive) {
	if (!db) return;
	db.run(`INSERT INTO cached_cash_desks (id, code, name, company_id, city, is_active, cached_at)
     VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(id) DO UPDATE SET
       code = excluded.code,
       name = excluded.name,
       company_id = excluded.company_id,
       city = excluded.city,
       is_active = excluded.is_active,
       cached_at = excluded.cached_at`, [
		id,
		code,
		name,
		companyId,
		city,
		isActive ? 1 : 0
	]);
	saveDatabase();
}
function getCachedCashDesks() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM cached_cash_desks ORDER BY code ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function getCachedCashDeskTimestamp() {
	if (!db) return null;
	const stmt = db.prepare("SELECT MAX(cached_at) as last_cached FROM cached_cash_desks");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	return row["last_cached"] ?? null;
}
function saveCachedWorker(id, workerCode, fullName, role, branchId, branchCode, branchName, companyId, companyCode, active) {
	if (!db) return;
	db.run(`INSERT INTO cached_workers (id, worker_code, full_name, role, branch_id, branch_code, branch_name, company_id, company_code, active, cached_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(id) DO UPDATE SET
       worker_code = excluded.worker_code,
       full_name = excluded.full_name,
       role = excluded.role,
       branch_id = excluded.branch_id,
       branch_code = excluded.branch_code,
       branch_name = excluded.branch_name,
       company_id = excluded.company_id,
       company_code = excluded.company_code,
       active = excluded.active,
       cached_at = excluded.cached_at`, [
		id,
		workerCode,
		fullName,
		role,
		branchId,
		branchCode,
		branchName,
		companyId,
		companyCode,
		active ? 1 : 0
	]);
	saveDatabase();
}
function getCachedWorkers() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM cached_workers ORDER BY full_name ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function getCachedWorkerTimestamp() {
	if (!db) return null;
	const stmt = db.prepare("SELECT MAX(cached_at) as last_cached FROM cached_workers");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	return row["last_cached"] ?? null;
}
function getCachedRates() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM cached_rates ORDER BY currency_code ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
//#endregion
//#region electron/printer.ts
/**
* Thermal Receipt Printer — Electron main process.
*
* 80mm-es hőnyomtatóra generál bizonylat szöveget ESC/POS parancsokkal,
* illetve HTML formátumban az Electron beépített nyomtató API-ján keresztül.
*
* Nyomtatási architektúra:
*   1. printReceipt() — fő belépési pont, IPC-ből hívva
*   2. Megpróbálja printToThermalUsb()-t (ESC/POS közvetlen USB — jövőbeli)
*   3. Ha nincs USB nyomtató, fallback: printViaElectron() — rejtett ablakban
*      HTML-t renderel és a rendszer nyomtató-driverén keresztül nyomtat
*
* Két cég:
*   - Best Change: Exclusive Best Change Zrt. (adószám: 32313332-2-02)
*   - Expressz: Expressz Ékszerház és Minibank Kft. (adószám: 14040535-2-02)
*/
var ESC = "\x1B";
var GS = "";
var CMD = {
	INIT: `${ESC}@`,
	ALIGN_CENTER: `${ESC}a\x01`,
	ALIGN_LEFT: `${ESC}a\x00`,
	BOLD_ON: `${ESC}E\x01`,
	BOLD_OFF: `${ESC}E\x00`,
	DOUBLE_WIDTH: `${GS}!\x10`,
	DOUBLE_HEIGHT: `${GS}!\x01`,
	DOUBLE_BOTH: `${GS}!\x11`,
	NORMAL_SIZE: `${GS}!\x00`,
	UNDERLINE_ON: `${ESC}-\x01`,
	UNDERLINE_OFF: `${ESC}-\x00`,
	CUT_PAPER: `${GS}V\x00`,
	PARTIAL_CUT: `${GS}V\x01`,
	FEED_LINES: (n) => `${ESC}d${String.fromCharCode(n)}`,
	LINE: "─".repeat(42),
	DOUBLE_LINE: "═".repeat(42)
};
var COMPANIES = {
	BEST_CHANGE: {
		name: "BEST CHANGE",
		fullName: "EXCLUSIVE BEST CHANGE ZRT.",
		taxNumber: "32313332-2-02",
		address: "Szeged, Kárász u. 5."
	},
	EXPRESSZ: {
		name: "EXPRESSZ",
		fullName: "EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT.",
		taxNumber: "14040535-2-02",
		address: "Szeged, Klauzál tér 3."
	}
};
var JOB_TYPE_LABELS = {
	sell: "ELADÁSI BIZONYLAT",
	buy: "VÁSÁRLÁSI BIZONYLAT",
	transfer: "ÁTADÁS-ÁTVÉTELI BIZONYLAT",
	storno: "STORNÓ BIZONYLAT",
	conversion: "KONVERZIÓS BIZONYLAT",
	closing: "NAPI ZÁRÁS"
};
/**
* ESC/POS bizonylat generálása stringként.
* Közvetlen USB hőnyomtató esetén ezt közvetlenül a port-ra kell küldeni.
* Jelenleg a printToThermalUsb() stub használja előkészítésre.
*/
function generateReceiptContent(data) {
	const company = COMPANIES[data.companyType] ?? COMPANIES["BEST_CHANGE"];
	const lines = [];
	lines.push(CMD.INIT);
	lines.push(CMD.ALIGN_CENTER);
	lines.push(CMD.BOLD_ON);
	lines.push(CMD.DOUBLE_BOTH);
	lines.push(company.name);
	lines.push(CMD.NORMAL_SIZE);
	lines.push(company.fullName);
	lines.push(CMD.BOLD_OFF);
	lines.push(company.address);
	lines.push(`Adószám: ${company.taxNumber}`);
	lines.push("");
	lines.push(CMD.DOUBLE_LINE);
	lines.push("");
	lines.push(CMD.BOLD_ON);
	lines.push(CMD.DOUBLE_HEIGHT);
	lines.push(JOB_TYPE_LABELS[data.type]);
	lines.push(CMD.NORMAL_SIZE);
	lines.push(CMD.BOLD_OFF);
	lines.push("");
	lines.push(CMD.ALIGN_LEFT);
	lines.push(`Bizonylat: ${data.receiptNumber}`);
	lines.push(`Dátum:     ${data.date}  ${data.time}`);
	lines.push(`Pénztár:   ${data.branchCode}`);
	lines.push(`Pénztáros: ${data.cashierName}`);
	lines.push("");
	lines.push(CMD.LINE);
	if (data.type === "sell" || data.type === "buy") lines.push(...generateTransactionLines(data));
	else if (data.type === "conversion") lines.push(...generateConversionLines(data));
	else if (data.type === "transfer") lines.push(...generateTransferLines(data));
	else if (data.type === "storno") lines.push(...generateStornoLines(data));
	else if (data.type === "closing") lines.push(...generateClosingLines(data));
	if (data.customerName) {
		lines.push("");
		lines.push(CMD.LINE);
		lines.push(CMD.BOLD_ON);
		lines.push("ÜGYFÉL ADATOK:");
		lines.push(CMD.BOLD_OFF);
		lines.push(`Név:      ${data.customerName}`);
		if (data.customerDocType) lines.push(`Igazolv.: ${data.customerDocType}`);
		if (data.customerDocNumber) lines.push(`Szám:     ${data.customerDocNumber}`);
	}
	if (data.receiptNumber && (data.type === "sell" || data.type === "buy" || data.type === "conversion")) {
		lines.push("");
		lines.push(CMD.LINE);
		lines.push(CMD.ALIGN_CENTER);
		lines.push("");
		lines.push(CMD.BOLD_ON);
		lines.push("QR KÓD:");
		lines.push(CMD.BOLD_OFF);
		const qrContent = [
			data.receiptNumber,
			data.date,
			(data.roundedHufAmount ?? data.hufAmount ?? 0).toString(),
			data.currencyCode ?? "HUF",
			company.taxNumber,
			data.branchCode
		].join("|");
		lines.push(`[QR:${qrContent}]`);
		lines.push("");
	}
	lines.push("");
	lines.push(CMD.DOUBLE_LINE);
	lines.push(CMD.ALIGN_CENTER);
	lines.push("Köszönjük, hogy minket választott!");
	lines.push("");
	lines.push(CMD.FEED_LINES(4));
	lines.push(CMD.PARTIAL_CUT);
	return lines.join("\n");
}
function generateTransactionLines(data) {
	const lines = [];
	const isSell = data.type === "sell";
	lines.push("");
	lines.push(CMD.BOLD_ON);
	lines.push(isSell ? "Deviza eladás (HUF → valuta):" : "Deviza vásárlás (valuta → HUF):");
	lines.push(CMD.BOLD_OFF);
	lines.push("");
	lines.push(`Valutanem:   ${data.currencyCode ?? "—"}`);
	lines.push(`Összeg:      ${formatAmount(data.foreignAmount)} ${data.currencyCode ?? ""}`);
	lines.push(`Árfolyam:    ${formatRate(data.rate)}`);
	lines.push("");
	lines.push(CMD.LINE);
	lines.push(CMD.BOLD_ON);
	lines.push(`HUF összeg:  ${formatAmount(data.hufAmount)} Ft`);
	if (data.roundedHufAmount !== void 0 && data.roundingDiff !== void 0 && data.roundingDiff !== 0) {
		lines.push(`Kerekítés:   ${formatAmount(data.roundingDiff)} Ft`);
		lines.push(CMD.DOUBLE_HEIGHT);
		lines.push(`FIZETENDŐ:   ${formatAmount(data.roundedHufAmount)} Ft`);
		lines.push(CMD.NORMAL_SIZE);
	} else {
		lines.push(CMD.DOUBLE_HEIGHT);
		lines.push(`FIZETENDŐ:   ${formatAmount(data.roundedHufAmount ?? data.hufAmount)} Ft`);
		lines.push(CMD.NORMAL_SIZE);
	}
	lines.push(CMD.BOLD_OFF);
	return lines;
}
function generateTransferLines(data) {
	const lines = [];
	lines.push("");
	lines.push(CMD.BOLD_ON);
	lines.push("Átadás-átvétel:");
	lines.push(CMD.BOLD_OFF);
	lines.push("");
	lines.push(`Cél pénztár: ${data.transferTarget ?? "—"}`);
	lines.push(`Valutanem:   ${data.currencyCode ?? "—"}`);
	lines.push(`Összeg:      ${formatAmount(data.foreignAmount)} ${data.currencyCode ?? ""}`);
	if (data.transferNote) lines.push(`Megjegyzés:  ${data.transferNote}`);
	return lines;
}
function generateConversionLines(data) {
	const lines = [];
	lines.push("");
	lines.push(CMD.BOLD_ON);
	lines.push("Konverzió:");
	lines.push(CMD.BOLD_OFF);
	lines.push("");
	lines.push(`Forrás:      ${formatAmount(data.sourceAmount)} ${data.sourceCurrencyCode ?? "—"}`);
	lines.push(`Cél:         ${formatAmount(data.targetAmount)} ${data.targetCurrencyCode ?? "—"}`);
	lines.push(`Köztes HUF:  ${formatAmount(data.hufAmount)} Ft`);
	lines.push(`Árfolyam:    ${formatRate(data.rate)}`);
	if (data.note) lines.push(`Megjegyzés:  ${data.note}`);
	return lines;
}
function generateStornoLines(data) {
	const lines = [];
	lines.push("");
	lines.push(CMD.BOLD_ON);
	lines.push("STORNÓ:");
	lines.push(CMD.BOLD_OFF);
	lines.push("");
	lines.push(`Eredeti biz.: ${data.originalReceiptNumber ?? "—"}`);
	lines.push(`Valutanem:    ${data.currencyCode ?? "—"}`);
	lines.push(`Összeg:       ${formatAmount(data.foreignAmount)} ${data.currencyCode ?? ""}`);
	lines.push(`HUF összeg:   ${formatAmount(data.hufAmount)} Ft`);
	if (data.stornoReason) {
		lines.push("");
		lines.push(`Indok: ${data.stornoReason}`);
	}
	return lines;
}
function generateClosingLines(data) {
	const lines = [];
	const summary = data.closingSummary;
	if (!summary) {
		lines.push("");
		lines.push("(Nincs zárási adat)");
		return lines;
	}
	lines.push("");
	lines.push(CMD.BOLD_ON);
	lines.push("FORGALMI ÖSSZESÍTŐ:");
	lines.push(CMD.BOLD_OFF);
	lines.push("");
	lines.push(`Összes tranzakció: ${summary.totalTransactions}`);
	lines.push(`  - Eladás:        ${summary.sellCount}`);
	lines.push(`  - Vásárlás:      ${summary.buyCount}`);
	lines.push("");
	lines.push(`HUF forgalom:      ${formatAmount(summary.totalHufTurnover)} Ft`);
	lines.push(`Díjbevétel:        ${formatAmount(summary.totalFees)} Ft`);
	lines.push("");
	lines.push(CMD.LINE);
	lines.push(`Nyitó egyenleg:    ${formatAmount(summary.openingBalance)} Ft`);
	lines.push(`Záró egyenleg:     ${formatAmount(summary.closingBalance)} Ft`);
	if (summary.discrepancies.length > 0) {
		lines.push("");
		lines.push(CMD.BOLD_ON);
		lines.push("ELTÉRÉSEK:");
		lines.push(CMD.BOLD_OFF);
		for (const d of summary.discrepancies) lines.push(`  ${d.currencyCode}: várt ${formatAmount(d.expected)} → tény ${formatAmount(d.actual)} (${formatAmount(d.difference)})`);
	}
	return lines;
}
function formatAmount(value) {
	if (value === void 0) return "—";
	return value.toLocaleString("hu-HU", { maximumFractionDigits: 2 });
}
function formatRate(value) {
	if (value === void 0) return "—";
	return value.toLocaleString("hu-HU", {
		minimumFractionDigits: 2,
		maximumFractionDigits: 4
	});
}
/**
* Bizonylat HTML generálása — 80mm szélességre optimalizált.
* Ezt rendereli a rejtett BrowserWindow a rendszer nyomtató felé.
*/
function generateReceiptHtml(data) {
	const company = COMPANIES[data.companyType] ?? COMPANIES["BEST_CHANGE"];
	const label = JOB_TYPE_LABELS[data.type];
	let bodyContent = "";
	bodyContent += `
    <div class="center">
      <div class="company-name">${escHtml(company.name)}</div>
      <div class="company-full">${escHtml(company.fullName)}</div>
      <div>${escHtml(company.address)}</div>
      <div>Adószám: ${escHtml(company.taxNumber)}</div>
    </div>
    <div class="double-line"></div>
    <div class="center receipt-type">${escHtml(label)}</div>
    <div class="meta">
      <div>Bizonylat: ${escHtml(data.receiptNumber)}</div>
      <div>Dátum: ${escHtml(data.date)} &nbsp; ${escHtml(data.time)}</div>
      <div>Pénztár: ${escHtml(data.branchCode)}</div>
      <div>Pénztáros: ${escHtml(data.cashierName)}</div>
    </div>
    <div class="line"></div>
  `;
	if (data.type === "sell" || data.type === "buy") bodyContent += generateTransactionHtml(data);
	else if (data.type === "transfer") bodyContent += generateTransferHtml(data);
	else if (data.type === "storno") bodyContent += generateStornoHtml(data);
	else if (data.type === "closing") bodyContent += generateClosingHtml(data);
	if (data.customerName) bodyContent += `
      <div class="line"></div>
      <div class="bold">ÜGYFÉL ADATOK:</div>
      <div>Név: ${escHtml(data.customerName)}</div>
      ${data.customerDocType ? `<div>Igazolv.: ${escHtml(data.customerDocType)}</div>` : ""}
      ${data.customerDocNumber ? `<div>Szám: ${escHtml(data.customerDocNumber)}</div>` : ""}
    `;
	bodyContent += `
    <div class="double-line"></div>
    <div class="center footer">Köszönjük, hogy minket választott!</div>
  `;
	return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    @page {
      size: 80mm auto;
      margin: 2mm;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Courier New', monospace;
      font-size: 11px;
      line-height: 1.4;
      width: 76mm;
      color: #000;
    }
    .center { text-align: center; }
    .bold { font-weight: bold; }
    .company-name {
      font-size: 18px;
      font-weight: bold;
    }
    .company-full {
      font-size: 11px;
      font-weight: bold;
    }
    .receipt-type {
      font-size: 14px;
      font-weight: bold;
      margin: 4px 0;
    }
    .meta { margin: 4px 0; }
    .line {
      border-top: 1px dashed #000;
      margin: 6px 0;
    }
    .double-line {
      border-top: 2px solid #000;
      margin: 6px 0;
    }
    .amount-row {
      display: flex;
      justify-content: space-between;
    }
    .total {
      font-size: 14px;
      font-weight: bold;
      margin-top: 4px;
    }
    .section { margin: 6px 0; }
    .footer { margin-top: 8px; font-size: 10px; }
    .discrepancy { color: #c00; font-weight: bold; }
  </style>
</head>
<body>${bodyContent}</body>
</html>`;
}
function generateTransactionHtml(data) {
	let html = `
    <div class="section">
      <div class="bold">${escHtml(data.type === "sell" ? "Deviza eladás (HUF → valuta):" : "Deviza vásárlás (valuta → HUF):")}</div>
      <div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? "—")}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? "")}</span></div>
      <div class="amount-row"><span>Árfolyam:</span><span>${formatRate(data.rate)}</span></div>
    </div>
    <div class="line"></div>
    <div class="amount-row bold"><span>HUF összeg:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>
  `;
	if (data.roundedHufAmount !== void 0 && data.roundingDiff !== void 0 && data.roundingDiff !== 0) html += `
      <div class="amount-row"><span>Kerekítés:</span><span>${formatAmount(data.roundingDiff)} Ft</span></div>
      <div class="amount-row total"><span>FIZETENDŐ:</span><span>${formatAmount(data.roundedHufAmount)} Ft</span></div>
    `;
	else html += `
      <div class="amount-row total"><span>FIZETENDŐ:</span><span>${formatAmount(data.roundedHufAmount ?? data.hufAmount)} Ft</span></div>
    `;
	return html;
}
function generateTransferHtml(data) {
	return `
    <div class="section">
      <div class="bold">Átadás-átvétel:</div>
      <div class="amount-row"><span>Cél pénztár:</span><span>${escHtml(data.transferTarget ?? "—")}</span></div>
      <div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? "—")}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? "")}</span></div>
      ${data.transferNote ? `<div>Megjegyzés: ${escHtml(data.transferNote)}</div>` : ""}
    </div>
  `;
}
function generateStornoHtml(data) {
	return `
    <div class="section">
      <div class="bold">STORNÓ:</div>
      <div class="amount-row"><span>Eredeti biz.:</span><span>${escHtml(data.originalReceiptNumber ?? "—")}</span></div>
      <div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? "—")}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? "")}</span></div>
      <div class="amount-row"><span>HUF összeg:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>
      ${data.stornoReason ? `<div>Indok: ${escHtml(data.stornoReason)}</div>` : ""}
    </div>
  `;
}
function generateClosingHtml(data) {
	const summary = data.closingSummary;
	if (!summary) return "<div class=\"section\">(Nincs zárási adat)</div>";
	let discrepancyHtml = "";
	if (summary.discrepancies.length > 0) discrepancyHtml = `
      <div class="bold discrepancy">ELTÉRÉSEK:</div>
      ${summary.discrepancies.map((d) => `<div class="discrepancy">&nbsp;&nbsp;${escHtml(d.currencyCode)}: várt ${formatAmount(d.expected)} → tény ${formatAmount(d.actual)} (${formatAmount(d.difference)})</div>`).join("")}
    `;
	return `
    <div class="section">
      <div class="bold">FORGALMI ÖSSZESÍTŐ:</div>
      <div class="amount-row"><span>Összes tranzakció:</span><span>${summary.totalTransactions}</span></div>
      <div class="amount-row"><span>&nbsp;&nbsp;- Eladás:</span><span>${summary.sellCount}</span></div>
      <div class="amount-row"><span>&nbsp;&nbsp;- Vásárlás:</span><span>${summary.buyCount}</span></div>
      <br/>
      <div class="amount-row"><span>HUF forgalom:</span><span>${formatAmount(summary.totalHufTurnover)} Ft</span></div>
      <div class="amount-row"><span>Díjbevétel:</span><span>${formatAmount(summary.totalFees)} Ft</span></div>
    </div>
    <div class="line"></div>
    <div class="amount-row"><span>Nyitó egyenleg:</span><span>${formatAmount(summary.openingBalance)} Ft</span></div>
    <div class="amount-row"><span>Záró egyenleg:</span><span>${formatAmount(summary.closingBalance)} Ft</span></div>
    ${discrepancyHtml}
  `;
}
/** Egyszerű HTML escape az XSS elkerülésére. */
function escHtml(str) {
	return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
/**
* Jövőbeli USB hőnyomtató integráció.
* Közvetlen ESC/POS parancsokat küld a nyomtatónak USB-n vagy soros porton.
*
* Aktiváláshoz szükséges:
*   1. `node-thermal-printer` vagy `escpos` npm csomag telepítése
*   2. USB HID driver (libusb) a célgépen
*   3. A PRINTER_CONFIG_KEY konfigba a nyomtató USB vendor/product ID beállítása
*
* @returns true ha sikerült nyomtatni, false ha nincs USB nyomtató (fallback-re vált)
*/
async function printToThermalUsb(_escPosContent) {
	return false;
}
/**
* Nyomtatás Electron beépített webContents.print() API-n keresztül.
* Rejtett BrowserWindow-ban rendereli a bizonylat HTML-t, majd a rendszer
* nyomtató-driverén keresztül kinyomtatja.
*
* @param html - A bizonylat HTML tartalma
* @param printerName - Opcionális nyomtató név; ha nincs megadva, az alapértelmezett nyomtatót használja
* @returns true ha a nyomtatás sikerült
*/
async function printViaElectron(html, printerName) {
	let printWindow = null;
	try {
		printWindow = new electron.BrowserWindow({
			show: false,
			width: 302,
			height: 800,
			webPreferences: {
				contextIsolation: true,
				nodeIntegration: false
			}
		});
		await printWindow.loadURL(`data:text/html;charset=utf-8,${encodeURIComponent(html)}`);
		const printOptions = {
			silent: true,
			printBackground: true,
			margins: { marginType: "none" },
			pageSize: {
				width: 8e4,
				height: 297e3
			}
		};
		if (printerName) printOptions.deviceName = printerName;
		return await new Promise((resolve) => {
			printWindow.webContents.print(printOptions, (success, failureReason) => {
				if (!success) import_main.default.warn(`[PRINTER] Nyomtatás sikertelen: ${failureReason}`);
				resolve(success);
			});
		});
	} catch (err) {
		import_main.default.error("[PRINTER] printViaElectron hiba:", err);
		return false;
	} finally {
		if (printWindow && !printWindow.isDestroyed()) printWindow.close();
	}
}
/**
* Bizonylat nyomtatás — fő belépési pont.
*
* Nyomtatási sorrend:
*   1. Ha USB hőnyomtató konfigurálva van → ESC/POS közvetlen nyomtatás
*   2. Egyébként → Electron webContents.print() rendszer nyomtatón keresztül
*
* Hibajelzések:
*   - Nyomtató offline / nem elérhető → false visszatérés, log üzenet
*   - Papír kifogyott → a rendszer driver kezeli, false visszatérés
*
* @param data - A bizonylat adatai
* @param printerName - Opcionális nyomtató név felülírás
* @returns true ha a nyomtatás sikeresen elindult
*/
async function printReceipt(data, printerName) {
	try {
		import_main.default.info(`[PRINTER] Nyomtatás indítása: ${data.type} ${data.receiptNumber}`);
		if (await printToThermalUsb(generateReceiptContent(data))) {
			import_main.default.info(`[PRINTER] USB hőnyomtató: OK — ${data.receiptNumber}`);
			return true;
		}
		import_main.default.info("[PRINTER] USB nyomtató nem elérhető, Electron print fallback...");
		const electronSuccess = await printViaElectron(generateReceiptHtml(data), printerName);
		if (electronSuccess) import_main.default.info(`[PRINTER] Electron print: OK — ${data.receiptNumber}`);
		else import_main.default.error(`[PRINTER] Nyomtatás sikertelen — ${data.receiptNumber}. Ellenőrizd a nyomtató állapotát (offline / papír kifogyott).`);
		return electronSuccess;
	} catch (err) {
		import_main.default.error("[PRINTER] Váratlan nyomtatási hiba:", err);
		return false;
	}
}
//#endregion
//#region electron/sync-engine.ts
/**
* SyncEngine — Offline → Online szinkronizáció.
*
* Feladatai:
* 1. Pending tranzakciók szinkronizálása (30s intervallum)
* 2. Árfolyamok letöltése és SQLite cache frissítése
* 3. Körlevelek letöltése
*
* Életciklus:
* - app.whenReady() → syncEngine.start()
* - app.on('will-quit') → syncEngine.stop()
*/
var HttpStatusError = class extends Error {
	status;
	constructor(status, statusText) {
		super(`HTTP ${status}: ${statusText}`);
		this.status = status;
	}
};
function isAuthStatusError(err) {
	return err instanceof HttpStatusError && (err.status === 401 || err.status === 403);
}
async function httpGet(url, token) {
	const headers = { "Content-Type": "application/json" };
	if (token) headers["Authorization"] = `Bearer ${token}`;
	const response = await fetch(url, {
		method: "GET",
		headers,
		signal: AbortSignal.timeout(1e4)
	});
	if (!response.ok) throw new HttpStatusError(response.status, response.statusText);
	return response.json();
}
async function httpPost(url, body, token, idempotencyKey) {
	const headers = {
		"Content-Type": "application/json",
		"Idempotency-Key": idempotencyKey ?? crypto.randomUUID()
	};
	if (token) headers["Authorization"] = `Bearer ${token}`;
	const response = await fetch(url, {
		method: "POST",
		headers,
		body: JSON.stringify(body),
		signal: AbortSignal.timeout(15e3)
	});
	if (!response.ok) throw new HttpStatusError(response.status, response.statusText);
	return response.json();
}
var SyncEngine = class {
	intervalId = null;
	lastTokenValidationAt = 0;
	tokenValidationTtlMs = 12e4;
	status = {
		lastSyncAt: null,
		lastSyncResult: null,
		isRunning: false
	};
	getServerUrl() {
		return getConfig("server_url") ?? "http://localhost:8080/api/v1";
	}
	getBootstrapCredentials() {
		const companyCode = process.env.PENZTAR_BOOTSTRAP_COMPANY_CODE?.trim() || getConfig("bootstrap_company_code")?.trim() || "";
		const workerCode = process.env.PENZTAR_BOOTSTRAP_WORKER_CODE?.trim() || getConfig("bootstrap_worker_code")?.trim() || "";
		const password = process.env.PENZTAR_BOOTSTRAP_PASSWORD?.trim() || getConfig("bootstrap_password")?.trim() || "";
		const roleCode = process.env.PENZTAR_BOOTSTRAP_ROLE_CODE?.trim() || getConfig("bootstrap_role_code")?.trim() || null;
		if (!companyCode || !workerCode || !password) return null;
		return {
			companyCode,
			workerCode,
			password,
			roleCode
		};
	}
	persistAuthToken(token) {
		try {
			if (electron.safeStorage.isEncryptionAvailable()) {
				setConfig("auth_token_encrypted", electron.safeStorage.encryptString(token).toString("base64"));
				deleteConfig("auth_token");
				return;
			}
		} catch (err) {
			console.warn("[SyncEngine] Token titkosított mentése nem sikerült, plaintext fallback:", err);
		}
		setConfig("auth_token", token);
	}
	clearStoredAuthToken() {
		deleteConfig("auth_token_encrypted");
		deleteConfig("auth_token");
		this.lastTokenValidationAt = 0;
	}
	async validateToken(serverUrl, token) {
		const now = Date.now();
		if (now - this.lastTokenValidationAt < this.tokenValidationTtlMs) return true;
		try {
			await httpGet(`${serverUrl}/workers/me`, token);
			this.lastTokenValidationAt = now;
			return true;
		} catch (err) {
			if (isAuthStatusError(err)) return false;
			throw err;
		}
	}
	async bootstrapAuthSession(serverUrl) {
		const credentials = this.getBootstrapCredentials();
		if (!credentials) return null;
		try {
			const login = await httpPost(`${serverUrl}/auth/login`, {
				companyCode: credentials.companyCode,
				workerCode: credentials.workerCode,
				password: credentials.password
			}, null);
			let token = login.token;
			if (login.roleSelectionRequired && credentials.roleCode) token = (await httpPost(`${serverUrl}/auth/login/select-role`, {
				token,
				roleCode: credentials.roleCode
			}, null)).token;
			this.persistAuthToken(token);
			this.lastTokenValidationAt = Date.now();
			console.log("[SyncEngine] Lokális auth/session bootstrap sikeres");
			return token;
		} catch (err) {
			if (isAuthStatusError(err)) console.warn("[SyncEngine] Lokális auth bootstrap sikertelen (401/403). Ellenőrizd a bootstrap credentialöket.");
			else console.warn("[SyncEngine] Lokális auth bootstrap hiba:", err instanceof Error ? err.message : err);
			return null;
		}
	}
	getAuthToken() {
		const encryptedToken = getConfig("auth_token_encrypted");
		if (encryptedToken && electron.safeStorage.isEncryptionAvailable()) try {
			return electron.safeStorage.decryptString(Buffer.from(encryptedToken, "base64"));
		} catch (err) {
			console.warn("[SyncEngine] Nem sikerült visszafejteni a tárolt auth tokent:", err);
		}
		return getConfig("auth_token");
	}
	/**
	* Szinkronizáció indítása — periodikus (alapértelmezetten 30s).
	*/
	start(intervalMs = 3e4) {
		if (this.intervalId) {
			console.log("[SyncEngine] Már fut, újraindítás...");
			this.stop();
		}
		console.log(`[SyncEngine] Indítás — ${intervalMs}ms intervallum`);
		setTimeout(() => {
			this.runSync();
		}, 5e3);
		this.intervalId = setInterval(() => {
			this.runSync();
		}, intervalMs);
	}
	/**
	* Szinkronizáció leállítása.
	*/
	stop() {
		if (this.intervalId) {
			clearInterval(this.intervalId);
			this.intervalId = null;
			console.log("[SyncEngine] Leállítva");
		}
	}
	/**
	* Teljes szinkronizálási ciklus futtatása.
	*/
	async runSync() {
		if (this.status.isRunning) {
			console.log("[SyncEngine] Előző sync még fut, kihagyás");
			return;
		}
		this.status.isRunning = true;
		try {
			const serverUrl = this.getServerUrl();
			let token = this.getAuthToken();
			if (token) {
				if (!await this.validateToken(serverUrl, token)) {
					this.clearStoredAuthToken();
					token = await this.bootstrapAuthSession(serverUrl);
				}
			} else token = await this.bootstrapAuthSession(serverUrl);
			const result = await this.syncAll(token);
			this.status.lastSyncResult = result;
			if (result.synced > 0) console.log(`[SyncEngine] ${result.synced} tranzakció szinkronizálva`);
			if (result.failed > 0) console.warn(`[SyncEngine] ${result.failed} tranzakció SIKERTELEN:`, result.errors);
			if (token) {
				await this.syncRates();
				await this.syncCirculars();
				await this.syncDistributions();
				await this.syncTransfers();
				await this.syncCollections();
				await this.cacheBranchStatus();
				await this.syncCashDeskMasterData();
				await this.syncWorkerMasterData();
			}
			this.status.lastSyncAt = (/* @__PURE__ */ new Date()).toISOString();
		} catch (err) {
			console.error("[SyncEngine] Sync hiba:", err);
		} finally {
			this.status.isRunning = false;
		}
	}
	/**
	* Pending tranzakciók szinkronizálása a szerverrel.
	*/
	async syncAll(tokenOverride) {
		const result = {
			synced: 0,
			failed: 0,
			errors: []
		};
		const pendingTransactions = getPendingTransactions();
		const pendingConversions = getPendingConversions();
		const pendingBankTransactions = getPendingBankTransactions();
		const pendingDistributions = getPendingDistributions();
		const pendingTransfers = getPendingTransfers();
		const pendingCollections = getPendingCollections();
		const pendingStornos = getPendingStornos();
		const pendingHandoverOperations = getPendingHandoverOperations();
		const totalPending = pendingTransactions.length + pendingConversions.length + pendingBankTransactions.length + pendingDistributions.length + pendingTransfers.length + pendingCollections.length + pendingStornos.length + pendingHandoverOperations.length;
		if (totalPending === 0) return result;
		const serverUrl = this.getServerUrl();
		const token = tokenOverride ?? this.getAuthToken();
		if (!token) {
			result.errors.push("Nincs auth token — bejelentkezés szükséges");
			result.failed = totalPending;
			return result;
		}
		for (const tx of pendingTransactions) try {
			await this.syncTransaction(serverUrl, token, tx);
			markTransactionSynced(tx.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`TX #${tx.id} (${tx.type} ${tx.currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const conversion of pendingConversions) try {
			await this.syncConversion(serverUrl, token, conversion);
			markConversionSynced(conversion.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`CONV #${conversion.id} (${conversion.from_currency_code}->${conversion.to_currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const bankTransaction of pendingBankTransactions) try {
			await this.syncBankTransaction(serverUrl, token, bankTransaction);
			markBankTransactionSynced(bankTransaction.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`BANK #${bankTransaction.id} (${bankTransaction.transaction_type} ${bankTransaction.currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const distribution of pendingDistributions) try {
			await this.syncDistribution(serverUrl, token, distribution);
			markDistributionSynced(distribution.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`DIST #${distribution.id} (${distribution.currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const transfer of pendingTransfers) try {
			await this.syncTransfer(serverUrl, token, transfer);
			markTransferSynced(transfer.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`TRANSFER #${transfer.id} (${transfer.currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const collection of pendingCollections) try {
			await this.syncCollection(serverUrl, token, collection);
			markCollectionSynced(collection.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`COLLECTION #${collection.id} (${collection.currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const storno of pendingStornos) try {
			await this.syncStorno(serverUrl, token, storno);
			markStornoSynced(storno.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`STORNO #${storno.id} (${storno.original_receipt_number}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const operation of pendingHandoverOperations) try {
			await this.syncHandoverOperation(serverUrl, token, operation);
			markHandoverOperationSynced(operation.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`HANDOVER #${operation.id} (${operation.operation_type}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		return result;
	}
	/**
	* Egyedi tranzakció szinkronizálása.
	*/
	async syncTransaction(serverUrl, token, tx) {
		const endpoint = tx.type === "SELL" ? `${serverUrl}/transactions/sell` : `${serverUrl}/transactions/buy`;
		const body = {
			currencyCode: tx.currency_code,
			currencyAmount: tx.foreign_amount,
			customExchangeRate: tx.rate
		};
		if (tx.handling_fee !== null && tx.handling_fee !== void 0) body["handlingFee"] = tx.handling_fee;
		if (tx.discount_percent !== null && tx.discount_percent !== void 0) body["discountPercent"] = tx.discount_percent;
		const customerIdentifier = tx.customer_identifier ?? (typeof tx.customer_id === "string" ? tx.customer_id : null);
		if (customerIdentifier && customerIdentifier.trim().length > 0) body["customerId"] = customerIdentifier;
		if (tx.customer_name && tx.customer_name.trim().length > 0) body["customerName"] = tx.customer_name;
		if (tx.customer_document_number && tx.customer_document_number.trim().length > 0) body["customerDocumentNumber"] = tx.customer_document_number;
		if (tx.customer_address && tx.customer_address.trim().length > 0) body["customerAddress"] = tx.customer_address;
		if (tx.denominations !== null) try {
			body["denominations"] = JSON.parse(tx.denominations);
		} catch {
			body["denominations"] = tx.denominations;
		}
		await httpPost(endpoint, body, token, tx.idempotency_key ?? void 0);
	}
	async syncConversion(serverUrl, token, conversion) {
		const body = { fromAmount: conversion.from_amount };
		if (conversion.from_currency_id && conversion.from_currency_id > 0) body["fromCurrencyId"] = conversion.from_currency_id;
		else body["fromCurrencyCode"] = conversion.from_currency_code;
		if (conversion.to_currency_id && conversion.to_currency_id > 0) body["toCurrencyId"] = conversion.to_currency_id;
		else body["toCurrencyCode"] = conversion.to_currency_code;
		if (conversion.handling_fee !== null && conversion.handling_fee !== void 0) body["handlingFee"] = conversion.handling_fee;
		if (conversion.customer_id && conversion.customer_id.trim().length > 0) body["customerId"] = conversion.customer_id;
		if (conversion.customer_name && conversion.customer_name.trim().length > 0) body["customerName"] = conversion.customer_name;
		if (conversion.customer_document_number && conversion.customer_document_number.trim().length > 0) body["customerDocumentNumber"] = conversion.customer_document_number;
		await httpPost(`${serverUrl}/transactions/conversion`, body, token, conversion.idempotency_key ?? void 0);
	}
	async syncBankTransaction(serverUrl, token, bankTransaction) {
		const body = {
			transactionType: bankTransaction.transaction_type,
			currencyCode: bankTransaction.currency_code,
			amount: bankTransaction.amount,
			exchangeRate: bankTransaction.exchange_rate
		};
		if (bankTransaction.vault_territory_id !== null && bankTransaction.vault_territory_id !== void 0) body["vaultTerritoryId"] = bankTransaction.vault_territory_id;
		if (bankTransaction.bank_name && bankTransaction.bank_name.trim().length > 0) body["bankName"] = bankTransaction.bank_name;
		if (bankTransaction.bank_reference && bankTransaction.bank_reference.trim().length > 0) body["bankReference"] = bankTransaction.bank_reference;
		if (bankTransaction.note && bankTransaction.note.trim().length > 0) body["note"] = bankTransaction.note;
		await httpPost(`${serverUrl}/ertektar/bank-transactions`, body, token, bankTransaction.idempotency_key ?? void 0);
	}
	async syncStorno(serverUrl, token, storno) {
		const body = {
			transactionId: storno.transaction_id,
			reason: storno.reason
		};
		if (storno.approval_id) body["approvalId"] = storno.approval_id;
		if (storno.custom_exchange_rate !== null && storno.custom_exchange_rate !== void 0) body["customExchangeRate"] = storno.custom_exchange_rate;
		if (storno.payment_method) body["paymentMethodDid"] = storno.payment_method;
		await httpPost(`${serverUrl}/stornos/execute`, body, token, storno.idempotency_key ?? void 0);
	}
	async syncDistribution(serverUrl, token, dist) {
		const body = {
			targetBranchCode: dist.target_branch_code,
			currencyCode: dist.currency_code,
			amount: dist.amount
		};
		if (dist.denominations) try {
			body["denominations"] = JSON.parse(dist.denominations);
		} catch {}
		if (dist.note) body["note"] = dist.note;
		await httpPost(`${serverUrl}/ertektar/distribution`, body, token, dist.idempotency_key ?? void 0);
	}
	async syncTransfer(serverUrl, token, tx) {
		const body = {
			amount: tx.amount,
			targetBranchCode: tx.target_branch_code,
			currencyCode: tx.currency_code
		};
		if (tx.target_branch_id) body["toBranchId"] = tx.target_branch_id;
		if (tx.currency_id !== null && tx.currency_id !== void 0) body["currencyId"] = tx.currency_id;
		if (tx.transfer_type) body["transferType"] = tx.transfer_type;
		if (tx.huf_value !== null && tx.huf_value !== void 0) body["hufValue"] = tx.huf_value;
		if (tx.denominations) try {
			body["denominations"] = JSON.parse(tx.denominations);
		} catch {}
		if (tx.note) body["notes"] = tx.note;
		await httpPost(`${serverUrl}/transfers`, body, token, tx.idempotency_key ?? void 0);
	}
	async syncCollection(serverUrl, token, col) {
		const body = {
			sourceBranchCode: col.source_branch_code,
			currencyCode: col.currency_code,
			amount: col.amount
		};
		if (col.note) body["note"] = col.note;
		await httpPost(`${serverUrl}/ertektar/collections`, body, token, col.idempotency_key ?? void 0);
	}
	async syncHandoverOperation(serverUrl, token, operation) {
		if (operation.operation_type === "GENERATE") {
			await httpPost(`${serverUrl}/handover-sheets/generate`, {
				fromCashDeskId: operation.from_cash_desk_id,
				toCashDeskId: operation.to_cash_desk_id,
				transferDate: operation.transfer_date,
				amounts: operation.amounts_json ? JSON.parse(operation.amounts_json) : {}
			}, token, operation.idempotency_key ?? void 0);
			return;
		}
		if (!operation.sheet_id) throw new Error("Hiányzó handover sheet id");
		await httpPost(operation.operation_type === "PRINT" ? `${serverUrl}/handover-sheets/${operation.sheet_id}/print` : `${serverUrl}/handover-sheets/${operation.sheet_id}/complete`, {}, token, operation.idempotency_key ?? void 0);
	}
	/**
	* Árfolyamok letöltése és SQLite cache frissítése.
	*
	* Legacy: ArfolyamBeolvasas — FTP szerveren lévő NR*.DAT fájl letöltése
	* és a helyi ARFOLYAM tábla frissítése.
	* Új rendszer: REST API-n keresztül kéri le az aktuális árfolyamokat.
	*/
	async syncRates() {
		try {
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			const rates = await httpGet(`${serverUrl}/exchange-rates/pos-current`, token);
			const db = getDb();
			if (!db || !Array.isArray(rates)) return;
			for (const rate of rates) db.run(`INSERT INTO cached_rates (currency_code, buy_rate, sell_rate, unit, updated_at,
             official_rate, limit1_amount, limit1_buy_rate, limit1_sell_rate,
             limit2_amount, limit2_buy_rate, limit2_sell_rate,
             limit3_amount, limit3_buy_rate, limit3_sell_rate)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(currency_code) DO UPDATE SET
             buy_rate = excluded.buy_rate,
             sell_rate = excluded.sell_rate,
             unit = excluded.unit,
             updated_at = excluded.updated_at,
             official_rate = excluded.official_rate,
             limit1_amount = excluded.limit1_amount,
             limit1_buy_rate = excluded.limit1_buy_rate,
             limit1_sell_rate = excluded.limit1_sell_rate,
             limit2_amount = excluded.limit2_amount,
             limit2_buy_rate = excluded.limit2_buy_rate,
             limit2_sell_rate = excluded.limit2_sell_rate,
             limit3_amount = excluded.limit3_amount,
             limit3_buy_rate = excluded.limit3_buy_rate,
             limit3_sell_rate = excluded.limit3_sell_rate`, [
				rate.currencyCode,
				rate.buyRate,
				rate.sellRate,
				rate.unit,
				rate.updatedAt,
				rate.officialRate ?? null,
				rate.limit1Amount ?? null,
				rate.limit1BuyRate ?? null,
				rate.limit1SellRate ?? null,
				rate.limit2Amount ?? null,
				rate.limit2BuyRate ?? null,
				rate.limit2SellRate ?? null,
				rate.limit3Amount ?? null,
				rate.limit3BuyRate ?? null,
				rate.limit3SellRate ?? null
			]);
			saveDatabase();
			console.log(`[SyncEngine] ${rates.length} árfolyam frissítve`);
		} catch (err) {
			if (isAuthStatusError(err)) {
				this.clearStoredAuthToken();
				console.warn("[SyncEngine] Árfolyam sync auth hiba (401/403), session újra-bootstrap szükséges.");
				return;
			}
			console.warn("[SyncEngine] Árfolyam sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Körlevelek letöltése és SQLite-ba mentése.
	*/
	async syncCirculars() {
		try {
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			const circulars = await httpGet(`${serverUrl}/circulars`, token);
			const db = getDb();
			if (!db || !Array.isArray(circulars)) return;
			db.run(`
        CREATE TABLE IF NOT EXISTS cached_circulars (
          id INTEGER PRIMARY KEY,
          subject TEXT NOT NULL,
          body TEXT NOT NULL,
          sender TEXT NOT NULL,
          sent_at TEXT NOT NULL,
          acknowledged INTEGER DEFAULT 0,
          cached_at TEXT DEFAULT (datetime('now'))
        )
      `);
			for (const circular of circulars) db.run(`INSERT INTO cached_circulars (id, subject, body, sender, sent_at)
           VALUES (?, ?, ?, ?, ?)
           ON CONFLICT(id) DO UPDATE SET
             subject = excluded.subject,
             body = excluded.body,
             sender = excluded.sender,
             sent_at = excluded.sent_at`, [
				circular.id,
				circular.subject,
				circular.body,
				circular.sender,
				circular.sentAt
			]);
			if (circulars.length > 0) {
				saveDatabase();
				console.log(`[SyncEngine] ${circulars.length} körlevél szinkronizálva`);
			}
		} catch (err) {
			if (isAuthStatusError(err)) {
				this.clearStoredAuthToken();
				console.warn("[SyncEngine] Körlevél sync auth hiba (401/403), session újra-bootstrap szükséges.");
				return;
			}
			console.warn("[SyncEngine] Körlevél sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Értéktár: Pending distributions szinkronizálása.
	*/
	async syncDistributions() {
		try {
			const pending = getPendingDistributions();
			if (pending.length === 0) return;
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			if (!token) return;
			for (const dist of pending) try {
				const body = {
					targetBranchCode: dist.target_branch_code,
					currencyCode: dist.currency_code,
					amount: dist.amount
				};
				if (dist.denominations) try {
					body["denominations"] = JSON.parse(dist.denominations);
				} catch {}
				if (dist.note) body["note"] = dist.note;
				await httpPost(`${serverUrl}/ertektar/distribution`, body, token, dist.idempotency_key ?? void 0);
				markDistributionSynced(dist.id);
			} catch (err) {
				if (isAuthStatusError(err)) {
					this.clearStoredAuthToken();
					console.warn("[SyncEngine] Distribution auth hiba (401/403), ciklus leállítva.");
					break;
				}
				console.warn(`[SyncEngine] Distribution #${dist.id} sync hiba:`, err instanceof Error ? err.message : err);
				break;
			}
		} catch (err) {
			console.warn("[SyncEngine] Distribution sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Értéktár: Pending transfers szinkronizálása.
	*/
	async syncTransfers() {
		try {
			const pending = getPendingTransfers();
			if (pending.length === 0) return;
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			if (!token) return;
			for (const tx of pending) try {
				const body = { amount: tx.amount };
				if (tx.target_branch_id) body["toBranchId"] = tx.target_branch_id;
				body["targetBranchCode"] = tx.target_branch_code;
				if (tx.currency_id !== null && tx.currency_id !== void 0) body["currencyId"] = tx.currency_id;
				body["currencyCode"] = tx.currency_code;
				if (tx.transfer_type) body["transferType"] = tx.transfer_type;
				if (tx.huf_value !== null && tx.huf_value !== void 0) body["hufValue"] = tx.huf_value;
				if (tx.denominations) try {
					body["denominations"] = JSON.parse(tx.denominations);
				} catch {}
				if (tx.note) body["notes"] = tx.note;
				await httpPost(`${serverUrl}/transfers`, body, token, tx.idempotency_key ?? void 0);
				markTransferSynced(tx.id);
			} catch (err) {
				if (isAuthStatusError(err)) {
					this.clearStoredAuthToken();
					console.warn("[SyncEngine] Transfer auth hiba (401/403), ciklus leállítva.");
					break;
				}
				console.warn(`[SyncEngine] Transfer #${tx.id} sync hiba:`, err instanceof Error ? err.message : err);
				break;
			}
		} catch (err) {
			console.warn("[SyncEngine] Transfer sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Értéktár: Pending collections szinkronizálása.
	*/
	async syncCollections() {
		try {
			const pending = getPendingCollections();
			if (pending.length === 0) return;
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			if (!token) return;
			for (const col of pending) try {
				const body = {
					sourceBranchCode: col.source_branch_code,
					currencyCode: col.currency_code,
					amount: col.amount
				};
				if (col.note) body["note"] = col.note;
				await httpPost(`${serverUrl}/ertektar/collections`, body, token, col.idempotency_key ?? void 0);
				markCollectionSynced(col.id);
			} catch (err) {
				if (isAuthStatusError(err)) {
					this.clearStoredAuthToken();
					console.warn("[SyncEngine] Collection auth hiba (401/403), ciklus leállítva.");
					break;
				}
				console.warn(`[SyncEngine] Collection #${col.id} sync hiba:`, err instanceof Error ? err.message : err);
				break;
			}
		} catch (err) {
			console.warn("[SyncEngine] Collection sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Értéktár: Pénztár státuszok cache-elése.
	*/
	async cacheBranchStatus() {
		try {
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			const branches = await httpGet(`${serverUrl}/ertektar/branches/status`, token);
			if (!Array.isArray(branches)) return;
			for (const branch of branches) saveCachedBranchStatus(branch.code, branch.name, branch.companyId, branch.lastSyncAt, branch.onlineStatus, branch.totalHufValue, branch.dailyTurnover, branch.cashBalances ? JSON.stringify(branch.cashBalances) : null);
			if (branches.length > 0) console.log(`[SyncEngine] ${branches.length} pénztár státusz cache-elve`);
		} catch (err) {
			if (isAuthStatusError(err)) {
				this.clearStoredAuthToken();
				console.warn("[SyncEngine] Branch status auth hiba (401/403), session újra-bootstrap szükséges.");
				return;
			}
			console.warn("[SyncEngine] Branch status cache hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Pénztár törzs (branch master) cache-elése.
	*/
	async syncCashDeskMasterData() {
		try {
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			const cashDesks = await httpGet(`${serverUrl}/branches?activeOnly=true`, token);
			if (!Array.isArray(cashDesks)) return;
			for (const cashDesk of cashDesks) saveCachedCashDesk(cashDesk.id, cashDesk.code, cashDesk.name, cashDesk.companyId ?? null, cashDesk.city ?? null, cashDesk.isActive ?? true);
			if (cashDesks.length > 0) console.log(`[SyncEngine] ${cashDesks.length} pénztár törzs rekord cache-elve`);
		} catch (err) {
			if (isAuthStatusError(err)) {
				this.clearStoredAuthToken();
				console.warn("[SyncEngine] Pénztár törzs sync auth hiba (401/403), session újra-bootstrap szükséges.");
				return;
			}
			console.warn("[SyncEngine] Pénztár törzs sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Dolgozó törzs cache-elése.
	*/
	async syncWorkerMasterData() {
		try {
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			const workers = await httpGet(`${serverUrl}/workers/active`, token);
			if (!Array.isArray(workers)) return;
			for (const worker of workers) saveCachedWorker(worker.id, worker.workerCode ?? null, worker.fullName, worker.role ?? null, worker.branchId ?? null, worker.branchCode ?? null, worker.branchName ?? null, worker.companyId ?? null, worker.companyCode ?? null, worker.active ?? true);
			if (workers.length > 0) console.log(`[SyncEngine] ${workers.length} dolgozó törzs rekord cache-elve`);
		} catch (err) {
			if (isAuthStatusError(err)) {
				this.clearStoredAuthToken();
				console.warn("[SyncEngine] Dolgozó törzs sync auth hiba (401/403), session újra-bootstrap szükséges.");
				return;
			}
			console.warn("[SyncEngine] Dolgozó törzs sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Aktuális szinkronizáció státusz lekérdezése.
	*/
	getStatus() {
		return { ...this.status };
	}
};
/**
* Globális SyncEngine példány — az electron main process-ben használjuk.
*/
var syncEngine = new SyncEngine();
//#endregion
//#region electron/camera.ts
var CAMERA_DIR = "C:/valuta/camera";
function sanitizeId$1(id) {
	const clean = id.replace(/[^a-zA-Z0-9_-]/g, "");
	if (!clean || clean !== id) throw new Error("Invalid transactionId: " + id);
	return clean;
}
function listDirectories(root) {
	if (!node_fs.default.existsSync(root)) return [];
	return node_fs.default.readdirSync(root).filter((entry) => {
		const fullPath = node_path.default.join(root, entry);
		return node_fs.default.existsSync(fullPath) && node_fs.default.statSync(fullPath).isDirectory();
	});
}
function collectFiles(root) {
	if (!node_fs.default.existsSync(root)) return [];
	const result = [];
	const entries = node_fs.default.readdirSync(root, { withFileTypes: true });
	for (const entry of entries) {
		const fullPath = node_path.default.join(root, entry.name);
		if (entry.isDirectory()) result.push(...collectFiles(fullPath));
		else if (entry.isFile()) result.push(fullPath);
	}
	return result;
}
function copyDirectoryWithCount(sourceDir, targetDir) {
	if (!node_fs.default.existsSync(sourceDir)) return 0;
	node_fs.default.mkdirSync(targetDir, { recursive: true });
	let count = 0;
	const entries = node_fs.default.readdirSync(sourceDir, { withFileTypes: true });
	for (const entry of entries) {
		const src = node_path.default.join(sourceDir, entry.name);
		const dest = node_path.default.join(targetDir, entry.name);
		if (entry.isDirectory()) count += copyDirectoryWithCount(src, dest);
		else if (entry.isFile()) {
			node_fs.default.mkdirSync(node_path.default.dirname(dest), { recursive: true });
			node_fs.default.copyFileSync(src, dest);
			count += 1;
		}
	}
	return count;
}
electron.ipcMain.handle("camera-save-recording", async (_event, transactionId, videoBuffer, extension) => {
	const date = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
	const safeId = sanitizeId$1(transactionId);
	const dir = node_path.default.join(CAMERA_DIR, date, safeId);
	node_fs.default.mkdirSync(dir, { recursive: true });
	const filename = `recording_${Date.now()}.${extension}`;
	const filepath = node_path.default.join(dir, filename);
	node_fs.default.writeFileSync(filepath, Buffer.from(videoBuffer));
	return filepath;
});
electron.ipcMain.handle("camera-export-to-usb", async (_event, dateFrom, dateTo) => {
	const result = await electron.dialog.showOpenDialog({
		title: "Válaszd ki az USB meghajtót",
		properties: ["openDirectory"],
		buttonLabel: "Exportálás ide"
	});
	if (result.canceled || !result.filePaths[0]) return {
		success: false,
		exported: 0,
		error: "Megszakítva"
	};
	const from = new Date(dateFrom);
	const to = new Date(dateTo);
	if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) return {
		success: false,
		exported: 0,
		error: "Érvénytelen dátum"
	};
	if (from > to) return {
		success: false,
		exported: 0,
		error: "A dátumtartomány hibás"
	};
	try {
		const targetDir = node_path.default.join(result.filePaths[0], "valuta_kamera_export");
		node_fs.default.mkdirSync(targetDir, { recursive: true });
		let exported = 0;
		const dateDirs = listDirectories(CAMERA_DIR);
		for (const dateDir of dateDirs) {
			const dateValue = new Date(dateDir);
			if (Number.isNaN(dateValue.getTime())) continue;
			if (dateValue < from || dateValue > to) continue;
			const sourceDir = node_path.default.join(CAMERA_DIR, dateDir);
			const destinationDir = node_path.default.join(targetDir, dateDir);
			exported += copyDirectoryWithCount(sourceDir, destinationDir);
		}
		return {
			success: true,
			exported
		};
	} catch (err) {
		return {
			success: false,
			exported: 0,
			error: `Írási hiba: ${err.message}`
		};
	}
});
electron.ipcMain.handle("camera-list-recordings", async (_event, transactionId) => {
	if (!node_fs.default.existsSync(CAMERA_DIR)) return [];
	if (transactionId) {
		const recordings = [];
		const safeId = sanitizeId$1(transactionId);
		const dateDirs = listDirectories(CAMERA_DIR);
		for (const dateDir of dateDirs) {
			const candidateDir = node_path.default.join(CAMERA_DIR, dateDir, safeId);
			recordings.push(...collectFiles(candidateDir));
		}
		return recordings;
	}
	return collectFiles(CAMERA_DIR);
});
function getDirSize(dirPath) {
	if (!node_fs.default.existsSync(dirPath)) return 0;
	let size = 0;
	const entries = node_fs.default.readdirSync(dirPath, { withFileTypes: true });
	for (const entry of entries) {
		const fullPath = node_path.default.join(dirPath, entry.name);
		if (entry.isDirectory()) size += getDirSize(fullPath);
		else if (entry.isFile()) try {
			size += node_fs.default.statSync(fullPath).size;
		} catch {}
	}
	return size;
}
electron.ipcMain.handle("camera-local-storage-stats", async () => {
	if (!node_fs.default.existsSync(CAMERA_DIR)) return {
		totalUsageBytes: 0,
		availableSpaceBytes: 0,
		totalRecordings: 0,
		oldestDate: null,
		newestDate: null
	};
	const totalUsageBytes = getDirSize(CAMERA_DIR);
	const allFiles = collectFiles(CAMERA_DIR);
	const dateDirs = listDirectories(CAMERA_DIR).sort();
	let availableSpaceBytes = 0;
	try {
		const stats = node_fs.default.statfsSync(CAMERA_DIR);
		availableSpaceBytes = Number(stats.bavail) * Number(stats.bsize);
	} catch {}
	return {
		totalUsageBytes,
		availableSpaceBytes,
		totalRecordings: allFiles.length,
		oldestDate: dateDirs.length > 0 ? dateDirs[0] : null,
		newestDate: dateDirs.length > 0 ? dateDirs[dateDirs.length - 1] : null
	};
});
electron.ipcMain.handle("camera-local-recordings-by-date", async (_event, dateFrom, dateTo) => {
	if (!node_fs.default.existsSync(CAMERA_DIR)) return [];
	const from = new Date(dateFrom);
	const to = new Date(dateTo);
	if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) return [];
	const results = [];
	const dateDirs = listDirectories(CAMERA_DIR);
	for (const dateDir of dateDirs) {
		const dirDate = new Date(dateDir);
		if (Number.isNaN(dirDate.getTime())) continue;
		if (dirDate < from || dirDate > to) continue;
		const txDirs = listDirectories(node_path.default.join(CAMERA_DIR, dateDir));
		for (const txDir of txDirs) {
			const files = collectFiles(node_path.default.join(CAMERA_DIR, dateDir, txDir));
			for (const filePath of files) try {
				const stat = node_fs.default.statSync(filePath);
				results.push({
					date: dateDir,
					transactionId: txDir,
					filePath,
					fileSizeBytes: stat.size,
					createdAt: stat.birthtime.toISOString()
				});
			} catch {}
		}
	}
	return results;
});
electron.ipcMain.handle("camera-local-read-file", async (_event, filePath) => {
	const resolved = node_path.default.resolve(filePath);
	if (!resolved.startsWith(node_path.default.resolve(CAMERA_DIR))) return null;
	if (!node_fs.default.existsSync(resolved)) return null;
	return node_fs.default.readFileSync(resolved).toString("base64");
});
electron.ipcMain.handle("camera-local-cleanup", async (_event, retentionDays) => {
	if (!node_fs.default.existsSync(CAMERA_DIR)) return { deletedCount: 0 };
	const cutoff = /* @__PURE__ */ new Date();
	cutoff.setDate(cutoff.getDate() - retentionDays);
	let deletedCount = 0;
	for (const dateDir of listDirectories(CAMERA_DIR)) {
		const dirDate = new Date(dateDir);
		if (Number.isNaN(dirDate.getTime()) || dirDate >= cutoff) continue;
		const dirPath = node_path.default.join(CAMERA_DIR, dateDir);
		const fileCount = collectFiles(dirPath).length;
		try {
			node_fs.default.rmSync(dirPath, {
				recursive: true,
				force: true
			});
			deletedCount += fileCount;
		} catch {}
	}
	return { deletedCount };
});
//#endregion
//#region electron/scanner.ts
var SCAN_DIR = "C:/valuta/scan";
var ENCRYPTION_KEY_FILE = "C:/valuta/.scan_key";
function sanitizeId(id) {
	const clean = id.replace(/[^a-zA-Z0-9_-]/g, "");
	if (!clean || clean !== id) throw new Error("Invalid transactionId: " + id);
	return clean;
}
function getOrCreateKey() {
	if (node_fs.default.existsSync(ENCRYPTION_KEY_FILE)) {
		const stored = node_fs.default.readFileSync(ENCRYPTION_KEY_FILE, "utf8").trim();
		return Buffer.from(stored, "base64");
	}
	const key = node_crypto.default.randomBytes(32);
	node_fs.default.writeFileSync(ENCRYPTION_KEY_FILE, key.toString("base64"), { mode: 384 });
	return key;
}
function encrypt(buffer) {
	const key = getOrCreateKey();
	const iv = node_crypto.default.randomBytes(16);
	const cipher = node_crypto.default.createCipheriv("aes-256-gcm", key, iv);
	const encrypted = Buffer.concat([cipher.update(buffer), cipher.final()]);
	const tag = cipher.getAuthTag();
	return {
		encrypted,
		iv: iv.toString("hex"),
		tag: tag.toString("hex")
	};
}
function decrypt(encrypted, iv, tag) {
	const key = getOrCreateKey();
	const decipher = node_crypto.default.createDecipheriv("aes-256-gcm", key, Buffer.from(iv, "hex"));
	decipher.setAuthTag(Buffer.from(tag, "hex"));
	return Buffer.concat([decipher.update(encrypted), decipher.final()]);
}
electron.ipcMain.handle("scan-save-document", async (_event, transactionId, documentType, imageBase64) => {
	const { encrypted, iv, tag } = encrypt(Buffer.from(imageBase64, "base64"));
	const date = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
	const safeId = sanitizeId(transactionId);
	const dir = node_path.default.join(SCAN_DIR, date, safeId);
	node_fs.default.mkdirSync(dir, { recursive: true });
	const filename = `${documentType}_${Date.now()}.enc`;
	const filepath = node_path.default.join(dir, filename);
	node_fs.default.writeFileSync(filepath, encrypted);
	node_fs.default.writeFileSync(`${filepath}.meta`, JSON.stringify({
		iv,
		tag,
		documentType,
		timestamp: (/* @__PURE__ */ new Date()).toISOString()
	}));
	return {
		path: filepath,
		encrypted: true
	};
});
electron.ipcMain.handle("scan-get-document", async (_event, filepath) => {
	const resolved = node_path.default.resolve(filepath);
	if (!resolved.startsWith(node_path.default.resolve(SCAN_DIR))) throw new Error("Érvénytelen fájlútvonal");
	const encrypted = node_fs.default.readFileSync(resolved);
	const metaRaw = node_fs.default.readFileSync(`${resolved}.meta`, "utf8");
	const meta = JSON.parse(metaRaw);
	return decrypt(encrypted, meta.iv, meta.tag).toString("base64");
});
electron.ipcMain.handle("scan-list-documents", async (_event, transactionId) => {
	if (!node_fs.default.existsSync(SCAN_DIR)) return [];
	const results = [];
	const safeId = sanitizeId(transactionId);
	const dateDirs = node_fs.default.readdirSync(SCAN_DIR);
	for (const dateDir of dateDirs) {
		const candidate = node_path.default.join(SCAN_DIR, dateDir, safeId);
		if (!node_fs.default.existsSync(candidate) || !node_fs.default.statSync(candidate).isDirectory()) continue;
		const files = node_fs.default.readdirSync(candidate);
		for (const file of files) if (file.endsWith(".enc")) results.push(node_path.default.join(candidate, file));
	}
	return results;
});
//#endregion
//#region electron/updater.ts
electron.ipcMain.handle("restart-app", () => {
	try {
		electron.app.relaunch();
		electron.app.exit(0);
		return true;
	} catch (err) {
		import_main.default.error("[Updater] restart-app failed", err);
		return false;
	}
});
//#endregion
//#region electron/main.ts
var isDev = !electron.app.isPackaged;
electron.protocol.registerSchemesAsPrivileged([{
	scheme: "app",
	privileges: {
		standard: true,
		secure: true,
		supportFetchAPI: true,
		corsEnabled: true,
		stream: true
	}
}]);
import_main.default.initialize();
import_main.default.transports.file.level = "info";
import_main.default.transports.console.level = isDev ? "debug" : "warn";
process.on("uncaughtException", (err) => {
	import_main.default.error("[Process] uncaughtException", err);
});
process.on("unhandledRejection", (reason) => {
	import_main.default.error("[Process] unhandledRejection", reason);
});
var mainWindow = null;
function createWindow() {
	mainWindow = new electron.BrowserWindow({
		width: 1280,
		height: 1024,
		resizable: isDev,
		fullscreen: false,
		autoHideMenuBar: true,
		title: "Valuta Pénztár",
		webPreferences: {
			preload: node_path.default.join(__dirname, "preload.js"),
			contextIsolation: true,
			nodeIntegration: false,
			sandbox: true,
			webSecurity: true,
			allowRunningInsecureContent: false,
			experimentalFeatures: false
		}
	});
	if (isDev) {
		mainWindow.loadURL("http://localhost:3000");
		mainWindow.webContents.openDevTools({ mode: "detach" });
	} else mainWindow.loadURL("app://localhost/index.html");
	mainWindow.webContents.on("console-message", (_event, level, message, line, sourceId) => {
		if (level >= 2) import_main.default.warn(`[Renderer] L${level} ${sourceId}:${line} — ${message}`);
	});
	mainWindow.webContents.on("render-process-gone", (_event, details) => {
		import_main.default.error("[Renderer] Process gone:", details.reason);
		electron.dialog.showErrorBox("Megjelenítési hiba", `A program megjelenítő folyamata leállt.\nOk: ${details.reason}\n\nKérjük, indítsa újra az alkalmazást.`);
	});
	mainWindow.webContents.on("before-input-event", (_event, input) => {
		if (input.key === "F12" && input.type === "keyDown") mainWindow?.webContents.toggleDevTools();
	});
	mainWindow.webContents.on("will-navigate", (event, url) => {
		if (!["app://localhost", "http://localhost:3000"].some((origin) => url.startsWith(origin))) {
			import_main.default.warn(`[Security] Blocked navigation to: ${url}`);
			event.preventDefault();
		}
	});
	mainWindow.webContents.setWindowOpenHandler(({ url }) => {
		import_main.default.warn(`[Security] Blocked popup window: ${url}`);
		return { action: "deny" };
	});
	mainWindow.on("closed", () => {
		mainWindow = null;
	});
}
electron.ipcMain.handle("print-receipt", async (_event, dataJson) => {
	try {
		return await printReceipt(JSON.parse(dataJson));
	} catch (err) {
		console.error("[IPC] print-receipt hiba:", err);
		return false;
	}
});
electron.ipcMain.handle("get-config", async (_event, key) => {
	return getConfig(key);
});
electron.ipcMain.handle("set-config", async (_event, key, value) => {
	setConfig(key, value);
});
electron.ipcMain.handle("delete-config", async (_event, key) => {
	deleteConfig(key);
});
electron.ipcMain.handle("save-pending-transaction", async (_event, type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, handlingFee, discountPercent, customerIdentifier, customerName, customerDocumentNumber, customerAddress, denominations) => {
	return savePendingTransaction(type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, handlingFee, discountPercent, customerIdentifier, customerName, customerDocumentNumber, customerAddress, denominations);
});
electron.ipcMain.handle("get-pending-transactions", async () => {
	return getPendingTransactions();
});
electron.ipcMain.handle("save-pending-conversion", async (_event, fromCurrencyId, fromCurrencyCode, toCurrencyId, toCurrencyCode, fromAmount, calculatedHufAmount, calculatedToAmount, conversionRate, handlingFee, customerId, customerName, customerDocumentNumber, note) => {
	return savePendingConversion(fromCurrencyId, fromCurrencyCode, toCurrencyId, toCurrencyCode, fromAmount, calculatedHufAmount, calculatedToAmount, conversionRate, handlingFee, customerId, customerName, customerDocumentNumber, note);
});
electron.ipcMain.handle("get-pending-conversions", async () => {
	return getPendingConversions();
});
electron.ipcMain.handle("save-pending-bank-transaction", async (_event, transactionType, currencyCode, amount, exchangeRate, hufAmount, vaultTerritoryId, bankName, bankReference, note) => {
	return savePendingBankTransaction(transactionType, currencyCode, amount, exchangeRate, hufAmount, vaultTerritoryId, bankName, bankReference, note);
});
electron.ipcMain.handle("get-pending-bank-transactions", async () => {
	return getPendingBankTransactions();
});
electron.ipcMain.handle("save-pending-storno", async (_event, payload) => {
	return savePendingStorno(payload);
});
electron.ipcMain.handle("get-pending-stornos", async () => {
	return getPendingStornos();
});
electron.ipcMain.handle("get-pending-transaction-count", async () => {
	return getPendingTransactionCount();
});
electron.ipcMain.handle("mark-transaction-synced", async (_event, id) => {
	markTransactionSynced(id);
});
electron.ipcMain.handle("mark-conversion-synced", async (_event, id) => {
	markConversionSynced(id);
});
electron.ipcMain.handle("mark-bank-transaction-synced", async (_event, id) => {
	markBankTransactionSynced(id);
});
electron.ipcMain.handle("mark-storno-synced", async (_event, id) => {
	markStornoSynced(id);
});
electron.ipcMain.handle("sync-offline", async () => {
	return (await syncEngine.syncAll()).synced;
});
electron.ipcMain.handle("get-sync-status", async () => {
	return JSON.stringify(syncEngine.getStatus());
});
electron.ipcMain.handle("get-app-version", async () => {
	return electron.app.getVersion();
});
electron.ipcMain.handle("get-printers", async () => {
	if (!mainWindow) return [];
	return mainWindow.webContents.getPrintersAsync();
});
electron.ipcMain.handle("save-pending-distribution", async (_event, targetBranchCode, currencyCode, amount, denominations, note) => {
	return savePendingDistribution(targetBranchCode, currencyCode, amount, denominations, note);
});
electron.ipcMain.handle("save-pending-transfer", async (_event, targetBranchId, targetBranchCode, currencyId, currencyCode, amount, hufValue, transferType, denominations, note) => {
	return savePendingTransfer(targetBranchId, targetBranchCode, currencyId, currencyCode, amount, hufValue, transferType, denominations, note);
});
electron.ipcMain.handle("get-pending-transfers", async () => {
	return getPendingTransfers();
});
electron.ipcMain.handle("save-pending-collection", async (_event, sourceBranchCode, currencyCode, amount, note) => {
	return savePendingCollection(sourceBranchCode, currencyCode, amount, note);
});
electron.ipcMain.handle("save-pending-handover-operation", async (_event, payload) => {
	return savePendingHandoverOperation(payload);
});
electron.ipcMain.handle("get-pending-handover-operations", async () => {
	return getPendingHandoverOperations();
});
electron.ipcMain.handle("get-cached-branch-statuses", async () => {
	return getCachedBranchStatuses();
});
electron.ipcMain.handle("get-cached-branch-status-timestamp", async () => {
	return getCachedBranchStatusTimestamp();
});
electron.ipcMain.handle("get-cached-rates", async () => {
	return getCachedRates();
});
electron.ipcMain.handle("get-cached-cash-desks", async () => {
	return getCachedCashDesks();
});
electron.ipcMain.handle("get-cached-cash-desk-timestamp", async () => {
	return getCachedCashDeskTimestamp();
});
electron.ipcMain.handle("get-cached-workers", async () => {
	return getCachedWorkers();
});
electron.ipcMain.handle("get-cached-worker-timestamp", async () => {
	return getCachedWorkerTimestamp();
});
electron.ipcMain.handle("save-local-audit-event", async (_event, payload) => {
	return saveLocalAuditEvent(payload);
});
electron.ipcMain.handle("get-local-audit-events", async (_event, limit) => {
	return getLocalAuditEvents(limit ?? 200);
});
electron.ipcMain.handle("secure-store-token", async (_event, token) => {
	try {
		if (!electron.safeStorage.isEncryptionAvailable()) {
			import_main.default.warn("[SafeStorage] Encryption not available, falling back to config store");
			setConfig("auth_token", token);
			return true;
		}
		setConfig("auth_token_encrypted", electron.safeStorage.encryptString(token).toString("base64"));
		deleteConfig("auth_token");
		return true;
	} catch (err) {
		import_main.default.error("[SafeStorage] store-token error:", err);
		return false;
	}
});
electron.ipcMain.handle("secure-load-token", async () => {
	try {
		const encrypted = getConfig("auth_token_encrypted");
		if (encrypted && electron.safeStorage.isEncryptionAvailable()) {
			const buffer = Buffer.from(encrypted, "base64");
			return electron.safeStorage.decryptString(buffer);
		}
		const plaintext = getConfig("auth_token");
		if (plaintext) {
			import_main.default.info("[SafeStorage] Migrating plaintext token to encrypted storage");
			if (electron.safeStorage.isEncryptionAvailable()) {
				setConfig("auth_token_encrypted", electron.safeStorage.encryptString(plaintext).toString("base64"));
				deleteConfig("auth_token");
			}
			return plaintext;
		}
		return null;
	} catch (err) {
		import_main.default.error("[SafeStorage] load-token error:", err);
		return null;
	}
});
electron.ipcMain.handle("secure-clear-token", async () => {
	deleteConfig("auth_token_encrypted");
	deleteConfig("auth_token");
});
electron.app.whenReady().then(async () => {
	const distPath = node_path.default.join(__dirname, "../dist");
	electron.protocol.handle("app", (req) => {
		const url = new URL(req.url);
		let filePath = node_path.default.join(distPath, decodeURIComponent(url.pathname));
		if (url.pathname === "/" || url.pathname === "") filePath = node_path.default.join(distPath, "index.html");
		if (!(node_path.default.extname(filePath) !== "")) filePath = node_path.default.join(distPath, "index.html");
		const resolved = node_path.default.resolve(filePath);
		const resolvedDist = node_path.default.resolve(distPath);
		if (!resolved.startsWith(resolvedDist + node_path.default.sep) && resolved !== resolvedDist) {
			import_main.default.warn(`[Protocol] Path traversal blokkolva: ${req.url} → ${resolved}`);
			filePath = node_path.default.join(distPath, "index.html");
		}
		import_main.default.info(`[Protocol] ${req.url} → ${filePath}`);
		return electron.net.fetch((0, node_url.pathToFileURL)(filePath).toString());
	});
	import_main.default.info("[App] Custom \"app\" protocol regisztrálva, distPath:", distPath);
	try {
		await initDatabase();
	} catch (err) {
		import_main.default.error("[App] initDatabase failed", err);
		const details = err instanceof Error ? err.message : String(err);
		electron.dialog.showErrorBox("Adatbázis hiba", `A helyi adatbázist nem sikerült inicializálni.\n\nRészletek:\n${details}`);
		electron.app.quit();
		return;
	}
	createWindow();
	syncEngine.start(3e4);
	import_main.default.info("[App] SyncEngine elindítva");
});
electron.app.on("will-quit", () => {
	syncEngine.stop();
	import_main.default.info("[App] SyncEngine leállítva");
});
electron.app.on("window-all-closed", () => {
	electron.app.quit();
});
electron.app.on("activate", () => {
	if (mainWindow === null) createWindow();
});
//#endregion
