#!/usr/bin/env node
import { readFile } from 'node:fs/promises'
import { buildRatePackage } from './packageBuilder.js'
import { fetchBootstrap, publishRatePackage, type RateMakerApiConfig } from './api.js'
import type { BuildRatePackageInput } from './types.js'

function getConfig(): RateMakerApiConfig {
  const serverBaseUrl = process.env.RATE_MAKER_SERVER_URL
  const accessToken = process.env.RATE_MAKER_ACCESS_TOKEN
  if (!serverBaseUrl) throw new Error('RATE_MAKER_SERVER_URL kornyezeti valtozo hianyzik')
  if (!accessToken) throw new Error('RATE_MAKER_ACCESS_TOKEN kornyezeti valtozo hianyzik')
  return { serverBaseUrl, accessToken }
}

async function readJsonFile<T>(path: string): Promise<T> {
  const raw = await readFile(path, 'utf8')
  return JSON.parse(raw) as T
}

async function main(): Promise<void> {
  const command = process.argv[2]
  const config = getConfig()

  if (command === 'bootstrap') {
    const result = await fetchBootstrap(config)
    process.stdout.write(`${JSON.stringify(result, null, 2)}\n`)
    return
  }

  if (command === 'publish') {
    const inputPath = process.argv[3]
    if (!inputPath) {
      throw new Error('Hasznalat: arfolyam-keszito publish <rates.json>')
    }
    const input = await readJsonFile<BuildRatePackageInput>(inputPath)
    const ratePackage = buildRatePackage(input)
    const result = await publishRatePackage(config, ratePackage)
    process.stdout.write(
      `${JSON.stringify({ localPackage: ratePackage, server: result }, null, 2)}\n`,
    )
    return
  }

  throw new Error('Hasznalat: arfolyam-keszito bootstrap | publish <rates.json>')
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error)
  process.stderr.write(`Hiba: ${message}\n`)
  process.exitCode = 1
})
