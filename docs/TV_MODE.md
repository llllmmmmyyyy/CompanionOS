# Companion TV Mode

The API 21 Phone application remains the authority for time, steps, parent confirmation and Preferences history. The existing three offline activities remain available. Four additional deterministic mock adventures cover MOVE, LEARN, IMAGINE and CALM.

## Working local demonstration

Home → Play on TV → Demo TV Mode → choose an adventure. Start on the phone; use Pause activity, Resume activity and Next step. Play on TV opens a landscape child player on the **same phone**. Phone controller returns to the controls and restores the previous orientation. This demonstrates a receiver projection without requiring a television or network. Demo TV connection does not shorten the activity: the separate Demo Mode checkbox selects the ten-second timer; normal mode uses 3, 5 or 10 minutes.

The player displays large instructions, a media placeholder, countdown, step progress, pause state and a celebration. All media is currently local placeholder content; no generated videos are downloaded or played. Step changes are parent controlled. A timer expiring shows a celebration but only parent confirmation writes history. Disconnecting the transport leaves the phone timer and completed records intact. Pausing freezes remaining milliseconds; background reconciliation never resumes a paused activity. Active sessions are not persisted across process termination; saved settings and completed records are.

## Modules and transport contract

- `Companion.ets`: existing settings/history schema, extended activity metadata and pause-aware session.
- `AiActivityService.ets`: request/result contract, deterministic mock and validation/conversion.
- `TvSessionTransport.ets`: `TvSessionTransport`, phone-owned `TvFrame`, local receiver, and `HarmonyDistributedTvTransport` adapter.
- `NearbyTv.ets`: actual API 21 authorized-device lookup, on-demand distributed permission and honest unavailable/denied messages.
- `Index.ets`: connection page, phone controls and landscape receiver presentation.

Transport commands are connect, disconnect, start, pause, resume, cancel, nextStep and synchronize. Events include connection, disconnection, start, pause, resume, cancellation, step change and parent-confirmed completion. The local receiver has no independent timer or storage. The real adapter delegates these commands to an injected `DistributedTvChannel`; the app does **not** instantiate a working remote channel or claim a real TV connection.

## Real TV integration still required

Nearby devices lists only already-authorized devices visible to HarmonyOS DeviceManager, not an active unpaired-device discovery/pairing flow. Finding a device does not prove that it runs a compatible TV receiver. This project remains a Phone module; it does not deploy a TV application. A real TV integration needs compatible hardware/SDK, pairing, a TV receiver, an authenticated ordered channel, session/sequence validation, acknowledgements, disconnect events and reconnect resynchronization. Keep those APIs in the channel/service layer. Test permissions, supported device types and transport interruption on actual hardware before enabling a real connection button.

The real channel is an extension interface, not a completed end-to-end distributed implementation. A network outage currently cannot break Local Demo because it makes no network requests. Reliable background TV delivery and background notifications are not promised.
