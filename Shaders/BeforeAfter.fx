/*------------------.
| :: Description :: |
'-------------------/

Before-After PS (version 1.1.1)

Copyright:
This code © 2018-2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons
Attribution-ShareAlike 4.0 International License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/4.0/
*/

/*--------------.
| :: Commons :: |
'--------------*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

/*-----------.
| :: Menu :: |
'-----------*/

uniform bool Line = true;

uniform float Offset
<
	ui_type = "drag";
	ui_min = -1f; ui_max = 1f; ui_step = 0.001;
> = 0.5;

uniform float Blur
<
	ui_label = "Edge Blur";
	ui_type = "drag";
	ui_min = 0f; ui_max = 1f; ui_step = 0.001;
> = 0.0;

uniform float3 Color
< 	__UNIFORM_COLOR_FLOAT3
	ui_label = "Line color";
> = float3(0f, 0f, 0f);

/*---------------.
| :: Textures :: |
'---------------*/

// First pass render target
texture BeforeTarget
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;
};
sampler BeforeSampler
{
	Texture = BeforeTarget;
};

/*----------------.
| :: Functions :: |
'----------------*/

// Overlay blending mode
float Overlay(float LayerAB)
{
	float MinAB = min(LayerAB, 0.5);
	float MaxAB = max(LayerAB, 0.5);
	return 2f*(MinAB*MinAB+MaxAB+MaxAB-MaxAB*MaxAB)-1.5;
}

/*--------------.
| :: Shaders :: |
'--------------*/

void BeforePS(
	float4 vpos      : SV_Position,
	float2 UvCoord   : TEXCOORD,
	out float3 Image : SV_Target
)
{
	// Grab screen texture
	Image = tex2D(ReShade::BackBuffer, UvCoord).rgb;
}

void AfterPS(
	float4 vpos      : SV_Position,
	float2 UvCoord   : TEXCOORD,
	out float3 Image : SV_Target
)
{
	float Coordinates = Offset < 0f ? 1f-UvCoord.x : UvCoord.x;
	float AbsOffset = abs(Offset);
	// Separate Before/After
	if(Blur == 0f)
	{
		bool WhichOne = Coordinates > AbsOffset;
		Image = WhichOne ? tex2D(ReShade::BackBuffer, UvCoord).rgb : tex2D(BeforeSampler, UvCoord).rgb;
		if(Line) Image = Coordinates < AbsOffset-0.002 || Coordinates > AbsOffset+0.002 ? Image : Color;
	}
	else
	{
		// Mask
		float Mask = clamp((Coordinates-AbsOffset+0.5*Blur) / Blur, 0f, 1f);
		Image = lerp(tex2D(BeforeSampler, UvCoord).rgb, tex2D(ReShade::BackBuffer, UvCoord).rgb, Overlay(Mask));
	}
}

/*-------------.
| :: Output :: |
'-------------*/

technique Before
<
	ui_tooltip =
		"Place this technique before effects you want compare.\n"
		"Then move technique 'After'"
		"\n"
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-SA 4.0";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = BeforePS;
		RenderTarget = BeforeTarget;
	}
}

technique After
<
	ui_tooltip =
		"Place this technique after effects you want compare.\n"
		"Then move technique 'Before'"
		"\n"
		"This effect © 2018-2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-SA 4.0";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = AfterPS;
	}
}
