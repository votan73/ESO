"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const DEFAULT_FILE_NAME = "ESOProfiler";
const JSONStream_1 = require("JSONStream");
const fs_1 = require("fs");
const stream_1 = require("stream");
function init(tr, document, Polymer) {
    const fs = require("fs");
    const ESOProfilerExportConverter = require("./converter").ESOProfilerExportConverter;
    const path = process.cwd().replace(/Elder Scrolls Online\\(.+)\\AddOns.*/, "Elder Scrolls Online\\$1\\SavedVariables");
    let saveButton;
    var viewer;
    var url;
    var model;
    var currentData = {};
    tr.exportTo('tr.importer', function () {
        function EsoProfilerImporter(model, eventData) {
            this.importPriority = 0;
            this.model = model;
            this.filename = eventData;
        }
        EsoProfilerImporter['canImport'] = function (eventData) {
            return typeof (eventData) === "string" && (eventData.endsWith(".lua") || eventData.endsWith(".json")); // TODO: we should test if the file can be actually read
        };
        EsoProfilerImporter.prototype = {
            __proto__: tr.importer.Importer.prototype,
            get importerName() {
                return 'EsoProfilerImporter';
            },
            isTraceDataContainer() {
                return true;
            },
            readLuaFile(filename) {
                const converter = new ESOProfilerExportConverter();
                return converter.convert(filename).then(data => {
                    currentData = data;
                    return [data];
                });
            },
            readJsonFile(filename) {
                return new Promise(function (resolve, reject) {
                    let incoming = {};
                    let readStream = fs_1.createReadStream(filename);
                    let transformStream = JSONStream_1.parse("$*");
                    readStream.pipe(transformStream);
                    transformStream.on("data", data => incoming[data.key] = data.value);
                    transformStream.on("close", () => {
                        currentData = incoming;
                        resolve([incoming]);
                    });
                    transformStream.on("error", err => reject(err));
                });
            },
            extractSubtraces() {
                if (this.filename.endsWith(".lua")) {
                    return this.readLuaFile(this.filename);
                }
                else {
                    return this.readJsonFile(this.filename);
                }
            },
        };
        tr.importer.Importer.register(EsoProfilerImporter);
        return {
            EsoProfilerImporter,
        };
    });
    function onResultFail(err) {
        var overlay = new tr.ui.b.Overlay();
        overlay.textContent = err + ': ' + url + ' could not be loaded';
        overlay.title = 'Failed to fetch data';
        overlay.visible = true;
    }
    function onResult(result) {
        model = new tr.Model();
        var i = new tr.importer.Import(model);
        var p = i.importTracesWithProgressDialog(result);
        p.then(onModelLoaded, onImportFail);
    }
    function onModelLoaded() {
        saveButton.disabled = (currentData === "");
        viewer.model = model;
        viewer.viewTitle = url;
        console.log(model);
    }
    function onImportFail(err) {
        var overlay = new tr.ui.b.Overlay();
        overlay.textContent = tr.b.normalizeException(err).message;
        overlay.title = 'Import error';
        overlay.visible = true;
    }
    function loadFile(filename) {
        console.log("loadFile", filename);
        url = filename;
        saveButton.disabled = true;
        onResult([filename]);
    }
    let saveFileName = "";
    function createSaveFile(overlay) {
        return new Promise(function (resolve, reject) {
            console.log("createSaveFile");
            overlay.update("Creating file...");
            let writeStream = fs_1.createWriteStream(saveFileName);
            writeStream.on("close", () => resolve(overlay));
            writeStream.on("error", err => reject(err));
            let otherData = JSON.stringify(currentData.otherData);
            writeStream.write(`{\n`);
            writeStream.write(`"otherData": ${otherData},\n`);
            writeStream.end();
        });
    }
    function writeTraceEvents(overlay) {
        return new Promise(function (resolve, reject) {
            console.log("writeTraceEvents");
            overlay.update("Writing trace events...");
            let eventStream = new stream_1.Stream.Readable({ objectMode: true });
            let tranformStream = JSONStream_1.stringify("", ",\n", "");
            let writeStream = fs_1.createWriteStream(saveFileName, { flags: "a" });
            writeStream.on("close", () => resolve(overlay));
            writeStream.on("error", err => reject(err));
            let finished = false;
            tranformStream.on("data", data => {
                if (!data && !finished) {
                    finished = true;
                    writeStream.write(`\n],\n`);
                }
            });
            eventStream.pipe(tranformStream).pipe(writeStream);
            writeStream.write(`"traceEvents": [\n`);
            currentData.traceEvents.forEach(event => eventStream.push(event));
            eventStream.push(null);
        });
    }
    function writeStackFrames(overlay) {
        return new Promise(function (resolve, reject) {
            console.log("writeStackFrames");
            overlay.update("Writing stack frames...");
            let eventStream = new stream_1.Stream.Readable({ objectMode: true });
            let tranformStream = JSONStream_1.stringifyObject("", ",\n", "");
            let writeStream = fs_1.createWriteStream(saveFileName, { flags: "a" });
            writeStream.on("close", () => resolve(overlay));
            writeStream.on("error", err => reject(err));
            let finished = false;
            tranformStream.on("data", data => {
                if (!data && !finished) {
                    finished = true;
                    writeStream.write(`\n}\n`);
                }
            });
            eventStream.pipe(tranformStream).pipe(writeStream);
            let stackFrames = currentData.stackFrames;
            let stackId = Object.keys(stackFrames);
            writeStream.write(`"stackFrames": {\n`);
            stackId.forEach(id => eventStream.push([id, stackFrames[id]]));
            eventStream.push(null);
        });
    }
    function finalizeSaveFile(overlay) {
        return new Promise(function (resolve, reject) {
            console.log("finalizeSaveFile");
            overlay.update("Finalizing file...");
            let writeStream = fs_1.createWriteStream(saveFileName, { flags: "a" });
            writeStream.on("close", () => resolve(overlay));
            writeStream.on("error", err => reject(err));
            writeStream.write(`}\n`);
            writeStream.end();
        });
    }
    function saveFile(filename) {
        console.log("saveFile", filename, currentData);
        const overlay = tr.ui.b.Overlay();
        overlay.title = 'Exporting...';
        overlay.userCanClose = false;
        overlay.msgEl = document.createElement('div');
        Polymer.dom(overlay).appendChild(overlay.msgEl);
        overlay.msgEl.style.margin = '20px';
        overlay.update = function (msg) {
            Polymer.dom(this.msgEl).textContent = msg;
        };
        overlay.visible = true;
        saveFileName = filename;
        createSaveFile(overlay)
            .then(writeTraceEvents)
            .then(writeStackFrames)
            .then(finalizeSaveFile)
            .then(() => {
            console.log("Finished saving to", filename);
            overlay.visible = false;
        }, err => {
            console.error("Could not save file", filename, err);
            overlay.visible = false;
        });
    }
    var container = document.createElement('track-view-container');
    container.id = 'track_view_container';
    viewer = document.createElement('tr-ui-timeline-view');
    viewer.track_view_container = container;
    viewer.appendChild(container);
    viewer.id = 'trace-viewer';
    viewer.globalMode = true;
    document.body.appendChild(viewer);
    let loadButton = document.getElementById("loadButton");
    let loadInput = document.getElementById("loadInput");
    saveButton = document.getElementById("saveButton");
    let saveInput = document.getElementById("saveInput");
    let fileButtons = document.getElementById("fileButtons");
    console.log(fileButtons);
    document.body.removeChild(fileButtons);
    viewer.leftControls.appendChild(fileButtons);
    loadButton.addEventListener("click", e => loadInput.click());
    loadInput.addEventListener("change", e => loadFile(loadInput.value));
    saveButton.addEventListener("click", e => {
        let name = DEFAULT_FILE_NAME;
        if (model && model.metadata && model.metadata.length > 0 && model.metadata[0].value.startTime) {
            name += "-" + model.metadata[0].value.startTime;
        }
        saveInput.nwsaveas = name + ".json";
        saveInput.click();
    });
    saveInput.addEventListener("change", e => saveFile(saveInput.value));
    loadInput.nwworkingdir = `${path}\\${DEFAULT_FILE_NAME}.lua`;
    if (path.endsWith("SavedVariables")) {
        loadFile(`${path}\\${DEFAULT_FILE_NAME}.lua`);
    }
}
exports.init = init;
