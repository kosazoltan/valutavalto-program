/**
 * input-guard unit tesztek — böngésző-print billentyűk elfogása.
 * A createBeforeInputHandler pure factory: electron-mock nélkül tesztelhető.
 */
import { describe, it, expect, vi } from 'vitest';
import { createBeforeInputHandler, type GuardedInput } from '../input-guard';

function makeEvent() {
  return { preventDefault: vi.fn() };
}

function makeInput(partial: Partial<GuardedInput>): GuardedInput {
  return { key: '', type: 'keyDown', control: false, meta: false, alt: false, ...partial };
}

describe('createBeforeInputHandler — böngésző-print tiltás', () => {
  it('Ctrl+P keyDown → preventDefault (nincs Chromium print dialógus)', () => {
    const handler = createBeforeInputHandler();
    const event = makeEvent();
    handler(event, makeInput({ key: 'p', control: true }));
    expect(event.preventDefault).toHaveBeenCalledTimes(1);
  });

  it('Cmd+P (meta) → preventDefault', () => {
    const handler = createBeforeInputHandler();
    const event = makeEvent();
    handler(event, makeInput({ key: 'p', meta: true }));
    expect(event.preventDefault).toHaveBeenCalledTimes(1);
  });

  it('Ctrl+Shift+P nagybetűs key értékkel → preventDefault', () => {
    const handler = createBeforeInputHandler();
    const event = makeEvent();
    handler(event, makeInput({ key: 'P', control: true }));
    expect(event.preventDefault).toHaveBeenCalledTimes(1);
  });

  it('Ctrl+Alt+P (AltGr) → NEM blokkolt', () => {
    const handler = createBeforeInputHandler();
    const event = makeEvent();
    handler(event, makeInput({ key: 'p', control: true, alt: true }));
    expect(event.preventDefault).not.toHaveBeenCalled();
  });

  it('sima "p" módosító nélkül → NEM blokkolt', () => {
    const handler = createBeforeInputHandler();
    const event = makeEvent();
    handler(event, makeInput({ key: 'p' }));
    expect(event.preventDefault).not.toHaveBeenCalled();
  });

  it('Ctrl+S → NEM blokkolt (csak a P-kombinációt fogjuk el)', () => {
    const handler = createBeforeInputHandler();
    const event = makeEvent();
    handler(event, makeInput({ key: 's', control: true }));
    expect(event.preventDefault).not.toHaveBeenCalled();
  });
});

describe('createBeforeInputHandler — F12 DevTools (meglévő viselkedés)', () => {
  it('F12 keyDown → toggleDevTools hívódik, preventDefault NEM', () => {
    const toggleDevTools = vi.fn();
    const handler = createBeforeInputHandler({ toggleDevTools });
    const event = makeEvent();
    handler(event, makeInput({ key: 'F12' }));
    expect(toggleDevTools).toHaveBeenCalledTimes(1);
    expect(event.preventDefault).not.toHaveBeenCalled();
  });

  it('F12 keyUp → NEM toggle-öl (csak keyDown-ra)', () => {
    const toggleDevTools = vi.fn();
    const handler = createBeforeInputHandler({ toggleDevTools });
    handler(makeEvent(), makeInput({ key: 'F12', type: 'keyUp' }));
    expect(toggleDevTools).not.toHaveBeenCalled();
  });

  it('F12 toggleDevTools opció nélkül → no-op, nem dob', () => {
    const handler = createBeforeInputHandler();
    expect(() => handler(makeEvent(), makeInput({ key: 'F12' }))).not.toThrow();
  });
});
