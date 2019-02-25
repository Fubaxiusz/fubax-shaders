/*
MatCap PS (c) 2019 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-NonCommercial-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-nc-sa/4.0/

For inquiries please contact jakubfober@gmail.com
*/

/*
Depth Map sampler is from ReShade.fxh by Crosire.
Normal Map generator is from DisplayDepth.fx by CeeJay.
*/

// version 0.2.0

  ////////////////////
 /////// MENU ///////
////////////////////

#ifndef MATCAP
	#define MATCAP 512
#endif

uniform float FarPlane <
	ui_label = "Far Plane adjustment";
	ui_tooltip = "Adjust Normal Map strength";
	#if __RESHADE__ < 40000
		ui_type = "drag";
	#else
		ui_type = "slider";
	#endif
	ui_min = 0.0; ui_max = 1000.0; ui_step = 1.0;
> = 1000.0;


  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

texture MatcapTex < source = "matcap.png"; > {Width = MATCAP; Height = MATCAP;};
sampler MatcapSampler
{
	Texture = MatcapTex;
	AddressU = BORDER;
	AddressV = BORDER;
	Format = RGBA8;
};

// Get depth function from ReShade.fxh with custom Far Plane
float GetDepth(float2 TexCoord)
{
	#if RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN
		TexCoord.y = 1.0 - TexCoord.y;
	#endif
	float Depth = tex2Dlod( ReShade::DepthBuffer, float4(TexCoord, 0, 0) ).x;
	
	#if RESHADE_DEPTH_INPUT_IS_LOGARITHMIC
		const float C = 0.01;
		Depth = (exp(Depth * log(C + 1.0)) - 1.0) / C;
	#endif
	#if RESHADE_DEPTH_INPUT_IS_REVERSED
		Depth = 1.0 - Depth;
	#endif

	const float N = 1.0;
	Depth /= FarPlane - Depth * (FarPlane - N);

	return Depth;
}

// Normal map generator from DisplayDepth.fx
float3 NormalVector(float2 texcoord)
{
	float3 offset = float3(ReShade::PixelSize.xy, 0.0);
	float2 posCenter = texcoord.xy;
	float2 posNorth  = posCenter - offset.zy;
	float2 posEast   = posCenter + offset.xz;

	float3 vertCenter = float3(posCenter, 1) * GetDepth(posCenter);
	float3 vertNorth  = float3(posNorth,  1) * GetDepth(posNorth);
	float3 vertEast   = float3(posEast,   1) * GetDepth(posEast);

	return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}

// Sample Matcap texture
float4 GetMatcap(float2 TexCoord)
{
	// Get aspect ratio
	float Aspect = ReShade::AspectRatio;

	// Sample display image (for use with DisplayDepth.fx)
	float3 Normal = NormalVector(TexCoord);
	Normal.xy = Normal.xy * 2.0 - 1.0;
	Normal = normalize(Normal);

	float2 MatcapCoord = Normal.xy * 0.5 + 0.5;
	MatcapCoord.y = 1.0 - MatcapCoord.y;

	// Sample matcap texture
	float4 MatcapTexture = tex2D(MatcapSampler, MatcapCoord);

	return MatcapTexture;
}

float3 MatcapPS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	float3 Display = tex2D(ReShade::BackBuffer, texcoord).rgb;
	float4 MatCapSampled = GetMatcap(texcoord);

	return lerp(Display, MatCapSampled.rgb, MatCapSampled.a);
}

technique MatCap
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = MatcapPS;
	}
}
