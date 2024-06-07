# Fubax FX shaders for ReShade
This repository contains a collection of post-processing ReShade shaders, which I contribute, written in the [ReShade FX shader language](https://github.com/crosire/reshade-shaders/blob/slim/REFERENCE.md).

-----

## Donations
If you want to support this, visit [*PayPal link*](https://paypal.me/fubax).

-----

# FAQ for gamedevs
*How to legally integrate Fisheye shader into an upcoming game?*
* Add credit and indicate if changes were made, preferably in the end credits.
* Share the altered shader code on GitHub, if changed, under the same license.

Example:

```
Implements modified Aximorphic virtual lens (CC+ BY-SA 3.0)
by Jakub Max Fober
See the source on [our website link]
```

Additionally, you can [send me a notice](mailto:jakub.m.fober@protonmail.com) and I will happily promote your work.

-----

### [Perfect Perspective](/Shaders/PerfectPerspective.fx) FX (CC+ BY-SA 3.0) [*wiki*](https://github.com/Fubaxiusz/fubax-shaders/wiki/PerfectPerspective)
![Wreckfest with Perfect Perspective shader](https://github.com/Fubaxiusz/fubax-shaders/assets/34406163/c1c9d992-7fc8-4a32-a3ca-e7c201dd8105)
I recommend use of [REST addon](https://github.com/4lex4nder/ReshadeEffectShaderToggler/releases) to ignore the game UI.

### [Chromakey](/Shaders/Chromakey.fx) FX (CC BY-SA 4.0)
![Alien Isolation with Chromakey shader](https://github.com/Fubaxiusz/fubax-shaders/assets/34406163/d7f716af-a24a-474a-91a2-7eeb449aba50)

### [Filmic Anamorphic Sharpen](/Shaders/FilmicAnamorphSharpen.fx) FX (CC BY-SA 4.0)
![Inside Depth 6 with Filmic Anamorphic Sharpen shader](https://github.com/Fubaxiusz/fubax-shaders/assets/34406163/0ac08113-0f7a-4ad7-a78f-c02c48cf21da)

### [Vectorscope](/Shaders/Vectorscope.fx) FX (CC+ BY-NC-ND 3.0)
![MirrorsEdge with Vectorscope shader](https://github.com/Fubaxiusz/fubax-shaders/assets/34406163/c3d9c5c4-8203-4505-b3e6-bba63863a629)

### About ReShade
ReShade is an advanced, fully generic post-processing injector for games and video software. It allows you to add visual effects or adjust the appearance of the image, creating the visual experience you prefer.

To get ReShade, visit [https://reshade.me](https://reshade.me) official website.

## Installation
1. [Download the latest ReShade](https://reshade.me/#download) from the official site.
2. Select the game of choice for installation and the API it uses.
3. During installation, select ***"fubax-shaders by Fubaxiusz"*** along with ***"Standard effects"*** to download this shader-pack and required files.
4. Start your game, open the ReShade in-game menu, and search for the shaders.
5. [Visit the Wiki](https://github.com/Fubaxiusz/fubax-shaders/wiki/Home) to learn how to use my shaders.

### Prerequisites
Fubax-shaders require [Reshade](https://reshade.me) version 5.x or latest, and the *ReShade.fxh*, *ReShadeUI.fxh* files present in the `reshade-shaders\Shaders` folder.

## How to use?
Please [visit the Wiki page](https://github.com/Fubaxiusz/fubax-shaders/wiki/Home) to learn how to use various of my shaders (with image explanation), or jump right to:
+ [Perfect Perspective](https://github.com/Fubaxiusz/fubax-shaders/wiki/PerfectPerspective) guide

## Syntax
Check out [the language reference document](https://github.com/crosire/reshade-shaders/blob/master/REFERENCE.md) to get started on how to write your own!

## Licensing
Look into the shader source code to see the attached license notice. To see the source, you can explore this repository or right-click on a technique in ReShade and select *"Edit source code"*. You can reach out to me and negotiate custom licensing for commercial purposes.

## Contact
If you have a feature request, an idea, or a question, start an official issue thread or contact me directly.
If you want additional licensing for your commercial game, don't hesitate to talk to me.

Contact me via e-mail [*jakub.m.fober@pm.me*](mailto:jakub.m.fober@protonmail.com)

![]()
### Credits
Besides the shaders created from the ground up by me, a few of them were created as entirely new versions of existing effects, like [Tilt Shift](/Shaders/TiltShift.fx), [Monitor Gamma](/Shaders/MonitorGamma.fx) or [ACES](/Shaders/ACES.fx).

<p align=center>
© 2023 Jakub Maksymilian Fober
</p>
