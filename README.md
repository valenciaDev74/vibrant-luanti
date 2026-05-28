# Luanti Shaders

Custom GLSL shader pipeline for [Luanti](https://www.luanti.org/) (formerly Minetest), enhancing the game's visuals with advanced rendering techniques.

## Overview

| Directory | Stage | Purpose |
|---|---|---|
| `nodes_shader/` | GBuffer / Forward | Renders world nodes (blocks) with diffuse lighting, fog, parallax mapping, and dynamic shadows |
| `object_shader/` | GBuffer / Forward | Renders entities, items, and players with skinning, lighting, and shadow support |
| `shadow/pass1/` | Shadow map | Writes depth from solid geometry to the shadow map |
| `shadow/pass1_trans/` | Shadow map | Writes depth + color from translucent geometry for colored shadows |
| `shadow/pass2/` | Shadow resolve | Combines solid and translucent shadow maps into the final shadow texture |
| `second_stage/` | Post-processing | Tone mapping (Uncharted 2), gamma correction, bloom, auto-exposure, dithering, saturation |
| `volumetric_light/` | Post-processing | Volumetric light scattering (god rays) from sun/moon with noise-based sampling |

## Screenshots

![Screenshot 1](https://cdn.discordapp.com/attachments/628943954397888522/1509353406274473994/screenshot_20260527_095849.png?ex=6a18de66&is=6a178ce6&hm=9cfe5b93ee044e30187f626937d500a16cc1b7ba737f682e622f7537200b01b6)
![Screenshot 2](https://media.discordapp.net/attachments/628943954397888522/1509353596427173948/screenshot_20260524_152018.png?ex=6a18de93&is=6a178d13&hm=3fc8a84bff7e594f04ed3979fd636a79f92d642755cc565b57a5e9e0ea9eca02&=&format=webp&quality=lossless&width=1006&height=529)
![Screenshot 3](https://media.discordapp.net/attachments/628943954397888522/1509353663259213884/screenshot_20260525_184557.png?ex=6a18dea3&is=6a178d23&hm=8580a962d017e7519e986d74c398b4b2b1d7148d4b716f97a1c2c4f2d3180d98&=&format=webp&quality=lossless&width=1006&height=529)

## Features

- **Physically-based tone mapping** — Uncharted 2 filmic curve with configurable exposure and gamma
- **Dynamic shadows** — PCF soft shadows with colored translucency support and Poisson disk filtering
- **Volumetric lighting** — Screen-space god rays with blue noise dithering
- **Bloom** — Bright-pass extraction, blur, and debug visualization
- **Auto-exposure** — Luminance-adaptive exposure compensation
- **SSAA** — Supersampling anti-aliasing
- **Specular lighting on nodes** — Per-pixel specular highlights
- **Water reflections** — Screen-space reflections on water surfaces
- **Translucent foliage** — Alpha-tested leaf transparency with shadow support
- **Waving plants, leaves, and water** — Vertex-animated foliage and waves
- **Parallax mapping** — Depth-based texture offset for nodes
- **Fog** — Distance-based fog with configurable color and density
- **Dithering** — Ordered dithering to reduce banding in low-precision color formats

## Requirements

- Luanti (Minetest) 5.x+
- OpenGL 3.3+ / OpenGL ES 3.0+
- `enable_shaders = true` in `minetest.conf`
- All effects are gated by `ENABLE_*` defines — enable them in Luanti's settings for the full experience

## Installation

1. Copy the `nodes_shader/`, `object_shader/`, `shadow/`, `second_stage/`, and `volumetric_light/` folders into your Luanti shaderpack directory (e.g. `~/.minetest/shaders/`).
2. Copy the `mods/shader_complements/` folder into your Luanti mods directory (`~/.minetest/mods/`) and enable it in the world settings.

## License

MIT
