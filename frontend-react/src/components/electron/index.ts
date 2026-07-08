/**
 * Electron-specific components barrel export.
 *
 * These components only function inside Electron (window.electronAPI).
 * Each component returns null when rendered in a plain browser context.
 */

export { default as CameraRecorder } from './CameraRecorder'
export { default as CameraExport } from './CameraExport'
export { default as DocumentScanner } from './DocumentScanner'
export { default as ReceiptPreviewModal } from './ReceiptPreviewModal'
