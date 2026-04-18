---
type: analysis
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Camera Endpoint and Test Gap List"
load: on-demand
---

# Camera Endpoint and Test Gap List

> Cel: a kamera alrendszer kulon HTTP/IPC endpoint-matrixa es a hozza tartozo teszt-gap lista.
> Gepi matrix: `generated/camera-endpoint-gap-list-2026-04-09.csv`

---

## S1 HTTP_ENDPOINT_MATRIX

| Endpoint | Handler | Role / auth | Evidence | Test evidence | Status |
|----------|---------|-------------|----------|---------------|--------|
| `GET /api/v1/camera/stream/{cameraId}` | `CameraController.getLiveFrame` | `MANAGER`, `ADMIN` | `CameraController.java` | `CameraControllerSecurityTest.java` | implemented |
| `GET /api/v1/camera/status` | `CameraController.getCameraStatus` | `MANAGER`, `ADMIN` | `CameraController.java` | `CameraControllerSecurityTest.java` | implemented |
| `GET /api/v1/camera/recordings` | `CameraController.getRecordings` | `MANAGER`, `ADMIN` | `CameraController.java` | `CameraControllerSecurityTest.java` | implemented |
| `GET /api/v1/camera/recordings/{id}` | `CameraController.getRecording` | `MANAGER`, `ADMIN` | `CameraController.java` | `CameraControllerSecurityTest.java` | implemented |
| `GET /api/v1/camera/recordings/by-receipt/{receiptNumber}` | `CameraController.findByReceipt` | `MANAGER`, `ADMIN` | `CameraController.java` | nincs dedikalt controller teszt | partial |
| `GET /api/v1/camera/recordings/by-transaction/{transactionId}` | `CameraController.findByTransaction` | `MANAGER`, `ADMIN` | `CameraController.java` | `CameraControllerSecurityTest.java` | partial |
| `GET /api/v1/camera/admin/configs` | `CameraAdminController.getConfigs` | `ADMIN` | `CameraAdminController.java` | `CameraAdminControllerSecurityTest.java` | implemented |
| `POST /api/v1/camera/admin/configs` | `CameraAdminController.saveConfig` | `ADMIN` | `CameraAdminController.java` | `CameraAdminControllerSecurityTest.java` | partial |
| `DELETE /api/v1/camera/admin/configs/{id}` | `CameraAdminController.deleteConfig` | `ADMIN` | `CameraAdminController.java` | `CameraAdminControllerSecurityTest.java` | partial |
| `GET /api/v1/camera/admin/storage-stats` | `CameraAdminController.getStorageStats` | `ADMIN` | `CameraAdminController.java` | nincs dedikalt teszt | missing-test |
| `POST /api/v1/camera/admin/cleanup` | `CameraAdminController.manualCleanup` | `ADMIN` | `CameraAdminController.java` | nincs dedikalt teszt | missing-test |
| `GET /api/v1/camera/admin/upload-status` | `CameraAdminController.getUploadStatus` | `ADMIN` | `CameraAdminController.java` | nincs dedikalt teszt | missing-test |
| `GET /api/v1/camera/admin/access-logs/{recordingId}` | `CameraAdminController.getAccessLogs` | `ADMIN` | `CameraAdminController.java` | `CameraAdminControllerSecurityTest.java` | partial |
| `POST /api/v1/camera/export/request` | `CameraExportController.createRequest` | export authorities | `CameraExportController.java` | nincs dedikalt MockMvc/integration teszt | missing-test |
| `POST /api/v1/camera/export/{requestId}/approve` | `CameraExportController.approve` | approve authorities | `CameraExportController.java` | nincs dedikalt teszt | missing-test |
| `POST /api/v1/camera/export/{requestId}/reject` | `CameraExportController.reject` | approve authorities | `CameraExportController.java` | nincs dedikalt teszt | missing-test |
| `POST /api/v1/camera/export/{requestId}/execute` | `CameraExportController.execute` | export authorities | `CameraExportController.java` | nincs dedikalt teszt | missing-test |
| `GET /api/v1/camera/export/{requestId}` | `CameraExportController.getById` | export/compliance authorities | `CameraExportController.java` | nincs dedikalt teszt | missing-test |
| `GET /api/v1/camera/export/pending` | `CameraExportController.getPending` | approve authorities | `CameraExportController.java` | nincs dedikalt teszt | missing-test |
| `GET /api/v1/camera/export/branch/{branchId}` | `CameraExportController.getByBranch` | export/compliance authorities | `CameraExportController.java` | nincs dedikalt teszt | missing-test |
| `GET /api/v1/camera/export/{requestId}/custody` | `CameraExportController.getCustody` | export/compliance authorities | `CameraExportController.java` | nincs dedikalt teszt | missing-test |
| `POST /api/v1/camera/export/verify-chain` | `CameraExportController.verifyChain` | local/compliance/IT authorities | `CameraExportController.java` | `DariusAndCameraPathCompatibilityTest.java` | implemented |
| `POST /api/camera/export/verify-chain` | legacy alias | local/compliance/IT authorities | `CameraExportController.java` | `DariusAndCameraPathCompatibilityTest.java` | implemented |

---

## S2 ELECTRON_IPC_MATRIX

| IPC channel | Purpose | Test status |
|-------------|---------|-------------|
| `camera-save-recording` | local recording write | no dedicated test |
| `camera-export-to-usb` | USB export | no dedicated test |
| `camera-list-recordings` | local listing | no dedicated test |
| `camera-local-storage-stats` | storage stats | no dedicated test |
| `camera-local-recordings-by-date` | date query | no dedicated test |
| `camera-local-read-file` | local playback/read | no dedicated test |
| `camera-local-cleanup` | retention cleanup | no dedicated test |
| `camera-rtsp-start` | RTSP recording start | no dedicated test |
| `camera-rtsp-stop` | RTSP recording stop | no dedicated test |
| `camera-rtsp-status` | RTSP state | no dedicated test |
| `camera-rtsp-segments` | segment list | no dedicated test |
| `camera-encrypt-file` | file encryption | no dedicated test |
| `camera-decrypt-file` | file decryption | no dedicated test |
| `camera-verify-hash` | integrity check | no dedicated test |
| `camera-generate-key` | key generation | no dedicated test |

---

## S3 TEST_EVIDENCE

### Backend test files

- `backend/src/test/java/hu/puzzleir/valuta/controller/CameraControllerSecurityTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/controller/CameraAdminControllerSecurityTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/controller/DariusAndCameraPathCompatibilityTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/service/CameraTransactionLinkerTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/service/TransactionServiceCameraLinkingTest.java`
- `backend/src/test/java/hu/puzzleir/valuta/service/CameraHashChainServiceTest.java`

### Frontend / Electron allapot

- penztar kliensben nincs kulon kamera unit test csomag
- az E2E csak a kamera status oldal betolteset erinti, workflow parity nincs

---

## S4 GAP_LIST

| Gap ID | Tema | Leiras | Risk |
|--------|------|--------|------|
| `CAM-G1` | export controller | a teljes request/approve/reject/execute workflow-hoz nincs MockMvc/integration coverage | P0 |
| `CAM-G2` | transaction id contract | a komment UUID vagy LONG bemenetet mond, a kod `Long.parseLong`-ot hiv | P0 |
| `CAM-G3` | playback endpoint | metadata van, de kulon `play`/binary playback endpoint nincs dokumentalt parity-vel | P1 |
| `CAM-G4` | MJPEG vs JPEG | a design MJPEG-szeru streaminget emlit, a kod single-JPEG frame-et ad | P1 |
| `CAM-G5` | cleanup/upload admin | admin cleanup/storage/upload endpoint-eknek nincs dedikalt controller tesztje | P1 |
| `CAM-G6` | conditional bean split | `CameraController`/`CameraAdminController` conditional, export controller nem az | P1 |
| `CAM-G7` | Electron IPC | RTSP, USB export, encryption, local playback coverage hianyzik | P0 |
| `CAM-G8` | legacy C1/C2 parity | legacy formatum es modern playback kozti regresszios horgony nincs | P1 |
| `CAM-G9` | dual stream parity | legacy dual/public-private stream viselkedes nincs explicit API-modellel lefedve | P2 |

---

## S5 AJANLOTT_TESZTEK

1. `CameraExportControllerWorkflowTest` teljes 4-eyes export folyamatra
2. `CameraControllerTransactionIdParsingTest` UUID vs LONG szerzodesre
3. `CameraAdminControllerOpsTest` storage/cleanup/upload-status endpoint-ekre
4. Electron IPC unit tests az `rtsp-recorder`, `camera-encryption`, `video-manager` modulokra
5. end-to-end export + custody + verify-chain regresszio
