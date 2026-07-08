#!/usr/bin/env node
// Cross-platform backend launcher - Windows: mvnw.cmd, Linux/Mac: ./mvnw
import { spawn } from 'node:child_process'
import { platform } from 'node:os'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(__dirname, '..')
const isWin = platform() === 'win32'
const BACKEND_DIR = resolve(ROOT, 'backend')
const mvnw = isWin ? '.\\mvnw.cmd' : './mvnw'

const jvmArgs = [
  '-DENCRYPTION_SALT=00112233445566778899aabbccddeeff',
  '-DENCRYPTION_KEY=dev-only-local-key-32chars-xxxxx',
].join(' ')

const args = ['spring-boot:run', `-Dspring-boot.run.jvmArguments=${jvmArgs}`]
console.log(`[dev-backend] Launching: ${mvnw} ${args.join(' ')}`)
const child = spawn(mvnw, args, {
  cwd: BACKEND_DIR,
  stdio: 'inherit',
  shell: isWin,
})
child.on('exit', (code) => process.exit(code ?? 0))
