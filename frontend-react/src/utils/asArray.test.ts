import { describe, it, expect } from 'vitest'
import { asArray } from './asArray'

describe('asArray<T>', () => {
    it('egyszeru array-t atadja', () => {
        expect(asArray<number>([1, 2, 3])).toEqual([1, 2, 3])
    })

    it('null-t ures array-ra alakit', () => {
        expect(asArray<number>(null)).toEqual([])
    })

    it('undefined-et ures array-ra alakit', () => {
        expect(asArray<number>(undefined)).toEqual([])
    })

    it('object-et ures array-ra alakit', () => {
        expect(asArray<number>({ content: [1, 2] })).toEqual([])
    })

    it('string-et ures array-ra alakit (defensive)', () => {
        expect(asArray<string>('not-an-array')).toEqual([])
    })

    it('ures array-t visszaad', () => {
        expect(asArray<number>([])).toEqual([])
    })
})
