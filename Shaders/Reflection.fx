/*
Reflection PS (c) 2019 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-NonCommercial-NoDerivatives 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-nc-nd/4.0/ 

For inquiries please contact jakubfober@gmail.com
*/

/*
This shader maps reflection vector of a normal surface
from a camera onto reflection texture in equisolid
360 degrees projection (mirror ball)

If you want to create reflection texture from
equirectangular 360 panorama, visit following:
https://github.com/Fubaxiusz
It's a shader script for Shadron image-editing software,
avaiable here:
https://www.arteryengine.com/shadron/
*/

/*
Depth Map sampler is from ReShade.fxh by Crosire.
Normal Map generator is from DisplayDepth.fx by CeeJay.
*/

// version 0.1.5

  ////////////////////
 /////// MENU ///////
////////////////////

#ifndef REFLECTION
	#define REFLECTION 768
#endif
#ifndef ReflectionImage
	#define ReflectionImage "reflection.png"
#endif

uniform int FOV <
	ui_label = "Field of View (horizontal)";
	#if __RESHADE__ < 40000
		ui_type = "drag";
	#else
		ui_type = "slider";
	#endif
	ui_min = 1; ui_max = 170;
> = 60;

uniform float FarPlane <
	ui_label = "Far Plane adjustment";
	ui_tooltip = "Adjust Normal Map strength";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1000.0; ui_step = 0.2;
> = 1000.0;


  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

texture ReflectionTex < source = ReflectionImage; > {Width = REFLECTION; Height = REFLECTION;};
sampler ReflectionSampler
{
	Texture = ReflectionTex;
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

	float3 vertCenter = float3(posCenter - 0.5, 1) * GetDepth(posCenter);
	float3 vertNorth  = float3(posNorth - 0.5,  1) * GetDepth(posNorth);
	float3 vertEast   = float3(posEast - 0.5,   1) * GetDepth(posEast);

	return normalize(cross(vertCenter - vertNorth, vertCenter - vertEast)) * 0.5 + 0.5;
}

// Sample Matcap texture
float4 GetReflection(float2 TexCoord)
{
	// Get aspect ratio
	float Aspect = ReShade::AspectRatio;

	// Sample display image (for use with DisplayDepth.fx)
	float3 Normal = NormalVector(TexCoord);
	Normal.xy = Normal.xy * 2.0 - 1.0;
//	Normal = normalize(Normal);

	// Get ray vector from camera to the visible geometry
	float3 CameraRay;
	CameraRay.xy = TexCoord * 2.0 - 1.0;
	CameraRay.y /= Aspect; // Correct aspect ratio
	CameraRay.z = 1.0 / tan(radians(FOV*0.5)); // Scale frustum Z position from FOV

	// Get reflection vector from camera to geometry surface
	float3 OnSphereCoord = normalize( reflect(CameraRay, Normal) );

	// Convert cartesian coordinates to equisolid polar
	float2 EquisolidPolar, EquisolidCoord;
	EquisolidPolar.x = length( OnSphereCoord + float3(0.0, 0.0, 1.0) ) * 0.5;
	EquisolidPolar.y = atan2(OnSphereCoord.y, OnSphereCoord.x);
	// Convert polar to UV coordinates
	EquisolidCoord.x = EquisolidPolar.x * cos(EquisolidPolar.y);
	EquisolidCoord.y = EquisolidPolar.x * sin(EquisolidPolar.y);
	EquisolidCoord = EquisolidCoord * 0.5 + 0.5;

	// Mirror texture
	EquisolidCoord.x = 1.0 - EquisolidCoord.x;

	// Sample matcap texture
	float4 ReflectionTexture = tex2D(ReflectionSampler, EquisolidCoord);

	return ReflectionTexture;
}

float3 ReflectionPS(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	return GetReflection(texcoord).rgb;
}

technique Reflection
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ReflectionPS;
	}
}
