"use strict";
var __defProp = Object.defineProperty;
var __defNormalProp = (obj, key, value) => key in obj ? __defProp(obj, key, { enumerable: true, configurable: true, writable: true, value }) : obj[key] = value;
var __publicField = (obj, key, value) => __defNormalProp(obj, typeof key !== "symbol" ? key + "" : key, value);
const require$$0$5 = require("electron");
const require$$2 = require("path");
const require$$0$1 = require("child_process");
const require$$1 = require("os");
const require$$0 = require("fs");
const require$$0$2 = require("util");
const require$$0$3 = require("events");
const require$$0$4 = require("http");
const require$$1$1 = require("https");
const path = require("node:path");
const initSqlJs = require("sql.js");
const fs = require("node:fs");
const crypto = require("node:crypto");
function getDefaultExportFromCjs(x) {
  return x && x.__esModule && Object.prototype.hasOwnProperty.call(x, "default") ? x["default"] : x;
}
var packageJson;
var hasRequiredPackageJson;
function requirePackageJson() {
  if (hasRequiredPackageJson) return packageJson;
  hasRequiredPackageJson = 1;
  const fs2 = require$$0;
  const path2 = require$$2;
  packageJson = {
    findAndReadPackageJson,
    tryReadJsonAt
  };
  function findAndReadPackageJson() {
    return tryReadJsonAt(getMainModulePath()) || tryReadJsonAt(extractPathFromArgs()) || tryReadJsonAt(process.resourcesPath, "app.asar") || tryReadJsonAt(process.resourcesPath, "app") || tryReadJsonAt(process.cwd()) || { name: void 0, version: void 0 };
  }
  function tryReadJsonAt(...searchPaths) {
    if (!searchPaths[0]) {
      return void 0;
    }
    try {
      const searchPath = path2.join(...searchPaths);
      const fileName = findUp("package.json", searchPath);
      if (!fileName) {
        return void 0;
      }
      const json = JSON.parse(fs2.readFileSync(fileName, "utf8"));
      const name = (json == null ? void 0 : json.productName) || (json == null ? void 0 : json.name);
      if (!name || name.toLowerCase() === "electron") {
        return void 0;
      }
      if (name) {
        return { name, version: json == null ? void 0 : json.version };
      }
      return void 0;
    } catch (e) {
      return void 0;
    }
  }
  function findUp(fileName, cwd) {
    let currentPath = cwd;
    while (true) {
      const parsedPath = path2.parse(currentPath);
      const root = parsedPath.root;
      const dir = parsedPath.dir;
      if (fs2.existsSync(path2.join(currentPath, fileName))) {
        return path2.resolve(path2.join(currentPath, fileName));
      }
      if (currentPath === root) {
        return null;
      }
      currentPath = dir;
    }
  }
  function extractPathFromArgs() {
    const matchedArgs = process.argv.filter((arg) => {
      return arg.indexOf("--user-data-dir=") === 0;
    });
    if (matchedArgs.length === 0 || typeof matchedArgs[0] !== "string") {
      return null;
    }
    const userDataDir = matchedArgs[0];
    return userDataDir.replace("--user-data-dir=", "");
  }
  function getMainModulePath() {
    var _a;
    try {
      return (_a = require.main) == null ? void 0 : _a.filename;
    } catch {
      return void 0;
    }
  }
  return packageJson;
}
var NodeExternalApi_1;
var hasRequiredNodeExternalApi;
function requireNodeExternalApi() {
  if (hasRequiredNodeExternalApi) return NodeExternalApi_1;
  hasRequiredNodeExternalApi = 1;
  const childProcess = require$$0$1;
  const os = require$$1;
  const path2 = require$$2;
  const packageJson2 = requirePackageJson();
  class NodeExternalApi {
    constructor() {
      __publicField(this, "appName");
      __publicField(this, "appPackageJson");
      __publicField(this, "platform", process.platform);
    }
    getAppLogPath(appName = this.getAppName()) {
      if (this.platform === "darwin") {
        return path2.join(this.getSystemPathHome(), "Library/Logs", appName);
      }
      return path2.join(this.getAppUserDataPath(appName), "logs");
    }
    getAppName() {
      var _a;
      const appName = this.appName || ((_a = this.getAppPackageJson()) == null ? void 0 : _a.name);
      if (!appName) {
        throw new Error(
          "electron-log can't determine the app name. It tried these methods:\n1. Use `electron.app.name`\n2. Use productName or name from the nearest package.json`\nYou can also set it through log.transports.file.setAppName()"
        );
      }
      return appName;
    }
    /**
     * @private
     * @returns {undefined}
     */
    getAppPackageJson() {
      if (typeof this.appPackageJson !== "object") {
        this.appPackageJson = packageJson2.findAndReadPackageJson();
      }
      return this.appPackageJson;
    }
    getAppUserDataPath(appName = this.getAppName()) {
      return appName ? path2.join(this.getSystemPathAppData(), appName) : void 0;
    }
    getAppVersion() {
      var _a;
      return (_a = this.getAppPackageJson()) == null ? void 0 : _a.version;
    }
    getElectronLogPath() {
      return this.getAppLogPath();
    }
    getMacOsVersion() {
      const release = Number(os.release().split(".")[0]);
      if (release <= 19) {
        return `10.${release - 4}`;
      }
      return release - 9;
    }
    /**
     * @protected
     * @returns {string}
     */
    getOsVersion() {
      let osName = os.type().replace("_", " ");
      let osVersion = os.release();
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
        case "darwin": {
          return path2.join(home, "Library/Application Support");
        }
        case "win32": {
          return process.env.APPDATA || path2.join(home, "AppData/Roaming");
        }
        default: {
          return process.env.XDG_CONFIG_HOME || path2.join(home, ".config");
        }
      }
    }
    getSystemPathHome() {
      var _a;
      return ((_a = os.homedir) == null ? void 0 : _a.call(os)) || process.env.HOME;
    }
    getSystemPathTemp() {
      return os.tmpdir();
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
    onAppEvent(_eventName, _handler) {
    }
    onAppReady(handler) {
      handler();
    }
    onEveryWebContentsEvent(eventName, handler) {
    }
    /**
     * Listen to async messages sent from opposite process
     * @param {string} channel
     * @param {function} listener
     */
    onIpc(channel, listener) {
    }
    onIpcInvoke(channel, listener) {
    }
    /**
     * @param {string} url
     * @param {Function} [logFunction]
     */
    openUrl(url, logFunction = console.error) {
      const startMap = { darwin: "open", win32: "start", linux: "xdg-open" };
      const start = startMap[process.platform] || "xdg-open";
      childProcess.exec(`${start} ${url}`, {}, (err) => {
        if (err) {
          logFunction(err);
        }
      });
    }
    setAppName(appName) {
      this.appName = appName;
    }
    setPlatform(platform) {
      this.platform = platform;
    }
    setPreloadFileForSessions({
      filePath,
      // eslint-disable-line no-unused-vars
      includeFutureSession = true,
      // eslint-disable-line no-unused-vars
      getSessions = () => []
      // eslint-disable-line no-unused-vars
    }) {
    }
    /**
     * Sent a message to opposite process
     * @param {string} channel
     * @param {any} message
     */
    sendIpc(channel, message) {
    }
    showErrorBox(title, message) {
    }
  }
  NodeExternalApi_1 = NodeExternalApi;
  return NodeExternalApi_1;
}
var ElectronExternalApi_1;
var hasRequiredElectronExternalApi;
function requireElectronExternalApi() {
  if (hasRequiredElectronExternalApi) return ElectronExternalApi_1;
  hasRequiredElectronExternalApi = 1;
  const path2 = require$$2;
  const NodeExternalApi = requireNodeExternalApi();
  class ElectronExternalApi extends NodeExternalApi {
    /**
     * @param {object} options
     * @param {typeof Electron} [options.electron]
     */
    constructor({ electron } = {}) {
      super();
      /**
       * @type {typeof Electron}
       */
      __publicField(this, "electron");
      this.electron = electron;
    }
    getAppName() {
      var _a, _b;
      let appName;
      try {
        appName = this.appName || ((_a = this.electron.app) == null ? void 0 : _a.name) || ((_b = this.electron.app) == null ? void 0 : _b.getName());
      } catch {
      }
      return appName || super.getAppName();
    }
    getAppUserDataPath(appName) {
      return this.getPath("userData") || super.getAppUserDataPath(appName);
    }
    getAppVersion() {
      var _a;
      let appVersion;
      try {
        appVersion = (_a = this.electron.app) == null ? void 0 : _a.getVersion();
      } catch {
      }
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
      var _a;
      try {
        return (_a = this.electron.app) == null ? void 0 : _a.getPath(name);
      } catch {
        return void 0;
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
      var _a;
      if (((_a = this.electron.app) == null ? void 0 : _a.isPackaged) !== void 0) {
        return !this.electron.app.isPackaged;
      }
      if (typeof process.execPath === "string") {
        const execFileName = path2.basename(process.execPath).toLowerCase();
        return execFileName.startsWith("electron");
      }
      return super.isDev();
    }
    onAppEvent(eventName, handler) {
      var _a;
      (_a = this.electron.app) == null ? void 0 : _a.on(eventName, handler);
      return () => {
        var _a2;
        (_a2 = this.electron.app) == null ? void 0 : _a2.off(eventName, handler);
      };
    }
    onAppReady(handler) {
      var _a, _b, _c;
      if ((_a = this.electron.app) == null ? void 0 : _a.isReady()) {
        handler();
      } else if ((_b = this.electron.app) == null ? void 0 : _b.once) {
        (_c = this.electron.app) == null ? void 0 : _c.once("ready", handler);
      } else {
        handler();
      }
    }
    onEveryWebContentsEvent(eventName, handler) {
      var _a, _b, _c;
      (_b = (_a = this.electron.webContents) == null ? void 0 : _a.getAllWebContents()) == null ? void 0 : _b.forEach((webContents) => {
        webContents.on(eventName, handler);
      });
      (_c = this.electron.app) == null ? void 0 : _c.on("web-contents-created", onWebContentsCreated);
      return () => {
        var _a2, _b2;
        (_a2 = this.electron.webContents) == null ? void 0 : _a2.getAllWebContents().forEach((webContents) => {
          webContents.off(eventName, handler);
        });
        (_b2 = this.electron.app) == null ? void 0 : _b2.off("web-contents-created", onWebContentsCreated);
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
      var _a;
      (_a = this.electron.ipcMain) == null ? void 0 : _a.on(channel, listener);
    }
    onIpcInvoke(channel, listener) {
      var _a, _b;
      (_b = (_a = this.electron.ipcMain) == null ? void 0 : _a.handle) == null ? void 0 : _b.call(_a, channel, listener);
    }
    /**
     * @param {string} url
     * @param {Function} [logFunction]
     */
    openUrl(url, logFunction = console.error) {
      var _a;
      (_a = this.electron.shell) == null ? void 0 : _a.openExternal(url).catch(logFunction);
    }
    setPreloadFileForSessions({
      filePath,
      includeFutureSession = true,
      getSessions = () => {
        var _a;
        return [(_a = this.electron.session) == null ? void 0 : _a.defaultSession];
      }
    }) {
      for (const session of getSessions().filter(Boolean)) {
        setPreload(session);
      }
      if (includeFutureSession) {
        this.onAppEvent("session-created", (session) => {
          setPreload(session);
        });
      }
      function setPreload(session) {
        if (typeof session.registerPreloadScript === "function") {
          session.registerPreloadScript({
            filePath,
            id: "electron-log-preload",
            type: "frame"
          });
        } else {
          session.setPreloads([...session.getPreloads(), filePath]);
        }
      }
    }
    /**
     * Sent a message to opposite process
     * @param {string} channel
     * @param {any} message
     */
    sendIpc(channel, message) {
      var _a, _b;
      (_b = (_a = this.electron.BrowserWindow) == null ? void 0 : _a.getAllWindows()) == null ? void 0 : _b.forEach((wnd) => {
        var _a2, _b2;
        if (((_a2 = wnd.webContents) == null ? void 0 : _a2.isDestroyed()) === false && ((_b2 = wnd.webContents) == null ? void 0 : _b2.isCrashed()) === false) {
          wnd.webContents.send(channel, message);
        }
      });
    }
    showErrorBox(title, message) {
      var _a;
      (_a = this.electron.dialog) == null ? void 0 : _a.showErrorBox(title, message);
    }
  }
  ElectronExternalApi_1 = ElectronExternalApi;
  return ElectronExternalApi_1;
}
var electronLogPreload = { exports: {} };
var hasRequiredElectronLogPreload;
function requireElectronLogPreload() {
  if (hasRequiredElectronLogPreload) return electronLogPreload.exports;
  hasRequiredElectronLogPreload = 1;
  (function(module2) {
    let electron = {};
    try {
      electron = require("electron");
    } catch (e) {
    }
    if (electron.ipcRenderer) {
      initialize2(electron);
    }
    {
      module2.exports = initialize2;
    }
    function initialize2({ contextBridge, ipcRenderer }) {
      if (!ipcRenderer) {
        return;
      }
      ipcRenderer.on("__ELECTRON_LOG_IPC__", (_, message) => {
        window.postMessage({ cmd: "message", ...message });
      });
      ipcRenderer.invoke("__ELECTRON_LOG__", { cmd: "getOptions" }).catch((e) => console.error(new Error(
        `electron-log isn't initialized in the main process. Please call log.initialize() before. ${e.message}`
      )));
      const electronLog = {
        sendToMain(message) {
          try {
            ipcRenderer.send("__ELECTRON_LOG__", message);
          } catch (e) {
            console.error("electronLog.sendToMain ", e, "data:", message);
            ipcRenderer.send("__ELECTRON_LOG__", {
              cmd: "errorHandler",
              error: { message: e == null ? void 0 : e.message, stack: e == null ? void 0 : e.stack },
              errorName: "sendToMain"
            });
          }
        },
        log(...data) {
          electronLog.sendToMain({ data, level: "info" });
        }
      };
      for (const level of ["error", "warn", "info", "verbose", "debug", "silly"]) {
        electronLog[level] = (...data) => electronLog.sendToMain({
          data,
          level
        });
      }
      if (contextBridge && process.contextIsolated) {
        try {
          contextBridge.exposeInMainWorld("__electronLog", electronLog);
        } catch {
        }
      }
      if (typeof window === "object") {
        window.__electronLog = electronLog;
      } else {
        __electronLog = electronLog;
      }
    }
  })(electronLogPreload);
  return electronLogPreload.exports;
}
var initialize;
var hasRequiredInitialize;
function requireInitialize() {
  if (hasRequiredInitialize) return initialize;
  hasRequiredInitialize = 1;
  const fs2 = require$$0;
  const os = require$$1;
  const path2 = require$$2;
  const preloadInitializeFn = requireElectronLogPreload();
  let preloadInitialized = false;
  let spyConsoleInitialized = false;
  initialize = {
    initialize({
      externalApi,
      getSessions,
      includeFutureSession,
      logger,
      preload = true,
      spyRendererConsole = false
    }) {
      externalApi.onAppReady(() => {
        try {
          if (preload) {
            initializePreload({
              externalApi,
              getSessions,
              includeFutureSession,
              logger,
              preloadOption: preload
            });
          }
          if (spyRendererConsole) {
            initializeSpyRendererConsole({ externalApi, logger });
          }
        } catch (err) {
          logger.warn(err);
        }
      });
    }
  };
  function initializePreload({
    externalApi,
    getSessions,
    includeFutureSession,
    logger,
    preloadOption
  }) {
    let preloadPath = typeof preloadOption === "string" ? preloadOption : void 0;
    if (preloadInitialized) {
      logger.warn(new Error("log.initialize({ preload }) already called").stack);
      return;
    }
    preloadInitialized = true;
    try {
      preloadPath = path2.resolve(
        __dirname,
        "../renderer/electron-log-preload.js"
      );
    } catch {
    }
    if (!preloadPath || !fs2.existsSync(preloadPath)) {
      preloadPath = path2.join(
        externalApi.getAppUserDataPath() || os.tmpdir(),
        "electron-log-preload.js"
      );
      const preloadCode = `
      try {
        (${preloadInitializeFn.toString()})(require('electron'));
      } catch(e) {
        console.error(e);
      }
    `;
      fs2.writeFileSync(preloadPath, preloadCode, "utf8");
    }
    externalApi.setPreloadFileForSessions({
      filePath: preloadPath,
      includeFutureSession,
      getSessions
    });
  }
  function initializeSpyRendererConsole({ externalApi, logger }) {
    if (spyConsoleInitialized) {
      logger.warn(
        new Error("log.initialize({ spyRendererConsole }) already called").stack
      );
      return;
    }
    spyConsoleInitialized = true;
    const levels = ["debug", "info", "warn", "error"];
    externalApi.onEveryWebContentsEvent(
      "console-message",
      (event, level, message) => {
        logger.processMessage({
          data: [message],
          level: levels[level],
          variables: { processType: "renderer" }
        });
      }
    );
  }
  return initialize;
}
var scope;
var hasRequiredScope;
function requireScope() {
  if (hasRequiredScope) return scope;
  hasRequiredScope = 1;
  scope = scopeFactory;
  function scopeFactory(logger) {
    return Object.defineProperties(scope2, {
      defaultLabel: { value: "", writable: true },
      labelPadding: { value: true, writable: true },
      maxLabelLength: { value: 0, writable: true },
      labelLength: {
        get() {
          switch (typeof scope2.labelPadding) {
            case "boolean":
              return scope2.labelPadding ? scope2.maxLabelLength : 0;
            case "number":
              return scope2.labelPadding;
            default:
              return 0;
          }
        }
      }
    });
    function scope2(label) {
      scope2.maxLabelLength = Math.max(scope2.maxLabelLength, label.length);
      const newScope = {};
      for (const level of logger.levels) {
        newScope[level] = (...d) => logger.logData(d, { level, scope: label });
      }
      newScope.log = newScope.info;
      return newScope;
    }
  }
  return scope;
}
var Buffering_1;
var hasRequiredBuffering;
function requireBuffering() {
  if (hasRequiredBuffering) return Buffering_1;
  hasRequiredBuffering = 1;
  class Buffering {
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
  }
  Buffering_1 = Buffering;
  return Buffering_1;
}
var Logger_1;
var hasRequiredLogger;
function requireLogger() {
  if (hasRequiredLogger) return Logger_1;
  hasRequiredLogger = 1;
  const scopeFactory = requireScope();
  const Buffering = requireBuffering();
  const _Logger = class _Logger {
    constructor({
      allowUnknownLevel = false,
      dependencies = {},
      errorHandler,
      eventLogger,
      initializeFn,
      isDev: isDev2 = false,
      levels = ["error", "warn", "info", "verbose", "debug", "silly"],
      logId,
      transportFactories = {},
      variables
    } = {}) {
      __publicField(this, "dependencies", {});
      __publicField(this, "errorHandler", null);
      __publicField(this, "eventLogger", null);
      __publicField(this, "functions", {});
      __publicField(this, "hooks", []);
      __publicField(this, "isDev", false);
      __publicField(this, "levels", null);
      __publicField(this, "logId", null);
      __publicField(this, "scope", null);
      __publicField(this, "transports", {});
      __publicField(this, "variables", {});
      this.addLevel = this.addLevel.bind(this);
      this.create = this.create.bind(this);
      this.initialize = this.initialize.bind(this);
      this.logData = this.logData.bind(this);
      this.processMessage = this.processMessage.bind(this);
      this.allowUnknownLevel = allowUnknownLevel;
      this.buffering = new Buffering(this);
      this.dependencies = dependencies;
      this.initializeFn = initializeFn;
      this.isDev = isDev2;
      this.levels = levels;
      this.logId = logId;
      this.scope = scopeFactory(this);
      this.transportFactories = transportFactories;
      this.variables = variables || {};
      for (const name of this.levels) {
        this.addLevel(name, false);
      }
      this.log = this.info;
      this.functions.log = this.log;
      this.errorHandler = errorHandler;
      errorHandler == null ? void 0 : errorHandler.setOptions({ ...dependencies, logFn: this.error });
      this.eventLogger = eventLogger;
      eventLogger == null ? void 0 : eventLogger.setOptions({ ...dependencies, logger: this });
      for (const [name, factory] of Object.entries(transportFactories)) {
        this.transports[name] = factory(this, dependencies);
      }
      _Logger.instances[logId] = this;
    }
    static getInstance({ logId }) {
      return this.instances[logId] || this.instances.default;
    }
    addLevel(level, index = this.levels.length) {
      if (index !== false) {
        this.levels.splice(index, 0, level);
      }
      this[level] = (...args) => this.logData(args, { level });
      this.functions[level] = this[level];
    }
    catchErrors(options) {
      this.processMessage(
        {
          data: ["log.catchErrors is deprecated. Use log.errorHandler instead"],
          level: "warn"
        },
        { transports: ["console"] }
      );
      return this.errorHandler.startCatching(options);
    }
    create(options) {
      if (typeof options === "string") {
        options = { logId: options };
      }
      return new _Logger({
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
      if (check === -1 || pass === -1) {
        return true;
      }
      return check <= pass;
    }
    initialize(options = {}) {
      this.initializeFn({ logger: this, ...this.dependencies, ...options });
    }
    logData(data, options = {}) {
      if (this.buffering.enabled) {
        this.buffering.addMessage({ data, date: /* @__PURE__ */ new Date(), ...options });
      } else {
        this.processMessage({ data, ...options });
      }
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
      if (!this.allowUnknownLevel) {
        level = this.levels.includes(message.level) ? message.level : "info";
      }
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
        if (typeof transFn !== "function" || transFn.level === false) {
          continue;
        }
        if (!this.compareLevels(transFn.level, message.level)) {
          continue;
        }
        try {
          const transformedMsg = this.hooks.reduce((msg, hook) => {
            return msg ? hook(msg, transFn, transName) : msg;
          }, normalizedMessage);
          if (transformedMsg) {
            transFn({ ...transformedMsg, data: [...transformedMsg.data] });
          }
        } catch (e) {
          this.processInternalErrorFn(e);
        }
      }
    }
    processInternalErrorFn(_e) {
    }
    transportEntries(transports = this.transports) {
      const transportArray = Array.isArray(transports) ? transports : Object.entries(transports);
      return transportArray.map((item) => {
        switch (typeof item) {
          case "string":
            return this.transports[item] ? [item, this.transports[item]] : null;
          case "function":
            return [item.name, item];
          default:
            return Array.isArray(item) ? item : null;
        }
      }).filter(Boolean);
    }
  };
  __publicField(_Logger, "instances", {});
  let Logger = _Logger;
  Logger_1 = Logger;
  return Logger_1;
}
var ErrorHandler_1;
var hasRequiredErrorHandler;
function requireErrorHandler() {
  if (hasRequiredErrorHandler) return ErrorHandler_1;
  hasRequiredErrorHandler = 1;
  class ErrorHandler {
    constructor({
      externalApi,
      logFn = void 0,
      onError = void 0,
      showDialog = void 0
    } = {}) {
      __publicField(this, "externalApi");
      __publicField(this, "isActive", false);
      __publicField(this, "logFn");
      __publicField(this, "onError");
      __publicField(this, "showDialog", true);
      this.createIssue = this.createIssue.bind(this);
      this.handleError = this.handleError.bind(this);
      this.handleRejection = this.handleRejection.bind(this);
      this.setOptions({ externalApi, logFn, onError, showDialog });
      this.startCatching = this.startCatching.bind(this);
      this.stopCatching = this.stopCatching.bind(this);
    }
    handle(error, {
      logFn = this.logFn,
      onError = this.onError,
      processType = "browser",
      showDialog = this.showDialog,
      errorName = ""
    } = {}) {
      var _a;
      error = normalizeError(error);
      try {
        if (typeof onError === "function") {
          const versions = ((_a = this.externalApi) == null ? void 0 : _a.getVersions()) || {};
          const createIssue = this.createIssue;
          const result = onError({
            createIssue,
            error,
            errorName,
            processType,
            versions
          });
          if (result === false) {
            return;
          }
        }
        errorName ? logFn(errorName, error) : logFn(error);
        if (showDialog && !errorName.includes("rejection") && this.externalApi) {
          this.externalApi.showErrorBox(
            `A JavaScript error occurred in the ${processType} process`,
            error.stack
          );
        }
      } catch {
        console.error(error);
      }
    }
    setOptions({ externalApi, logFn, onError, showDialog }) {
      if (typeof externalApi === "object") {
        this.externalApi = externalApi;
      }
      if (typeof logFn === "function") {
        this.logFn = logFn;
      }
      if (typeof onError === "function") {
        this.onError = onError;
      }
      if (typeof showDialog === "boolean") {
        this.showDialog = showDialog;
      }
    }
    startCatching({ onError, showDialog } = {}) {
      if (this.isActive) {
        return;
      }
      this.isActive = true;
      this.setOptions({ onError, showDialog });
      process.on("uncaughtException", this.handleError);
      process.on("unhandledRejection", this.handleRejection);
    }
    stopCatching() {
      this.isActive = false;
      process.removeListener("uncaughtException", this.handleError);
      process.removeListener("unhandledRejection", this.handleRejection);
    }
    createIssue(pageUrl, queryParams) {
      var _a;
      (_a = this.externalApi) == null ? void 0 : _a.openUrl(
        `${pageUrl}?${new URLSearchParams(queryParams).toString()}`
      );
    }
    handleError(error) {
      this.handle(error, { errorName: "Unhandled" });
    }
    handleRejection(reason) {
      const error = reason instanceof Error ? reason : new Error(JSON.stringify(reason));
      this.handle(error, { errorName: "Unhandled rejection" });
    }
  }
  function normalizeError(e) {
    if (e instanceof Error) {
      return e;
    }
    if (e && typeof e === "object") {
      if (e.message) {
        return Object.assign(new Error(e.message), e);
      }
      try {
        return new Error(JSON.stringify(e));
      } catch (serErr) {
        return new Error(`Couldn't normalize error ${String(e)}: ${serErr}`);
      }
    }
    return new Error(`Can't normalize error ${String(e)}`);
  }
  ErrorHandler_1 = ErrorHandler;
  return ErrorHandler_1;
}
var EventLogger_1;
var hasRequiredEventLogger;
function requireEventLogger() {
  if (hasRequiredEventLogger) return EventLogger_1;
  hasRequiredEventLogger = 1;
  class EventLogger {
    constructor(options = {}) {
      __publicField(this, "disposers", []);
      __publicField(this, "format", "{eventSource}#{eventName}:");
      __publicField(this, "formatters", {
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
            return details && typeof details === "object" ? { ...details, ...this.getWebContentsDetails(webContents) } : [];
          }
        },
        webContents: {
          "console-message": ({ args: [level, message, line, sourceId] }) => {
            if (level < 3) {
              return void 0;
            }
            return { message, source: `${sourceId}:${line}` };
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
      });
      __publicField(this, "events", {
        app: {
          "certificate-error": true,
          "child-process-gone": true,
          "render-process-gone": true
        },
        webContents: {
          // 'console-message': true,
          "did-fail-load": true,
          "did-fail-provisional-load": true,
          "plugin-crashed": true,
          "preload-error": true,
          "unresponsive": true
        }
      });
      __publicField(this, "externalApi");
      __publicField(this, "level", "error");
      __publicField(this, "scope", "");
      this.setOptions(options);
    }
    setOptions({
      events,
      externalApi,
      level,
      logger,
      format: format2,
      formatters,
      scope: scope2
    }) {
      if (typeof events === "object") {
        this.events = events;
      }
      if (typeof externalApi === "object") {
        this.externalApi = externalApi;
      }
      if (typeof level === "string") {
        this.level = level;
      }
      if (typeof logger === "object") {
        this.logger = logger;
      }
      if (typeof format2 === "string" || typeof format2 === "function") {
        this.format = format2;
      }
      if (typeof formatters === "object") {
        this.formatters = formatters;
      }
      if (typeof scope2 === "string") {
        this.scope = scope2;
      }
    }
    startLogging(options = {}) {
      this.setOptions(options);
      this.disposeListeners();
      for (const eventName of this.getEventNames(this.events.app)) {
        this.disposers.push(
          this.externalApi.onAppEvent(eventName, (...handlerArgs) => {
            this.handleEvent({ eventSource: "app", eventName, handlerArgs });
          })
        );
      }
      for (const eventName of this.getEventNames(this.events.webContents)) {
        this.disposers.push(
          this.externalApi.onEveryWebContentsEvent(
            eventName,
            (...handlerArgs) => {
              this.handleEvent(
                { eventSource: "webContents", eventName, handlerArgs }
              );
            }
          )
        );
      }
    }
    stopLogging() {
      this.disposeListeners();
    }
    arrayToObject(array, fieldNames) {
      const obj = {};
      fieldNames.forEach((fieldName, index) => {
        obj[fieldName] = array[index];
      });
      if (array.length > fieldNames.length) {
        obj.unknownArgs = array.slice(fieldNames.length);
      }
      return obj;
    }
    disposeListeners() {
      this.disposers.forEach((disposer) => disposer());
      this.disposers = [];
    }
    formatEventLog({ eventName, eventSource, handlerArgs }) {
      var _a;
      const [event, ...args] = handlerArgs;
      if (typeof this.format === "function") {
        return this.format({ args, event, eventName, eventSource });
      }
      const formatter = (_a = this.formatters[eventSource]) == null ? void 0 : _a[eventName];
      let formattedArgs = args;
      if (typeof formatter === "function") {
        formattedArgs = formatter({ args, event, eventName, eventSource });
      }
      if (!formattedArgs) {
        return void 0;
      }
      const eventData = {};
      if (Array.isArray(formattedArgs)) {
        eventData.args = formattedArgs;
      } else if (typeof formattedArgs === "object") {
        Object.assign(eventData, formattedArgs);
      }
      if (eventSource === "webContents") {
        Object.assign(eventData, this.getWebContentsDetails(event == null ? void 0 : event.sender));
      }
      const title = this.format.replace("{eventSource}", eventSource === "app" ? "App" : "WebContents").replace("{eventName}", eventName);
      return [title, eventData];
    }
    getEventNames(eventMap) {
      if (!eventMap || typeof eventMap !== "object") {
        return [];
      }
      return Object.entries(eventMap).filter(([_, listen]) => listen).map(([eventName]) => eventName);
    }
    getWebContentsDetails(webContents) {
      if (!(webContents == null ? void 0 : webContents.loadURL)) {
        return {};
      }
      try {
        return {
          webContents: {
            id: webContents.id,
            url: webContents.getURL()
          }
        };
      } catch {
        return {};
      }
    }
    handleEvent({ eventName, eventSource, handlerArgs }) {
      var _a;
      const log2 = this.formatEventLog({ eventName, eventSource, handlerArgs });
      if (log2) {
        const logFns = this.scope ? this.logger.scope(this.scope) : this.logger;
        (_a = logFns == null ? void 0 : logFns[this.level]) == null ? void 0 : _a.call(logFns, ...log2);
      }
    }
  }
  EventLogger_1 = EventLogger;
  return EventLogger_1;
}
var transform_1;
var hasRequiredTransform;
function requireTransform() {
  if (hasRequiredTransform) return transform_1;
  hasRequiredTransform = 1;
  transform_1 = { transform };
  function transform({
    logger,
    message,
    transport,
    initialData = (message == null ? void 0 : message.data) || [],
    transforms = transport == null ? void 0 : transport.transforms
  }) {
    return transforms.reduce((data, trans) => {
      if (typeof trans === "function") {
        return trans({ data, logger, message, transport });
      }
      return data;
    }, initialData);
  }
  return transform_1;
}
var format;
var hasRequiredFormat;
function requireFormat() {
  if (hasRequiredFormat) return format;
  hasRequiredFormat = 1;
  const { transform } = requireTransform();
  format = {
    concatFirstStringElements,
    formatScope,
    formatText,
    formatVariables,
    timeZoneFromOffset,
    format({ message, logger, transport, data = message == null ? void 0 : message.data }) {
      switch (typeof transport.format) {
        case "string": {
          return transform({
            message,
            logger,
            transforms: [formatVariables, formatScope, formatText],
            transport,
            initialData: [transport.format, ...data]
          });
        }
        case "function": {
          return transport.format({
            data,
            level: (message == null ? void 0 : message.level) || "info",
            logger,
            message,
            transport
          });
        }
        default: {
          return data;
        }
      }
    }
  };
  function concatFirstStringElements({ data }) {
    if (typeof data[0] !== "string" || typeof data[1] !== "string") {
      return data;
    }
    if (data[0].match(/%[1cdfiOos]/)) {
      return data;
    }
    return [`${data[0]} ${data[1]}`, ...data.slice(2)];
  }
  function timeZoneFromOffset(minutesOffset) {
    const minutesPositive = Math.abs(minutesOffset);
    const sign = minutesOffset > 0 ? "-" : "+";
    const hours = Math.floor(minutesPositive / 60).toString().padStart(2, "0");
    const minutes = (minutesPositive % 60).toString().padStart(2, "0");
    return `${sign}${hours}:${minutes}`;
  }
  function formatScope({ data, logger, message }) {
    const { defaultLabel, labelLength } = (logger == null ? void 0 : logger.scope) || {};
    const template = data[0];
    let label = message.scope;
    if (!label) {
      label = defaultLabel;
    }
    let scopeText;
    if (label === "") {
      scopeText = labelLength > 0 ? "".padEnd(labelLength + 3) : "";
    } else if (typeof label === "string") {
      scopeText = ` (${label})`.padEnd(labelLength + 3);
    } else {
      scopeText = "";
    }
    data[0] = template.replace("{scope}", scopeText);
    return data;
  }
  function formatVariables({ data, message }) {
    let template = data[0];
    if (typeof template !== "string") {
      return data;
    }
    template = template.replace("{level}]", `${message.level}]`.padEnd(6, " "));
    const date = message.date || /* @__PURE__ */ new Date();
    data[0] = template.replace(/\{(\w+)}/g, (substring, name) => {
      var _a;
      switch (name) {
        case "level":
          return message.level || "info";
        case "logId":
          return message.logId;
        case "y":
          return date.getFullYear().toString(10);
        case "m":
          return (date.getMonth() + 1).toString(10).padStart(2, "0");
        case "d":
          return date.getDate().toString(10).padStart(2, "0");
        case "h":
          return date.getHours().toString(10).padStart(2, "0");
        case "i":
          return date.getMinutes().toString(10).padStart(2, "0");
        case "s":
          return date.getSeconds().toString(10).padStart(2, "0");
        case "ms":
          return date.getMilliseconds().toString(10).padStart(3, "0");
        case "z":
          return timeZoneFromOffset(date.getTimezoneOffset());
        case "iso":
          return date.toISOString();
        default: {
          return ((_a = message.variables) == null ? void 0 : _a[name]) || substring;
        }
      }
    }).trim();
    return data;
  }
  function formatText({ data }) {
    const template = data[0];
    if (typeof template !== "string") {
      return data;
    }
    const textTplPosition = template.lastIndexOf("{text}");
    if (textTplPosition === template.length - 6) {
      data[0] = template.replace(/\s?{text}/, "");
      if (data[0] === "") {
        data.shift();
      }
      return data;
    }
    const templatePieces = template.split("{text}");
    let result = [];
    if (templatePieces[0] !== "") {
      result.push(templatePieces[0]);
    }
    result = result.concat(data.slice(1));
    if (templatePieces[1] !== "") {
      result.push(templatePieces[1]);
    }
    return result;
  }
  return format;
}
var object = { exports: {} };
var hasRequiredObject;
function requireObject() {
  if (hasRequiredObject) return object.exports;
  hasRequiredObject = 1;
  (function(module2) {
    const util = require$$0$2;
    module2.exports = {
      serialize,
      maxDepth({ data, transport, depth = (transport == null ? void 0 : transport.depth) ?? 6 }) {
        if (!data) {
          return data;
        }
        if (depth < 1) {
          if (Array.isArray(data)) return "[array]";
          if (typeof data === "object" && data) return "[object]";
          return data;
        }
        if (Array.isArray(data)) {
          return data.map((child) => module2.exports.maxDepth({
            data: child,
            depth: depth - 1
          }));
        }
        if (typeof data !== "object") {
          return data;
        }
        if (data && typeof data.toISOString === "function") {
          return data;
        }
        if (data === null) {
          return null;
        }
        if (data instanceof Error) {
          return data;
        }
        const newJson = {};
        for (const i in data) {
          if (!Object.prototype.hasOwnProperty.call(data, i)) continue;
          newJson[i] = module2.exports.maxDepth({
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
        const inspectOptions = (transport == null ? void 0 : transport.inspectOptions) || {};
        const simplifiedData = data.map((item) => {
          if (item === void 0) {
            return void 0;
          }
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
    function createSerializer(options = {}) {
      const seen = /* @__PURE__ */ new WeakSet();
      return function(key, value) {
        if (typeof value === "object" && value !== null) {
          if (seen.has(value)) {
            return void 0;
          }
          seen.add(value);
        }
        return serialize(key, value, options);
      };
    }
    function serialize(key, value, options = {}) {
      const serializeMapAndSet = (options == null ? void 0 : options.serializeMapAndSet) !== false;
      if (value instanceof Error) {
        return value.stack;
      }
      if (!value) {
        return value;
      }
      if (typeof value === "function") {
        return `[function] ${value.toString()}`;
      }
      if (value instanceof Date) {
        return value.toISOString();
      }
      if (serializeMapAndSet && value instanceof Map && Object.fromEntries) {
        return Object.fromEntries(value);
      }
      if (serializeMapAndSet && value instanceof Set && Array.from) {
        return Array.from(value);
      }
      return value;
    }
  })(object);
  return object.exports;
}
var style;
var hasRequiredStyle;
function requireStyle() {
  if (hasRequiredStyle) return style;
  hasRequiredStyle = 1;
  style = {
    transformStyles,
    applyAnsiStyles({ data }) {
      return transformStyles(data, styleToAnsi, resetAnsiStyle);
    },
    removeStyles({ data }) {
      return transformStyles(data, () => "");
    }
  };
  const ANSI_COLORS = {
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
  function styleToAnsi(style2) {
    const color = style2.replace(/color:\s*(\w+).*/, "$1").toLowerCase();
    return ANSI_COLORS[color] || "";
  }
  function resetAnsiStyle(string) {
    return string + ANSI_COLORS.unset;
  }
  function transformStyles(data, onStyleFound, onStyleApplied) {
    const foundStyles = {};
    return data.reduce((result, item, index, array) => {
      if (foundStyles[index]) {
        return result;
      }
      if (typeof item === "string") {
        let valueIndex = index;
        let styleApplied = false;
        item = item.replace(/%[1cdfiOos]/g, (match) => {
          valueIndex += 1;
          if (match !== "%c") {
            return match;
          }
          const style2 = array[valueIndex];
          if (typeof style2 === "string") {
            foundStyles[valueIndex] = true;
            styleApplied = true;
            return onStyleFound(style2, item);
          }
          return match;
        });
        if (styleApplied && onStyleApplied) {
          item = onStyleApplied(item);
        }
      }
      result.push(item);
      return result;
    }, []);
  }
  return style;
}
var console_1;
var hasRequiredConsole;
function requireConsole() {
  if (hasRequiredConsole) return console_1;
  hasRequiredConsole = 1;
  const {
    concatFirstStringElements,
    format: format2
  } = requireFormat();
  const { maxDepth, toJSON } = requireObject();
  const {
    applyAnsiStyles,
    removeStyles
  } = requireStyle();
  const { transform } = requireTransform();
  const consoleMethods = {
    error: console.error,
    warn: console.warn,
    info: console.info,
    verbose: console.info,
    debug: console.debug,
    silly: console.debug,
    log: console.log
  };
  console_1 = consoleTransportFactory;
  const separator = process.platform === "win32" ? ">" : "›";
  const DEFAULT_FORMAT = `%c{h}:{i}:{s}.{ms}{scope}%c ${separator} {text}`;
  Object.assign(consoleTransportFactory, {
    DEFAULT_FORMAT
  });
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
        format2,
        formatStyles,
        concatFirstStringElements,
        maxDepth,
        toJSON
      ],
      useStyles: process.env.FORCE_STYLES,
      writeFn({ message }) {
        const consoleLogFn = consoleMethods[message.level] || consoleMethods.info;
        consoleLogFn(...message.data);
      }
    });
    function transport(message) {
      const data = transform({ logger, message, transport });
      transport.writeFn({
        message: { ...message, data }
      });
    }
  }
  function addTemplateColors({ data, message, transport }) {
    if (typeof transport.format !== "string" || !transport.format.includes("%c")) {
      return data;
    }
    return [
      `color:${levelToStyle(message.level, transport)}`,
      "color:unset",
      ...data
    ];
  }
  function canUseStyles(useStyleValue, level) {
    if (typeof useStyleValue === "boolean") {
      return useStyleValue;
    }
    const useStderr = level === "error" || level === "warn";
    const stream = useStderr ? process.stderr : process.stdout;
    return stream && stream.isTTY;
  }
  function formatStyles(args) {
    const { message, transport } = args;
    const useStyles = canUseStyles(transport.useStyles, message.level);
    const nextTransform = useStyles ? applyAnsiStyles : removeStyles;
    return nextTransform(args);
  }
  function levelToStyle(level, transport) {
    return transport.colorMap[level] || transport.colorMap.default;
  }
  return console_1;
}
var File_1;
var hasRequiredFile$1;
function requireFile$1() {
  if (hasRequiredFile$1) return File_1;
  hasRequiredFile$1 = 1;
  const EventEmitter = require$$0$3;
  const fs2 = require$$0;
  const os = require$$1;
  class File extends EventEmitter {
    constructor({
      path: path2,
      writeOptions = { encoding: "utf8", flag: "a", mode: 438 },
      writeAsync = false
    }) {
      super();
      __publicField(this, "asyncWriteQueue", []);
      __publicField(this, "bytesWritten", 0);
      __publicField(this, "hasActiveAsyncWriting", false);
      __publicField(this, "path", null);
      __publicField(this, "initialSize");
      __publicField(this, "writeOptions", null);
      __publicField(this, "writeAsync", false);
      this.path = path2;
      this.writeOptions = writeOptions;
      this.writeAsync = writeAsync;
    }
    get size() {
      return this.getSize();
    }
    clear() {
      try {
        fs2.writeFileSync(this.path, "", {
          mode: this.writeOptions.mode,
          flag: "w"
        });
        this.reset();
        return true;
      } catch (e) {
        if (e.code === "ENOENT") {
          return true;
        }
        this.emit("error", e, this);
        return false;
      }
    }
    crop(bytesAfter) {
      try {
        const content = readFileSyncFromEnd(this.path, bytesAfter || 4096);
        this.clear();
        this.writeLine(`[log cropped]${os.EOL}${content}`);
      } catch (e) {
        this.emit(
          "error",
          new Error(`Couldn't crop file ${this.path}. ${e.message}`),
          this
        );
      }
    }
    getSize() {
      if (this.initialSize === void 0) {
        try {
          const stats = fs2.statSync(this.path);
          this.initialSize = stats.size;
        } catch (e) {
          this.initialSize = 0;
        }
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
      const file2 = this;
      if (this.hasActiveAsyncWriting || this.asyncWriteQueue.length === 0) {
        return;
      }
      const text = this.asyncWriteQueue.join("");
      this.asyncWriteQueue = [];
      this.hasActiveAsyncWriting = true;
      fs2.writeFile(this.path, text, this.writeOptions, (e) => {
        file2.hasActiveAsyncWriting = false;
        if (e) {
          file2.emit(
            "error",
            new Error(`Couldn't write to ${file2.path}. ${e.message}`),
            this
          );
        } else {
          file2.increaseBytesWrittenCounter(text);
        }
        file2.nextAsyncWrite();
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
      text += os.EOL;
      if (this.writeAsync) {
        this.asyncWriteQueue.push(text);
        this.nextAsyncWrite();
        return;
      }
      try {
        fs2.writeFileSync(this.path, text, this.writeOptions);
        this.increaseBytesWrittenCounter(text);
      } catch (e) {
        this.emit(
          "error",
          new Error(`Couldn't write to ${this.path}. ${e.message}`),
          this
        );
      }
    }
  }
  File_1 = File;
  function readFileSyncFromEnd(filePath, bytesCount) {
    const buffer = Buffer.alloc(bytesCount);
    const stats = fs2.statSync(filePath);
    const readLength = Math.min(stats.size, bytesCount);
    const offset = Math.max(0, stats.size - bytesCount);
    const fd = fs2.openSync(filePath, "r");
    const totalBytes = fs2.readSync(fd, buffer, 0, readLength, offset);
    fs2.closeSync(fd);
    return buffer.toString("utf8", 0, totalBytes);
  }
  return File_1;
}
var NullFile_1;
var hasRequiredNullFile;
function requireNullFile() {
  if (hasRequiredNullFile) return NullFile_1;
  hasRequiredNullFile = 1;
  const File = requireFile$1();
  class NullFile extends File {
    clear() {
    }
    crop() {
    }
    getSize() {
      return 0;
    }
    isNull() {
      return true;
    }
    writeLine() {
    }
  }
  NullFile_1 = NullFile;
  return NullFile_1;
}
var FileRegistry_1;
var hasRequiredFileRegistry;
function requireFileRegistry() {
  if (hasRequiredFileRegistry) return FileRegistry_1;
  hasRequiredFileRegistry = 1;
  const EventEmitter = require$$0$3;
  const fs2 = require$$0;
  const path2 = require$$2;
  const File = requireFile$1();
  const NullFile = requireNullFile();
  class FileRegistry extends EventEmitter {
    constructor() {
      super();
      __publicField(this, "store", {});
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
      let file2;
      try {
        filePath = path2.resolve(filePath);
        if (this.store[filePath]) {
          return this.store[filePath];
        }
        file2 = this.createFile({ filePath, writeOptions, writeAsync });
      } catch (e) {
        file2 = new NullFile({ path: filePath });
        this.emitError(e, file2);
      }
      file2.on("error", this.emitError);
      this.store[filePath] = file2;
      return file2;
    }
    /**
     * @param {string} filePath
     * @param {WriteOptions} writeOptions
     * @param {boolean} async
     * @return {File}
     * @private
     */
    createFile({ filePath, writeOptions, writeAsync }) {
      this.testFileWriting({ filePath, writeOptions });
      return new File({ path: filePath, writeOptions, writeAsync });
    }
    /**
     * @param {Error} error
     * @param {File} file
     * @private
     */
    emitError(error, file2) {
      this.emit("error", error, file2);
    }
    /**
     * @param {string} filePath
     * @param {WriteOptions} writeOptions
     * @private
     */
    testFileWriting({ filePath, writeOptions }) {
      fs2.mkdirSync(path2.dirname(filePath), { recursive: true });
      fs2.writeFileSync(filePath, "", { flag: "a", mode: writeOptions.mode });
    }
  }
  FileRegistry_1 = FileRegistry;
  return FileRegistry_1;
}
var file;
var hasRequiredFile;
function requireFile() {
  if (hasRequiredFile) return file;
  hasRequiredFile = 1;
  const fs2 = require$$0;
  const os = require$$1;
  const path2 = require$$2;
  const FileRegistry = requireFileRegistry();
  const { transform } = requireTransform();
  const { removeStyles } = requireStyle();
  const {
    format: format2,
    concatFirstStringElements
  } = requireFormat();
  const { toString } = requireObject();
  file = fileTransportFactory;
  const globalRegistry = new FileRegistry();
  function fileTransportFactory(logger, { registry = globalRegistry, externalApi } = {}) {
    let pathVariables;
    if (registry.listenerCount("error") < 1) {
      registry.on("error", (e, file2) => {
        logConsole(`Can't write to ${file2}`, e);
      });
    }
    return Object.assign(transport, {
      fileName: getDefaultFileName(logger.variables.processType),
      format: "[{y}-{m}-{d} {h}:{i}:{s}.{ms}] [{level}]{scope} {text}",
      getFile,
      inspectOptions: { depth: 5 },
      level: "silly",
      maxSize: 1024 ** 2,
      readAllLogs,
      sync: true,
      transforms: [removeStyles, format2, concatFirstStringElements, toString],
      writeOptions: { flag: "a", mode: 438, encoding: "utf8" },
      archiveLogFn(file2) {
        const oldPath = file2.toString();
        const inf = path2.parse(oldPath);
        try {
          fs2.renameSync(oldPath, path2.join(inf.dir, `${inf.name}.old${inf.ext}`));
        } catch (e) {
          logConsole("Could not rotate log", e);
          const quarterOfMaxSize = Math.round(transport.maxSize / 4);
          file2.crop(Math.min(quarterOfMaxSize, 256 * 1024));
        }
      },
      resolvePathFn(vars) {
        return path2.join(vars.libraryDefaultDir, vars.fileName);
      },
      setAppName(name) {
        logger.dependencies.externalApi.setAppName(name);
      }
    });
    function transport(message) {
      const file2 = getFile(message);
      const needLogRotation = transport.maxSize > 0 && file2.size > transport.maxSize;
      if (needLogRotation) {
        transport.archiveLogFn(file2);
        file2.reset();
      }
      const content = transform({ logger, message, transport });
      file2.writeLine(content);
    }
    function initializeOnFirstAccess() {
      if (pathVariables) {
        return;
      }
      pathVariables = Object.create(
        Object.prototype,
        {
          ...Object.getOwnPropertyDescriptors(
            externalApi.getPathVariables()
          ),
          fileName: {
            get() {
              return transport.fileName;
            },
            enumerable: true
          }
        }
      );
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
      if (error) {
        data.push(error);
      }
      logger.transports.console({ data, date: /* @__PURE__ */ new Date(), level });
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
      const logsPath = path2.dirname(transport.resolvePathFn(pathVariables));
      if (!fs2.existsSync(logsPath)) {
        return [];
      }
      return fs2.readdirSync(logsPath).map((fileName) => path2.join(logsPath, fileName)).filter(fileFilter).map((logPath) => {
        try {
          return {
            path: logPath,
            lines: fs2.readFileSync(logPath, "utf8").split(os.EOL)
          };
        } catch {
          return null;
        }
      }).filter(Boolean);
    }
  }
  function getDefaultFileName(processType = process.type) {
    switch (processType) {
      case "renderer":
        return "renderer.log";
      case "worker":
        return "worker.log";
      default:
        return "main.log";
    }
  }
  return file;
}
var ipc;
var hasRequiredIpc;
function requireIpc() {
  if (hasRequiredIpc) return ipc;
  hasRequiredIpc = 1;
  const { maxDepth, toJSON } = requireObject();
  const { transform } = requireTransform();
  ipc = ipcTransportFactory;
  function ipcTransportFactory(logger, { externalApi }) {
    Object.assign(transport, {
      depth: 3,
      eventId: "__ELECTRON_LOG_IPC__",
      level: logger.isDev ? "silly" : false,
      transforms: [toJSON, maxDepth]
    });
    return (externalApi == null ? void 0 : externalApi.isElectron()) ? transport : void 0;
    function transport(message) {
      var _a;
      if (((_a = message == null ? void 0 : message.variables) == null ? void 0 : _a.processType) === "renderer") {
        return;
      }
      externalApi == null ? void 0 : externalApi.sendIpc(transport.eventId, {
        ...message,
        data: transform({ logger, message, transport })
      });
    }
  }
  return ipc;
}
var remote;
var hasRequiredRemote;
function requireRemote() {
  if (hasRequiredRemote) return remote;
  hasRequiredRemote = 1;
  const http = require$$0$4;
  const https = require$$1$1;
  const { transform } = requireTransform();
  const { removeStyles } = requireStyle();
  const { toJSON, maxDepth } = requireObject();
  remote = remoteTransportFactory;
  function remoteTransportFactory(logger) {
    return Object.assign(transport, {
      client: { name: "electron-application" },
      depth: 6,
      level: false,
      requestOptions: {},
      transforms: [removeStyles, toJSON, maxDepth],
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
        logger.processMessage(
          {
            data: [`electron-log: can't POST ${transport.url}`, error],
            level: "warn"
          },
          { transports: ["console", "file"] }
        );
      },
      sendRequestFn({ serverUrl, requestOptions, body }) {
        const httpTransport = serverUrl.startsWith("https:") ? https : http;
        const request = httpTransport.request(serverUrl, {
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
      if (!transport.url) {
        return;
      }
      const body = transport.makeBodyFn({
        logger,
        message: { ...message, data: transform({ logger, message, transport }) },
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
  return remote;
}
var createDefaultLogger_1;
var hasRequiredCreateDefaultLogger;
function requireCreateDefaultLogger() {
  if (hasRequiredCreateDefaultLogger) return createDefaultLogger_1;
  hasRequiredCreateDefaultLogger = 1;
  const Logger = requireLogger();
  const ErrorHandler = requireErrorHandler();
  const EventLogger = requireEventLogger();
  const transportConsole = requireConsole();
  const transportFile = requireFile();
  const transportIpc = requireIpc();
  const transportRemote = requireRemote();
  createDefaultLogger_1 = createDefaultLogger;
  function createDefaultLogger({ dependencies, initializeFn }) {
    var _a;
    const defaultLogger = new Logger({
      dependencies,
      errorHandler: new ErrorHandler(),
      eventLogger: new EventLogger(),
      initializeFn,
      isDev: (_a = dependencies.externalApi) == null ? void 0 : _a.isDev(),
      logId: "default",
      transportFactories: {
        console: transportConsole,
        file: transportFile,
        ipc: transportIpc,
        remote: transportRemote
      },
      variables: {
        processType: "main"
      }
    });
    defaultLogger.default = defaultLogger;
    defaultLogger.Logger = Logger;
    defaultLogger.processInternalErrorFn = (e) => {
      defaultLogger.transports.console.writeFn({
        message: {
          data: ["Unhandled electron-log error", e],
          level: "error"
        }
      });
    };
    return defaultLogger;
  }
  return createDefaultLogger_1;
}
var main;
var hasRequiredMain$1;
function requireMain$1() {
  if (hasRequiredMain$1) return main;
  hasRequiredMain$1 = 1;
  const electron = require$$0$5;
  const ElectronExternalApi = requireElectronExternalApi();
  const { initialize: initialize2 } = requireInitialize();
  const createDefaultLogger = requireCreateDefaultLogger();
  const externalApi = new ElectronExternalApi({ electron });
  const defaultLogger = createDefaultLogger({
    dependencies: { externalApi },
    initializeFn: initialize2
  });
  main = defaultLogger;
  externalApi.onIpc("__ELECTRON_LOG__", (_, message) => {
    if (message.scope) {
      defaultLogger.Logger.getInstance(message).scope(message.scope);
    }
    const date = new Date(message.date);
    processMessage({
      ...message,
      date: date.getTime() ? date : /* @__PURE__ */ new Date()
    });
  });
  externalApi.onIpcInvoke("__ELECTRON_LOG__", (_, { cmd = "", logId }) => {
    switch (cmd) {
      case "getOptions": {
        const logger = defaultLogger.Logger.getInstance({ logId });
        return {
          levels: logger.levels,
          logId
        };
      }
      default: {
        processMessage({ data: [`Unknown cmd '${cmd}'`], level: "error" });
        return {};
      }
    }
  });
  function processMessage(message) {
    var _a;
    (_a = defaultLogger.Logger.getInstance(message)) == null ? void 0 : _a.processMessage(message);
  }
  return main;
}
var main_1;
var hasRequiredMain;
function requireMain() {
  if (hasRequiredMain) return main_1;
  hasRequiredMain = 1;
  const main2 = requireMain$1();
  main_1 = main2;
  return main_1;
}
var mainExports = requireMain();
const log = /* @__PURE__ */ getDefaultExportFromCjs(mainExports);
let db = null;
let dbPath = "";
function getDbPath() {
  const userDir = require$$0$5.app.getPath("home");
  const valutaDir = path.join(userDir, ".valuta");
  if (!fs.existsSync(valutaDir)) {
    try {
      fs.mkdirSync(valutaDir, { recursive: true });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      throw new Error(`Nem sikerült létrehozni a valuta mappát: ${valutaDir}. ${message}`);
    }
  }
  return path.join(valutaDir, "local.db");
}
function resolveWasmPath() {
  const candidates = [];
  if (require$$0$5.app.isPackaged) {
    candidates.push(path.join(process.resourcesPath, "sql-wasm.wasm"));
    candidates.push(path.join(require$$0$5.app.getAppPath(), "resources", "sql-wasm.wasm"));
    candidates.push(path.join(require$$0$5.app.getAppPath(), "sql-wasm.wasm"));
    candidates.push(path.join(__dirname, "sql-wasm.wasm"));
  } else {
    candidates.push(path.join(__dirname, "../node_modules/sql.js/dist/sql-wasm.wasm"));
    candidates.push(path.join(process.cwd(), "node_modules/sql.js/dist/sql-wasm.wasm"));
  }
  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  throw new Error(`sql-wasm.wasm nem található. Próbált útvonalak: ${candidates.join(" | ")}`);
}
async function initDatabase() {
  try {
    dbPath = getDbPath();
    const wasmPath = resolveWasmPath();
    const wasmBinary = fs.readFileSync(wasmPath);
    const SQL = await initSqlJs({ wasmBinary });
    if (fs.existsSync(dbPath)) {
      const buffer = fs.readFileSync(dbPath);
      db = new SQL.Database(buffer);
    } else {
      db = new SQL.Database();
    }
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
        updated_at TEXT NOT NULL
      );
    `);
    db.run(`
      CREATE TABLE IF NOT EXISTS pending_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('SELL', 'BUY')),
        currency_code TEXT NOT NULL,
        foreign_amount REAL NOT NULL,
        huf_amount REAL NOT NULL,
        rounded_huf_amount REAL NOT NULL,
        rate REAL NOT NULL,
        customer_id INTEGER,
        denominations TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
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
        target_branch_code TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        denominations TEXT,
        note TEXT,
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
      CREATE TABLE IF NOT EXISTS pending_collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_branch_code TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
    saveDatabase();
  } catch (err) {
    const error = err;
    const errorCode = "code" in error && error.code ? String(error.code) : "unknown";
    const errorMessage = error instanceof Error ? error.message : String(error);
    const wasmPath = (() => {
      try {
        return resolveWasmPath();
      } catch (resolveErr) {
        const resolveMessage = resolveErr instanceof Error ? resolveErr.message : String(resolveErr);
        return `resolve error: ${resolveMessage}`;
      }
    })();
    const details = [
      `dbPath=${dbPath || "n/a"}`,
      `wasmPath=${wasmPath}`,
      `resourcesPath=${process.resourcesPath}`,
      `appPath=${require$$0$5.app.getAppPath()}`,
      `isPackaged=${require$$0$5.app.isPackaged}`,
      `errorCode=${errorCode}`,
      `errorMessage=${errorMessage}`
    ].join("\n");
    throw new Error(`Database init failed:
${details}`);
  }
}
function saveDatabase() {
  if (!db) return;
  const data = db.export();
  const buffer = Buffer.from(data);
  fs.writeFileSync(dbPath, buffer);
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
  if (key.length > 100) {
    throw new Error(`Config key too long: ${key.length} chars (max 100)`);
  }
  if (value.length > 1e4) {
    throw new Error(`Config value too long: ${value.length} chars (max 10000)`);
  }
  db.run(
    `INSERT INTO config (key, value, updated_at) VALUES (?, ?, datetime('now'))
     ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at`,
    [key, value]
  );
  saveDatabase();
}
function deleteConfig(key) {
  if (!db) return;
  db.run("DELETE FROM config WHERE key = ?", [key]);
  saveDatabase();
}
function savePendingTransaction(type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, customerId, denominations) {
  if (!db) throw new Error("Database not initialized");
  db.run(
    `INSERT INTO pending_transactions (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, customer_id, denominations)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, customerId, denominations]
  );
  saveDatabase();
  const stmt = db.prepare("SELECT last_insert_rowid() as id");
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return row["id"] ?? 0;
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
  db.run(
    `INSERT INTO pending_distributions (target_branch_code, currency_code, amount, denominations, note)
     VALUES (?, ?, ?, ?, ?)`,
    [targetBranchCode, currencyCode, amount, denominations, note]
  );
  saveDatabase();
  const stmt = db.prepare("SELECT last_insert_rowid() as id");
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return row["id"] ?? 0;
}
function getPendingDistributions() {
  if (!db) return [];
  const results = [];
  const stmt = db.prepare("SELECT * FROM pending_distributions WHERE synced = 0 ORDER BY created_at ASC");
  while (stmt.step()) {
    results.push(stmt.getAsObject());
  }
  stmt.free();
  return results;
}
function markDistributionSynced(id) {
  if (!db) return;
  db.run("UPDATE pending_distributions SET synced = 1 WHERE id = ?", [id]);
  saveDatabase();
}
function savePendingTransfer(targetBranchCode, currencyCode, amount, denominations, note) {
  if (!db) throw new Error("Database not initialized");
  db.run(
    `INSERT INTO pending_transfers (target_branch_code, currency_code, amount, denominations, note)
     VALUES (?, ?, ?, ?, ?)`,
    [targetBranchCode, currencyCode, amount, denominations, note]
  );
  saveDatabase();
  const stmt = db.prepare("SELECT last_insert_rowid() as id");
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return row["id"] ?? 0;
}
function getPendingTransfers() {
  if (!db) return [];
  const results = [];
  const stmt = db.prepare("SELECT * FROM pending_transfers WHERE synced = 0 ORDER BY created_at ASC");
  while (stmt.step()) {
    results.push(stmt.getAsObject());
  }
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
  db.run(
    `INSERT INTO pending_collections (source_branch_code, currency_code, amount, note)
     VALUES (?, ?, ?, ?)`,
    [sourceBranchCode, currencyCode, amount, note]
  );
  saveDatabase();
  const stmt = db.prepare("SELECT last_insert_rowid() as id");
  stmt.step();
  const row = stmt.getAsObject();
  stmt.free();
  return row["id"] ?? 0;
}
function getPendingCollections() {
  if (!db) return [];
  const results = [];
  const stmt = db.prepare("SELECT * FROM pending_collections WHERE synced = 0 ORDER BY created_at ASC");
  while (stmt.step()) {
    results.push(stmt.getAsObject());
  }
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
  db.run(
    `INSERT INTO cached_branch_status (branch_code, branch_name, company_id, last_sync_at, online_status, total_huf_value, daily_turnover, cash_balances, cached_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(branch_code) DO UPDATE SET
       branch_name = excluded.branch_name,
       company_id = excluded.company_id,
       last_sync_at = excluded.last_sync_at,
       online_status = excluded.online_status,
       total_huf_value = excluded.total_huf_value,
       daily_turnover = excluded.daily_turnover,
       cash_balances = excluded.cash_balances,
       cached_at = excluded.cached_at`,
    [branchCode, branchName, companyId, lastSyncAt, onlineStatus, totalHufValue, dailyTurnover, cashBalances]
  );
  saveDatabase();
}
function getCachedBranchStatuses() {
  if (!db) return [];
  const results = [];
  const stmt = db.prepare("SELECT * FROM cached_branch_status ORDER BY branch_code ASC");
  while (stmt.step()) {
    results.push(stmt.getAsObject());
  }
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
function getCachedRates() {
  if (!db) return [];
  const results = [];
  const stmt = db.prepare("SELECT * FROM cached_rates ORDER BY currency_code ASC");
  while (stmt.step()) {
    results.push(stmt.getAsObject());
  }
  stmt.free();
  return results;
}
const ESC = "\x1B";
const GS = "";
const CMD = {
  INIT: `${ESC}@`,
  ALIGN_CENTER: `${ESC}a`,
  ALIGN_LEFT: `${ESC}a\0`,
  BOLD_ON: `${ESC}E`,
  BOLD_OFF: `${ESC}E\0`,
  DOUBLE_WIDTH: `${GS}!`,
  DOUBLE_HEIGHT: `${GS}!`,
  DOUBLE_BOTH: `${GS}!`,
  NORMAL_SIZE: `${GS}!\0`,
  UNDERLINE_ON: `${ESC}-`,
  UNDERLINE_OFF: `${ESC}-\0`,
  CUT_PAPER: `${GS}V\0`,
  PARTIAL_CUT: `${GS}V`,
  FEED_LINES: (n) => `${ESC}d${String.fromCharCode(n)}`,
  LINE: "─".repeat(42),
  DOUBLE_LINE: "═".repeat(42)
};
const COMPANIES = {
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
const JOB_TYPE_LABELS = {
  sell: "ELADÁSI BIZONYLAT",
  buy: "VÁSÁRLÁSI BIZONYLAT",
  transfer: "ÁTADÁS-ÁTVÉTELI BIZONYLAT",
  storno: "STORNÓ BIZONYLAT",
  closing: "NAPI ZÁRÁS"
};
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
  if (data.type === "sell" || data.type === "buy") {
    lines.push(...generateTransactionLines(data));
  } else if (data.type === "transfer") {
    lines.push(...generateTransferLines(data));
  } else if (data.type === "storno") {
    lines.push(...generateStornoLines(data));
  } else if (data.type === "closing") {
    lines.push(...generateClosingLines(data));
  }
  if (data.customerName) {
    lines.push("");
    lines.push(CMD.LINE);
    lines.push(CMD.BOLD_ON);
    lines.push("ÜGYFÉL ADATOK:");
    lines.push(CMD.BOLD_OFF);
    lines.push(`Név:      ${data.customerName}`);
    if (data.customerDocType) {
      lines.push(`Igazolv.: ${data.customerDocType}`);
    }
    if (data.customerDocNumber) {
      lines.push(`Szám:     ${data.customerDocNumber}`);
    }
  }
  if (data.receiptNumber && (data.type === "sell" || data.type === "buy")) {
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
  if (data.transferNote) {
    lines.push(`Megjegyzés:  ${data.transferNote}`);
  }
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
    for (const d of summary.discrepancies) {
      lines.push(`  ${d.currencyCode}: várt ${formatAmount(d.expected)} → tény ${formatAmount(d.actual)} (${formatAmount(d.difference)})`);
    }
  }
  return lines;
}
function formatAmount(value) {
  if (value === void 0) return "—";
  return value.toLocaleString("hu-HU", { maximumFractionDigits: 2 });
}
function formatRate(value) {
  if (value === void 0) return "—";
  return value.toLocaleString("hu-HU", { minimumFractionDigits: 2, maximumFractionDigits: 4 });
}
async function printReceipt(data) {
  try {
    const content = generateReceiptContent(data);
    console.log("[PRINTER] Bizonylat nyomtatás:", data.type, data.receiptNumber);
    console.log(content);
    return true;
  } catch (err) {
    console.error("[PRINTER] Nyomtatási hiba:", err);
    return false;
  }
}
async function httpGet(url, token) {
  const headers = {
    "Content-Type": "application/json"
  };
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }
  const response = await fetch(url, {
    method: "GET",
    headers,
    signal: AbortSignal.timeout(1e4)
  });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }
  return response.json();
}
async function httpPost(url, body, token) {
  const headers = {
    "Content-Type": "application/json"
  };
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }
  const response = await fetch(url, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(15e3)
  });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }
  return response.json();
}
class SyncEngine {
  constructor() {
    __publicField(this, "intervalId", null);
    __publicField(this, "status", {
      lastSyncAt: null,
      lastSyncResult: null,
      isRunning: false
    });
  }
  getServerUrl() {
    const stored = getConfig("server_url");
    return stored ?? "http://localhost:8080/api/v1";
  }
  getAuthToken() {
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
      void this.runSync();
    }, 5e3);
    this.intervalId = setInterval(() => {
      void this.runSync();
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
      const result = await this.syncAll();
      this.status.lastSyncResult = result;
      if (result.synced > 0) {
        console.log(`[SyncEngine] ${result.synced} tranzakció szinkronizálva`);
      }
      if (result.failed > 0) {
        console.warn(`[SyncEngine] ${result.failed} tranzakció SIKERTELEN:`, result.errors);
      }
      if (this.getAuthToken()) {
        await this.syncRates();
        await this.syncCirculars();
        await this.syncDistributions();
        await this.syncTransfers();
        await this.syncCollections();
        await this.cacheBranchStatus();
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
  async syncAll() {
    const result = { synced: 0, failed: 0, errors: [] };
    const pending = getPendingTransactions();
    if (pending.length === 0) {
      return result;
    }
    const serverUrl = this.getServerUrl();
    const token = this.getAuthToken();
    if (!token) {
      result.errors.push("Nincs auth token — bejelentkezés szükséges");
      result.failed = pending.length;
      return result;
    }
    for (const tx of pending) {
      try {
        await this.syncTransaction(serverUrl, token, tx);
        markTransactionSynced(tx.id);
        result.synced++;
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        result.failed++;
        result.errors.push(`TX #${tx.id} (${tx.type} ${tx.currency_code}): ${errorMsg}`);
        if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
          result.errors.push("Hálózati hiba — további próbálkozások leállítva");
          result.failed += pending.length - result.synced - result.failed;
          break;
        }
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
      foreignAmount: tx.foreign_amount,
      hufAmount: tx.huf_amount,
      roundedHufAmount: tx.rounded_huf_amount,
      rate: tx.rate
    };
    if (tx.customer_id !== null) {
      body["customerId"] = tx.customer_id;
    }
    if (tx.denominations !== null) {
      try {
        body["denominations"] = JSON.parse(tx.denominations);
      } catch {
        body["denominations"] = tx.denominations;
      }
    }
    await httpPost(endpoint, body, token);
  }
  /**
   * Árfolyamok letöltése és SQLite cache frissítése.
   */
  async syncRates() {
    try {
      const serverUrl = this.getServerUrl();
      const token = this.getAuthToken();
      const rates = await httpGet(
        `${serverUrl}/rates`,
        token
      );
      const db2 = getDb();
      if (!db2 || !Array.isArray(rates)) return;
      for (const rate of rates) {
        db2.run(
          `INSERT INTO cached_rates (currency_code, buy_rate, sell_rate, unit, updated_at)
           VALUES (?, ?, ?, ?, ?)
           ON CONFLICT(currency_code) DO UPDATE SET
             buy_rate = excluded.buy_rate,
             sell_rate = excluded.sell_rate,
             unit = excluded.unit,
             updated_at = excluded.updated_at`,
          [rate.currencyCode, rate.buyRate, rate.sellRate, rate.unit, rate.updatedAt]
        );
      }
      console.log(`[SyncEngine] ${rates.length} árfolyam frissítve`);
    } catch (err) {
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
      const circulars = await httpGet(
        `${serverUrl}/circulars`,
        token
      );
      const db2 = getDb();
      if (!db2 || !Array.isArray(circulars)) return;
      db2.run(`
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
      for (const circular of circulars) {
        db2.run(
          `INSERT INTO cached_circulars (id, subject, body, sender, sent_at)
           VALUES (?, ?, ?, ?, ?)
           ON CONFLICT(id) DO UPDATE SET
             subject = excluded.subject,
             body = excluded.body,
             sender = excluded.sender,
             sent_at = excluded.sent_at`,
          [circular.id, circular.subject, circular.body, circular.sender, circular.sentAt]
        );
      }
      if (circulars.length > 0) {
        console.log(`[SyncEngine] ${circulars.length} körlevél szinkronizálva`);
      }
    } catch (err) {
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
      for (const dist of pending) {
        try {
          const body = {
            targetBranchCode: dist.target_branch_code,
            currencyCode: dist.currency_code,
            amount: dist.amount
          };
          if (dist.denominations) {
            try {
              body["denominations"] = JSON.parse(dist.denominations);
            } catch {
            }
          }
          if (dist.note) body["note"] = dist.note;
          await httpPost(`${serverUrl}/ertektar/distribution`, body, token);
          markDistributionSynced(dist.id);
        } catch (err) {
          console.warn(`[SyncEngine] Distribution #${dist.id} sync hiba:`, err instanceof Error ? err.message : err);
          break;
        }
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
      for (const tx of pending) {
        try {
          const body = {
            targetBranchCode: tx.target_branch_code,
            currencyCode: tx.currency_code,
            amount: tx.amount
          };
          if (tx.denominations) {
            try {
              body["denominations"] = JSON.parse(tx.denominations);
            } catch {
            }
          }
          if (tx.note) body["note"] = tx.note;
          await httpPost(`${serverUrl}/transfers`, body, token);
          markTransferSynced(tx.id);
        } catch (err) {
          console.warn(`[SyncEngine] Transfer #${tx.id} sync hiba:`, err instanceof Error ? err.message : err);
          break;
        }
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
      for (const col of pending) {
        try {
          const body = {
            sourceBranchCode: col.source_branch_code,
            currencyCode: col.currency_code,
            amount: col.amount
          };
          if (col.note) body["note"] = col.note;
          await httpPost(`${serverUrl}/ertektar/collections`, body, token);
          markCollectionSynced(col.id);
        } catch (err) {
          console.warn(`[SyncEngine] Collection #${col.id} sync hiba:`, err instanceof Error ? err.message : err);
          break;
        }
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
      const branches = await httpGet(
        `${serverUrl}/ertektar/branches/status`,
        token
      );
      if (!Array.isArray(branches)) return;
      for (const branch of branches) {
        saveCachedBranchStatus(
          branch.code,
          branch.name,
          branch.companyId,
          branch.lastSyncAt,
          branch.onlineStatus,
          branch.totalHufValue,
          branch.dailyTurnover,
          branch.cashBalances ? JSON.stringify(branch.cashBalances) : null
        );
      }
      if (branches.length > 0) {
        console.log(`[SyncEngine] ${branches.length} pénztár státusz cache-elve`);
      }
    } catch (err) {
      console.warn("[SyncEngine] Branch status cache hiba:", err instanceof Error ? err.message : err);
    }
  }
  /**
   * Aktuális szinkronizáció státusz lekérdezése.
   */
  getStatus() {
    return { ...this.status };
  }
}
const syncEngine = new SyncEngine();
const CAMERA_DIR = "C:/valuta/camera";
function sanitizeId$1(id) {
  const clean = id.replace(/[^a-zA-Z0-9_-]/g, "");
  if (!clean || clean !== id) throw new Error("Invalid transactionId: " + id);
  return clean;
}
function listDirectories(root) {
  if (!fs.existsSync(root)) return [];
  return fs.readdirSync(root).filter((entry) => {
    const fullPath = path.join(root, entry);
    return fs.existsSync(fullPath) && fs.statSync(fullPath).isDirectory();
  });
}
function collectFiles(root) {
  if (!fs.existsSync(root)) return [];
  const result = [];
  const entries = fs.readdirSync(root, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(root, entry.name);
    if (entry.isDirectory()) {
      result.push(...collectFiles(fullPath));
    } else if (entry.isFile()) {
      result.push(fullPath);
    }
  }
  return result;
}
function copyDirectoryWithCount(sourceDir, targetDir) {
  if (!fs.existsSync(sourceDir)) return 0;
  fs.mkdirSync(targetDir, { recursive: true });
  let count = 0;
  const entries = fs.readdirSync(sourceDir, { withFileTypes: true });
  for (const entry of entries) {
    const src = path.join(sourceDir, entry.name);
    const dest = path.join(targetDir, entry.name);
    if (entry.isDirectory()) {
      count += copyDirectoryWithCount(src, dest);
    } else if (entry.isFile()) {
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.copyFileSync(src, dest);
      count += 1;
    }
  }
  return count;
}
require$$0$5.ipcMain.handle("camera-save-recording", async (_event, transactionId, videoBuffer, extension) => {
  const date = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
  const safeId = sanitizeId$1(transactionId);
  const dir = path.join(CAMERA_DIR, date, safeId);
  fs.mkdirSync(dir, { recursive: true });
  const filename = `recording_${Date.now()}.${extension}`;
  const filepath = path.join(dir, filename);
  fs.writeFileSync(filepath, Buffer.from(videoBuffer));
  return filepath;
});
require$$0$5.ipcMain.handle("camera-export-to-usb", async (_event, dateFrom, dateTo) => {
  const result = await require$$0$5.dialog.showOpenDialog({
    title: "Válaszd ki az USB meghajtót",
    properties: ["openDirectory"],
    buttonLabel: "Exportálás ide"
  });
  if (result.canceled || !result.filePaths[0]) {
    return { success: false, exported: 0, error: "Megszakítva" };
  }
  const from = new Date(dateFrom);
  const to = new Date(dateTo);
  if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) {
    return { success: false, exported: 0, error: "Érvénytelen dátum" };
  }
  if (from > to) {
    return { success: false, exported: 0, error: "A dátumtartomány hibás" };
  }
  try {
    const targetDir = path.join(result.filePaths[0], "valuta_kamera_export");
    fs.mkdirSync(targetDir, { recursive: true });
    let exported = 0;
    const dateDirs = listDirectories(CAMERA_DIR);
    for (const dateDir of dateDirs) {
      const dateValue = new Date(dateDir);
      if (Number.isNaN(dateValue.getTime())) continue;
      if (dateValue < from || dateValue > to) continue;
      const sourceDir = path.join(CAMERA_DIR, dateDir);
      const destinationDir = path.join(targetDir, dateDir);
      exported += copyDirectoryWithCount(sourceDir, destinationDir);
    }
    return { success: true, exported };
  } catch (err) {
    return { success: false, exported: 0, error: `Írási hiba: ${err.message}` };
  }
});
require$$0$5.ipcMain.handle("camera-list-recordings", async (_event, transactionId) => {
  if (!fs.existsSync(CAMERA_DIR)) return [];
  if (transactionId) {
    const recordings = [];
    const safeId = sanitizeId$1(transactionId);
    const dateDirs = listDirectories(CAMERA_DIR);
    for (const dateDir of dateDirs) {
      const candidateDir = path.join(CAMERA_DIR, dateDir, safeId);
      recordings.push(...collectFiles(candidateDir));
    }
    return recordings;
  }
  return collectFiles(CAMERA_DIR);
});
const SCAN_DIR = "C:/valuta/scan";
const ENCRYPTION_KEY_FILE = "C:/valuta/.scan_key";
function sanitizeId(id) {
  const clean = id.replace(/[^a-zA-Z0-9_-]/g, "");
  if (!clean || clean !== id) throw new Error("Invalid transactionId: " + id);
  return clean;
}
function getOrCreateKey() {
  if (fs.existsSync(ENCRYPTION_KEY_FILE)) {
    const stored = fs.readFileSync(ENCRYPTION_KEY_FILE, "utf8").trim();
    return Buffer.from(stored, "base64");
  }
  const key = crypto.randomBytes(32);
  fs.writeFileSync(ENCRYPTION_KEY_FILE, key.toString("base64"), { mode: 384 });
  return key;
}
function encrypt(buffer) {
  const key = getOrCreateKey();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);
  const encrypted = Buffer.concat([cipher.update(buffer), cipher.final()]);
  const tag = cipher.getAuthTag();
  return { encrypted, iv: iv.toString("hex"), tag: tag.toString("hex") };
}
function decrypt(encrypted, iv, tag) {
  const key = getOrCreateKey();
  const decipher = crypto.createDecipheriv("aes-256-gcm", key, Buffer.from(iv, "hex"));
  decipher.setAuthTag(Buffer.from(tag, "hex"));
  return Buffer.concat([decipher.update(encrypted), decipher.final()]);
}
require$$0$5.ipcMain.handle("scan-save-document", async (_event, transactionId, documentType, imageBase64) => {
  const buffer = Buffer.from(imageBase64, "base64");
  const { encrypted, iv, tag } = encrypt(buffer);
  const date = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
  const safeId = sanitizeId(transactionId);
  const dir = path.join(SCAN_DIR, date, safeId);
  fs.mkdirSync(dir, { recursive: true });
  const filename = `${documentType}_${Date.now()}.enc`;
  const filepath = path.join(dir, filename);
  fs.writeFileSync(filepath, encrypted);
  fs.writeFileSync(
    `${filepath}.meta`,
    JSON.stringify({ iv, tag, documentType, timestamp: (/* @__PURE__ */ new Date()).toISOString() })
  );
  return { path: filepath, encrypted: true };
});
require$$0$5.ipcMain.handle("scan-get-document", async (_event, filepath) => {
  const resolved = path.resolve(filepath);
  if (!resolved.startsWith(path.resolve(SCAN_DIR))) {
    throw new Error("Érvénytelen fájlútvonal");
  }
  const encrypted = fs.readFileSync(resolved);
  const metaRaw = fs.readFileSync(`${resolved}.meta`, "utf8");
  const meta = JSON.parse(metaRaw);
  const decrypted = decrypt(encrypted, meta.iv, meta.tag);
  return decrypted.toString("base64");
});
require$$0$5.ipcMain.handle("scan-list-documents", async (_event, transactionId) => {
  if (!fs.existsSync(SCAN_DIR)) return [];
  const results = [];
  const safeId = sanitizeId(transactionId);
  const dateDirs = fs.readdirSync(SCAN_DIR);
  for (const dateDir of dateDirs) {
    const candidate = path.join(SCAN_DIR, dateDir, safeId);
    if (!fs.existsSync(candidate) || !fs.statSync(candidate).isDirectory()) continue;
    const files = fs.readdirSync(candidate);
    for (const file2 of files) {
      if (file2.endsWith(".enc")) {
        results.push(path.join(candidate, file2));
      }
    }
  }
  return results;
});
require$$0$5.ipcMain.handle("restart-app", () => {
  try {
    require$$0$5.app.relaunch();
    require$$0$5.app.exit(0);
    return true;
  } catch (err) {
    log.error("[Updater] restart-app failed", err);
    return false;
  }
});
const isDev = !require$$0$5.app.isPackaged;
log.initialize();
log.transports.file.level = "info";
log.transports.console.level = isDev ? "debug" : "warn";
process.on("uncaughtException", (err) => {
  log.error("[Process] uncaughtException", err);
});
process.on("unhandledRejection", (reason) => {
  log.error("[Process] unhandledRejection", reason);
});
let mainWindow = null;
function createWindow() {
  mainWindow = new require$$0$5.BrowserWindow({
    width: 1280,
    height: 1024,
    resizable: isDev,
    fullscreen: false,
    autoHideMenuBar: true,
    title: "Valuta Pénztár",
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });
  if (isDev) {
    mainWindow.loadURL("http://localhost:5173");
    mainWindow.webContents.openDevTools({ mode: "detach" });
  } else {
    mainWindow.loadFile(path.join(__dirname, "../dist/index.html"));
  }
  mainWindow.on("closed", () => {
    mainWindow = null;
  });
}
require$$0$5.ipcMain.handle("print-receipt", async (_event, dataJson) => {
  try {
    const data = JSON.parse(dataJson);
    return await printReceipt(data);
  } catch (err) {
    console.error("[IPC] print-receipt hiba:", err);
    return false;
  }
});
require$$0$5.ipcMain.handle("get-config", async (_event, key) => {
  return getConfig(key);
});
require$$0$5.ipcMain.handle("set-config", async (_event, key, value) => {
  setConfig(key, value);
});
require$$0$5.ipcMain.handle("delete-config", async (_event, key) => {
  deleteConfig(key);
});
require$$0$5.ipcMain.handle("save-pending-transaction", async (_event, type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, customerId, denominations) => {
  return savePendingTransaction(type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, customerId, denominations);
});
require$$0$5.ipcMain.handle("get-pending-transactions", async () => {
  return getPendingTransactions();
});
require$$0$5.ipcMain.handle("get-pending-transaction-count", async () => {
  return getPendingTransactionCount();
});
require$$0$5.ipcMain.handle("mark-transaction-synced", async (_event, id) => {
  markTransactionSynced(id);
});
require$$0$5.ipcMain.handle("sync-offline", async () => {
  const result = await syncEngine.syncAll();
  return result.synced;
});
require$$0$5.ipcMain.handle("get-sync-status", async () => {
  return JSON.stringify(syncEngine.getStatus());
});
require$$0$5.ipcMain.handle("get-app-version", async () => {
  return require$$0$5.app.getVersion();
});
require$$0$5.ipcMain.handle("get-printers", async () => {
  if (!mainWindow) return [];
  return mainWindow.webContents.getPrintersAsync();
});
require$$0$5.ipcMain.handle("save-pending-distribution", async (_event, targetBranchCode, currencyCode, amount, denominations, note) => {
  return savePendingDistribution(targetBranchCode, currencyCode, amount, denominations, note);
});
require$$0$5.ipcMain.handle("save-pending-transfer", async (_event, targetBranchCode, currencyCode, amount, denominations, note) => {
  return savePendingTransfer(targetBranchCode, currencyCode, amount, denominations, note);
});
require$$0$5.ipcMain.handle("save-pending-collection", async (_event, sourceBranchCode, currencyCode, amount, note) => {
  return savePendingCollection(sourceBranchCode, currencyCode, amount, note);
});
require$$0$5.ipcMain.handle("get-cached-branch-statuses", async () => {
  return getCachedBranchStatuses();
});
require$$0$5.ipcMain.handle("get-cached-branch-status-timestamp", async () => {
  return getCachedBranchStatusTimestamp();
});
require$$0$5.ipcMain.handle("get-cached-rates", async () => {
  return getCachedRates();
});
require$$0$5.app.whenReady().then(async () => {
  try {
    await initDatabase();
  } catch (err) {
    log.error("[App] initDatabase failed", err);
    const details = err instanceof Error ? err.message : String(err);
    require$$0$5.dialog.showErrorBox(
      "Adatbázis hiba",
      `A helyi adatbázist nem sikerült inicializálni.

Részletek:
${details}`
    );
    require$$0$5.app.quit();
    return;
  }
  createWindow();
  syncEngine.start(3e4);
  log.info("[App] SyncEngine elindítva");
});
require$$0$5.app.on("will-quit", () => {
  syncEngine.stop();
  log.info("[App] SyncEngine leállítva");
});
require$$0$5.app.on("window-all-closed", () => {
  require$$0$5.app.quit();
});
require$$0$5.app.on("activate", () => {
  if (mainWindow === null) {
    createWindow();
  }
});
