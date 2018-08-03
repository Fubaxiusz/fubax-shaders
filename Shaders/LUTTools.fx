/*
Display LUT PS v1.1.3 (c) 2018 Jacob Maximilian Fober;
Apply LUT PS v1.0.0 (c) 2018 Jacob Maximilian Fober,
(remix of LUT shader 1.0 (c) 2016 Marty McFly)

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

  ////////////////////
 /////// MENU ///////
////////////////////

// Define LUT texture size
#ifndef LutSize
	#define LutSize 32
#endif
// Define LUT texture name
#ifndef LutName
	#define LutName "lut.png"
#endif

#ifndef ShaderAnalyzer
uniform int LutRes <
	ui_label = "LUT box resolution";
	ui_tooltip = "Horizontal resolution equals value squared. Default 32 is 1024. To set texture size and name for ApplyLUT, define 'LutSize [number]' and 'LutName [name]'";
	ui_type = "drag";
	ui_category = "Display LUT settings";
	ui_min = 8; ui_max = 128; ui_step = 1;
> = 32;
uniform float2 LutLumaChroma <
	ui_label = "LUT luma/chroma blend";
	ui_tooltip = "How much LUT affects luminance/chrominance";
	ui_type = "drag";
	ui_category = "Apply LUT settings";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.005;
> = float2(1.0, 1.0);
#endif

  //////////////////////
 /////// SHADER ///////
//////////////////////

// LUT texture for Apply Lut PS
#ifndef ShaderAnalyzer
texture LUTTex < source = LutName; > {Width = LutSize * LutSize; Height = LutSize; Format = RGBA8;};
#endif
sampler LUTSampler {Texture = LUTTex; Format = RGBA8;};


#include "ReShade.fxh"

// Shader No.1 pass
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
	bool LUTMask = max(LUTSize.x, LUTSize.y);

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

// Shader No.2 pass
void ApplyLutPS(float4 vois : SV_Position, float2 TexCoord : TEXCOORD, out float3 Image : SV_Target)
{
	// Grab background color
	Image = tex2D(ReShade::BackBuffer, TexCoord).rgb;

	float2 LutPixelSize = 1.0 / int2(LutSize * LutSize, LutSize);

	float4 LutCoord;
	LutCoord.xyz = Image.xyz * LutSize - Image.xyz;
	LutCoord.xy = (LutCoord.xy + 0.5) * LutPixelSize;
	LutCoord.x += floor(LutCoord.z) * LutPixelSize.y;
	// Blue lerp scalar
	LutCoord.z = frac(LutCoord.z);
	// X' coordinate for blue lerp
	LutCoord.w = LutCoord.x + LutPixelSize.y;

	// LUT corrected image
	float3 LutImage = lerp(
		tex2D(LUTSampler, LutCoord.xy).rgb,
		tex2D(LUTSampler, LutCoord.wy).rgb,
		LutCoord.z
	);

	// Blend LUT image with original
	if (1 == min(LutLumaChroma.x, LutLumaChroma.y))
	{
		Image = LutImage;
	}
	else
	{
		Image = lerp(
			normalize(Image),
			normalize(LutImage),
			LutLumaChroma.x
		) * lerp(
			length(Image),
			length(LutImage),
			LutLumaChroma.y
		);
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

technique ApplyLUT
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ApplyLutPS;
	}
}
