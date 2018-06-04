/*
CrossHair PS v1.2.1 (c) 2018 Jacob Maximilian Fober

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

  ////////////////////
 /////// MENU ///////
////////////////////

uniform float Opacity <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
> = 1.0;

uniform int Coefficients <
	ui_label = "Crosshair contrast mode";
	ui_tooltip = "YUV coefficients. For digital connection (HDMI/DVI/DisplayPort) use 709. For analog (VGA) use 601";
	ui_type = "combo";
	ui_items = "BT.709\0BT.601\0";
> = 0;

uniform bool Stroke <
	ui_label = "Enable black stroke";
> = true;

uniform bool Fixed <
	ui_label = "Fixed position";
	ui_tooltip = "Crosshair will move with the mouse on OFF";
	ui_category = "Position";
> = true;

uniform int2 OffsetXY <
	ui_label = "Offset in Pixels";
	ui_tooltip = "Offset Crosshair position in pixels";
	ui_type = "drag";
	ui_min = -16; ui_max = 16;
	ui_category = "Position";
> = int2(0, 0);

  //////////////////////
 /////// SHADER ///////
//////////////////////

#include "ReShade.fxh"

// RGB to YUV709
static const float3x3 ToYUV709 =
float3x3(
	float3(0.2126, 0.7152, 0.0722),
	float3(-0.09991, -0.33609, 0.436),
	float3(0.615, -0.55861, -0.05639)
);
// RGB to YUV601
static const float3x3 ToYUV601 =
float3x3(
	float3(0.299, 0.587, 0.114),
	float3(-0.14713, -0.28886, 0.436),
	float3(0.615, -0.51499, -0.10001)
);
// YUV709 to RGB
static const float3x3 ToRGB709 =
float3x3(
	float3(1, 0, 1.28033),
	float3(1, -0.21482, -0.38059),
	float3(1, 2.12798, 0)
);
// YUV601 to RGB
static const float3x3 ToRGB601 =
float3x3(
	float3(1, 0, 1.13983),
	float3(1, -0.39465, -0.58060),
	float3(1, 2.03211, 0)
);

// Get mouse position
uniform float2 MousePoint < source = "mousepoint"; >;

// Define CrossHair texture
texture CrossHairTex < source = "crosshair.png"; > {Width = 17; Height = 17; Format = RG8;};
sampler CrossHairSampler { Texture = CrossHairTex; };

// Overlay blending mode
float Overlay(float LayerA, float LayerB)
{
	float MinA = min(LayerA, 0.5);
	float MinB = min(LayerB, 0.5);
	float MaxA = max(LayerA, 0.5);
	float MaxB = max(LayerB, 0.5);
	return 2 * (MinA * MinB + MaxA + MaxB - MaxA * MaxB) - 1.5;
}

// Draw CrossHair
void CrossHairPS(float4 vois : SV_Position, float2 texcoord : TexCoord, out float3 Display : SV_Target)
{
	// Sample display image
	Display = tex2D(ReShade::BackBuffer, texcoord).rgb;

	// CrossHair texture size
	int2 Size = tex2Dsize(CrossHairSampler, 0);

	bool YUV709 = (Coefficients == 0);

	float3 StrokeColor;
	float2 Pixel = ReShade::PixelSize;
	float2 Screen = ReShade::ScreenSize;
	float2 Offset = Pixel * float2(-OffsetXY.x, OffsetXY.y);
	float2 Position = Fixed ? float2(0.5, 0.5) : MousePoint / ReShade::ScreenSize;

	// Calculate CrossHair image coordinates relative to the center of the screen
	float2 CrossHairHalfSize = Size / Screen * 0.5;
	float2 texcoordCrossHair = (texcoord - Pixel * 0.5 + Offset - Position + CrossHairHalfSize) * Screen / Size;

	// Sample CrossHair image
	float2 CrossHair = tex2D(CrossHairSampler, texcoordCrossHair).rg;

	if (CrossHair.r != 0 || CrossHair.g != 0)
	{
		// Get behind-crosshair color
		float3 Color = tex2D(ReShade::BackBuffer, Position + Offset).rgb;

		// Convert to YUV
		Color = mul(YUV709 ? ToYUV709 : ToYUV601, Color);

		// Invert Luma with high-contrast gray
		Color.r = (Color.r > 0.75 || Color.r < 0.25) ? 1.0 - Color.r : Color.r > 0.5 ? 0.25 : 0.75;
		// Invert Chroma
		Color.gb *= -1.0;

		float StrokeValue = 1 - Color.r;

		// Convert YUV to RGB
		Color = mul(YUV709 ? ToRGB709: ToRGB601, Color);

		// Overlay blend stroke with background
		StrokeColor = float3(
			Overlay(Display.r, StrokeValue),
			Overlay(Display.g, StrokeValue),
			Overlay(Display.b, StrokeValue)
		);
		StrokeColor = lerp(Display, StrokeColor, 0.75); // 75% opacity

		// Color the stroke
		Color = lerp(StrokeColor, Color, CrossHair.r);
		// Opacity
		CrossHair *= Opacity;

		// Paint the crosshair
		Display = lerp(Display, Color, Stroke ? CrossHair.g : CrossHair.r);
	}
}


technique CrossHair
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = CrossHairPS;
	}
}
