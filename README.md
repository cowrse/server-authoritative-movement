# Server-Authoritative Movement

A Roblox resource that hands control of player characters to the server, so a client cannot move its own character through speed hacks or teleports. The client only tells the server which way its camera is facing. The server owns the physics and decides where the character actually is.

[Play the demo on Roblox](https://www.roblox.com/games/70928060199437)

## How it works

**The server owns the character.** While the system is on, the server sets the character’s network owner to `nil` every frame. Roblox then simulates that character on the server, so anything a client does to its own character’s position is overwritten.

**The client sends only its camera direction.** When the camera is locked (shift lock), the client packs the two rotation components it needs into an 8-byte `buffer` and sends it each frame. The server turns them into a facing angle with `math.atan2` and rotates the character to match.

**Smoothing on the client.** The server-owned position is placed on an anchored part in the `Hurtboxes` folder. An `IKControl` on the character targets an attachment on that part. Each client sets the IKControl’s `SmoothTime` to its own frame time, so other players’ characters glide toward the server position instead of jumping.

**Settings panel.** A small UI lets you change walk speed and jump power, or switch the system off to compare against normal client-owned movement. These requests are also sent as 8-byte buffers.

## Files

| File | Runs on | Purpose |
| --- | --- | --- |
| `src/ServerScriptService/SAMServer.server.luau` | Server | Network ownership, the server-side position part, facing, and settings |
| `src/ReplicatedStorage/UpdateHz.client.luau` | Client | Sends the camera direction and drives IKControl smoothing |
| `src/StarterGui/Settings/Main.client.luau` | Client | The walk speed, jump power, and on/off controls |
| `place/ServerAuthoritativeMovement.rbxlx` | Studio | The complete, ready-to-run place |

## Getting started

Open `place/ServerAuthoritativeMovement.rbxlx` in Roblox Studio and press Play. The place includes the remotes, the `Hurtboxes` and `IKControls` folders, the `Aligns` IKControl template, and the settings UI that the scripts expect.

The `src` folder holds the same scripts as plain files for reading or for use with Rojo.

## Notes

- The place also contains a copy of Roblox’s default R15 `Animate` script. It is Roblox’s code, is not part of this resource, and is not covered by this repository’s license.
- The settings remote lets any player set their own walk speed and jump power. That is intended for the demo. Remove or validate it before using this in a game.

## Credit

If you use this in a game, please credit **cowrse** in the game's description or credits. It isn't required by the license, but it's appreciated.

## License

[MIT](LICENSE) © 2026 Anthony Saade
