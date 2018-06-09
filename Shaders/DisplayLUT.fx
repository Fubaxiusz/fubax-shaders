/*
Display LUT PS v1.0.0 (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

#include "ReShade.fxh"

// Shader pass
float3 DisplayLutPS(float4 vois : SV_Position, float2 TexCoord : TEXCOORD) : SV_Target
{
	// Get UV pixel size
	float2 PixelSize = ReShade::PixelSize;
	// Get image resolution
	float2 ScreenResolution = ReShade::ScreenSize;
	// Generate pattern UV
	float2 Gradient = TexCoord * ScreenResolution * 0.03125;
	// Convert pattern to RGB LUT
	float3 LUT;
	LUT.rg = frac(Gradient);
	LUT.b = floor(Gradient.r) / 31;
	// Display 1024x32 LUT
	return TexCoord < PixelSize * int2(1024, 32) ? LUT : tex2D(ReShade::BackBuffer, TexCoord).rgb;
}

technique DisplayLUT
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DisplayLutPS;
	}
}
