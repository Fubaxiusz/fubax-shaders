/*
Cursor PS (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

// version 1.0.1

  ////////////////////
 /////// MENU ///////
////////////////////

uniform float3 Color <
	ui_type = "color";
> = float3(0.871, 0.871, 0.871);

uniform float Scale <
	#if __RESHADE__ < 40000
		ui_type = "drag";
	#else
		ui_type = "slider";
	#endif
	ui_min = 0.1; ui_max = 1.0; ui_step = 0.001;
> = 0.2;

  //////////////////////
 /////// SHADER ///////
//////////////////////

// Get mouse position
uniform float2 MousePoint < source = "mousepoint"; >;

texture CursorTex < source = "cursor.png"; > {Width = 108; Height = 108;};
sampler CursorSampler
{
	Texture = CursorTex;
	AddressU = BORDER;
	AddressV = BORDER;
	Format = R8;
};

#include "ReShade.fxh"

float3 CursorPS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Get mouse position in UV space
	float2 Cursor = MousePoint / ReShade::ScreenSize;
	// Calculate Cursor size
	float2 CursorSize = ReShade::ScreenSize / float2(tex2Dsize(CursorSampler, 0)) / Scale;
	// Get pixel UV size
	float2 Pixel = ReShade::PixelSize;

	// Sample display image
	float3 Display = tex2D(ReShade::BackBuffer, texcoord).rgb;
	// Sample cursor texture
	float CursorTexture = tex2D(CursorSampler, (texcoord - Cursor) * CursorSize).r;

	return lerp(Display, Color, CursorTexture);
}

technique Cursor
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CursorPS;
	}
}
