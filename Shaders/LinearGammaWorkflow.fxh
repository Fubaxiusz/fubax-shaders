/*------------------.
| :: Description :: |
'-------------------/

Linear Gamma Workflow Library (version 1.4.3)

Author:
Jakub Maksymilian Fober

First publication:
2022-2023

Copyright:
This work is free of known copyright restrictions.
https://creativecommons.org/publicdomain/mark/1.0/
*/

#pragma once

// These are from the "color_space" enum in ReShade.
// They can be compared against "BUFFER_COLOR_SPACE", which is defined by ReShade shaders.
#ifndef RESHADE_COLOR_SPACE_UNKNOWN
#define RESHADE_COLOR_SPACE_UNKNOWN     0
#endif
#ifndef RESHADE_COLOR_SPACE_SRGB
#define RESHADE_COLOR_SPACE_SRGB        1
#endif
#ifndef RESHADE_COLOR_SPACE_SCRGB
#define RESHADE_COLOR_SPACE_SCRGB       2
#endif
#ifndef RESHADE_COLOR_SPACE_BT2020_PQ
#define RESHADE_COLOR_SPACE_BT2020_PQ   3
#endif

/*----------------.
| :: Functions :: |
'----------------*/

namespace GammaConvert
{
	// Convert display gamma for all vector types
	#if BUFFER_COLOR_SPACE==RESHADE_COLOR_SPACE_UNKNOWN || BUFFER_COLOR_SPACE==RESHADE_COLOR_SPACE_SRGB // transform from and to sRGB gamma in SDR (and fall back to it in the unknown color space case)
		// Sourced from International Color Consortium, at https://color.org/chardata/rgb/srgb.xalter
		#define _TO_DISPLAY_GAMMA(g) ((g)<=0.0031308?  (g)*12.92 : exp(log(g)/2.4)*1.055-0.055)
		#define _TO_LINEAR_GAMMA(g)  ((g)<=0.04049936? (g)/12.92 : exp(log((g+0.055)/1.055)*2.4))
	#elif BUFFER_COLOR_SPACE==RESHADE_COLOR_SPACE_BT2020_PQ // transform from and to HDR10 ST 2084
		#define _TO_DISPLAY_GAMMA(g) (exp(log(abs((0.8359375+18.8515625*exp(log(abs(g))*0.1593017578125))/(1f+18.6875*exp(log(abs(g))*0.1593017578125))))*78.84375))
		#define _TO_LINEAR_GAMMA(g)  (exp(log(abs(max(exp(log(abs(g))*32f/2523f)-0.8359375, 0f)/(18.8515625-18.6875*exp(log(abs(g))*32f/2523f))))*8192f/1305f))
	#else // bypass transform (e.g. BUFFER_COLOR_SPACE==RESHADE_COLOR_SPACE_SCRGB which is linear in/out)
		#define _TO_DISPLAY_GAMMA(g) (g)
		#define _TO_LINEAR_GAMMA(g)  (g)
	#endif
	// Gamma transform function: linear ↦ gammaRGB
	float  to_display(float  g) { return _TO_DISPLAY_GAMMA(g); }
	float2 to_display(float2 g) { return _TO_DISPLAY_GAMMA(g); }
	float3 to_display(float3 g) { return _TO_DISPLAY_GAMMA(g); }
	float4 to_display(float4 g) { return _TO_DISPLAY_GAMMA(g); }
	// Gamma transform function: gammaRGB ↦ linear
	float  to_linear( float  g) { return _TO_LINEAR_GAMMA(g); }
	float2 to_linear( float2 g) { return _TO_LINEAR_GAMMA(g); }
	float3 to_linear( float3 g) { return _TO_LINEAR_GAMMA(g); }
	float4 to_linear( float4 g) { return _TO_LINEAR_GAMMA(g); }
}
