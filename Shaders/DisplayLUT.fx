/*
Display LUT PS v1.1.2 (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

  ////////////////////
 /////// MENU ///////
////////////////////

#ifndef ShaderAnalyzer
uniform int LutRes <
	ui_label = "LUT box resolution";
	ui_tooltip = "Horizontal resolution equals value squared. Default 32 is 1024";
	ui_type = "drag";
	ui_min = 8; ui_max = 128; ui_step = 1;
> = 32;
#endif

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

// Shader pass
float3 DisplayLutPS(float4 vois : SV_Position, float2 TexCoord : TEXCOORD) : SV_Target
{
	// Get UV pixel size
	float2 PixelSize = ReShade::PixelSize;
	// Get image resolution
	int2 ScreenResolution = ReShade::ScreenSize;

	// Calculate LUT texture bounds
	float2 LUTSize = PixelSize * int2(LutRes * LutRes, LutRes);
	LUTSize = floor(TexCoord / LUTSize);
	// Create background mask
	bool LUTMask = bool(LUTSize.x) || bool(LUTSize.y);

	if (LUTMask)
	{
		return tex2D(ReShade::BackBuffer, TexCoord).rgb;
	}
	else
	{
		// Generate pattern UV
		float2 Gradient = TexCoord * ScreenResolution / LutRes;
		// Convert pattern to RGB LUT
		float3 LUT;
		LUT.rg = frac(Gradient) - 0.5 / LutRes;
		LUT.rg /= 1.0 - 1.0 / LutRes;
		LUT.b = floor(Gradient.r) / (LutRes - 1);
		// Display LUT texture
		return LUT;
	}
}

technique DisplayLUT
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = DisplayLutPS;
	}
}
