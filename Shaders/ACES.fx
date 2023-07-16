/*------------------.
| :: Description :: |
'-------------------/

ACES Tone Mapping PS (version 1.0.3)

Copyright:
This code © 2023 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons,
Attribution-ShareAlike 3.0 Unported License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/3.0/

About:
The matrices and ACES mapping where sourced from ChatGPT-4,
which it took from OpenColorIO documentation.
*/

/*--------------.
| :: Commons :: |
'--------------*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "LinearGammaWorkflow.fxh"
#include "BlueNoiseDither.fxh"

/*-----------.
| :: Menu :: |
'-----------*/

uniform float Exposure
<	__UNIFORM_SLIDER_FLOAT1
	ui_tooltip = "Increase exposure of the image.";
	ui_min = 1f; ui_max = 10f;
	ui_step = 0.01;
> = 3.82;

uniform float DryWet
<	__UNIFORM_SLIDER_FLOAT1
	ui_text = "Final mix";
	ui_label = "Dry/Wet blending";
	ui_tooltip = "Blend between original color and the ACES tone mapping.";
	ui_step = 0.01;
> = 0.75;

/*----------------.
| :: Constants :: |
'----------------*/

// Linear RGB to ACES2065-1 conversion matrix
static const float3x3 ACESInputMat =
	float3x3(
		0.4397010, 0.3829780, 0.1773350,
		0.0897923, 0.8134230, 0.0967616,
		0.0175440, 0.1115440, 0.8707040
	);

// ACES2065-1 to linear RGB conversion matrix
static const float3x3 ACESOutputMat =
	float3x3(
		1.60475, -0.53108, -0.07367,
	   -0.10208,  1.10813, -0.00605,
	   -0.00327, -0.07276,  1.07602
	);

/*----------------.
| :: Functions :: |
'----------------*/

// Function to apply RRT and ODT
float3 RRTAndODTFit(float3 color)
{
	return (color*(color+0.0245786)-0.000090537)/
		   (color*(color*0.983729+0.4329510)+0.238081);
}

/*--------------.
| :: Shaders :: |
'--------------*/

// Vertex shader generating a triangle covering the entire screen
void ACESToneMapping_VS(
	in  uint   vertexId  : SV_VertexID,
	out float4 vertexPos : SV_Position
)
{
	// Define vertex position
	const float2 vertexPosList[3] =
	{
		float2(-1f, 1f), // Top left
		float2(-1f,-3f), // Bottom left
		float2( 3f, 1f)  // Top right
	};
	// Export  vertex position,
	vertexPos.xy = vertexPosList[vertexId];
	vertexPos.zw = float2(0f, 1f); // Export vertex position
}

// Horizontal luminosity blur pass
void ACESToneMapping_PS(
	in  float4 pixCoord : SV_Position,
	out float3 color    : SV_Target
)
{
	// Get current pixel coordinates
	uint2 texelPos = uint2(pixCoord.xy);

	// Get current pixel color value
	float3 oryginalColor = tex2Dfetch(ReShade::BackBuffer, texelPos).rgb;

	// Convert to linear RGB value and apply exposure
	color = GammaConvert::to_linear(oryginalColor)*Exposure;

	// Convert to to ACES2065-1 color space
	color = mul(ACESInputMat, color);
	// Apply ACES RRT and ODT
	color = RRTAndODTFit(color);
	// Convert from ACES2065-1 to linear RGB
	color = mul(ACESOutputMat, color);

	// Apply sRGB gamma and clamp
	color = clamp(GammaConvert::to_display(color), 0f, 1f);

	// Dry/Wet blending
	color = lerp(oryginalColor, color, DryWet);

	// Apply color dither
	color = BlueNoise::dither(texelPos, color);
}

/*-------------.
| :: Output :: |
'-------------*/

technique ACESToneMapping
<
	ui_label = "ACES Tone Mapping";
	ui_tooltip =
		"ACES Tone Mapping curve effect\n"
		"\n"
		"This effect © 2023 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-SA 3.0";
>
{
	pass
	{
		VertexShader = ACESToneMapping_VS;
		PixelShader  = ACESToneMapping_PS;
	}
}
