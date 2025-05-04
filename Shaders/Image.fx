/*------------------.
| :: Description :: |
'-------------------/

Display Image PS (version 1.2.7)

Copyright:
This code © 2019-2025 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons
Attribution-ShareAlike 4.0 International License.
To view a copy of this license, visit
http://creativecommons.org/licenses/by-sa/4.0/
*/

/*-------------.
| :: Macros :: |
'-------------*/

// Image file name
#ifndef TEST_IMAGE_PATH
	#define TEST_IMAGE_PATH "TestPattern.png"
#endif
// Image horizontal resolution
#ifndef TEST_IMAGE_SIZE_X
	#define TEST_IMAGE_SIZE_X 1920
#endif
// Image vertical resolution
#ifndef TEST_IMAGE_SIZE_Y
	#define TEST_IMAGE_SIZE_Y 1080
#endif

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

uniform bool AspectCorrect
<	__UNIFORM_INPUT_BOOL1
	ui_label = "Original aspect ratio";
> = true;

uniform bool FillImage
<	__UNIFORM_INPUT_BOOL1
	ui_label = "Fill image";
> = false;

uniform float DimBackground
<	__UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 1f; ui_step = 0.01;
	ui_label = "Dim background image";
> = 1f;

/*----------------.
| :: Functions :: |
'----------------*/

// Emulate bitwise XOR '^' for compatibility with older APi
bool xor(bool a, bool b)
{ return (a||b)-(a&&b); }

/*---------------.
| :: Textures :: |
'---------------*/

// Define image texture
texture TestImageTex
< source = TEST_IMAGE_PATH; >
{
	Width  = TEST_IMAGE_SIZE_X;
	Height = TEST_IMAGE_SIZE_Y;
};
sampler TestImageSampler
{
	Texture = TestImageTex;
	SRGBTexture = true;
};

// Linear pixel step function for anti-aliasing by Jakub Max Fober
float Border(float2 coord)
{
	// Get pixel size
	float2 del = float2(ddx(coord.x), ddy(coord.y));
	// Convert to centered coordinates
	coord = 0.5-abs(coord-0.5);
	// Scale to pixel size and clamp values
	coord = saturate(coord/del);
	// Combine masks
	return min(coord.x, coord.y);
}

/*--------------.
| :: Shaders :: |
'--------------*/

// Draw Image
void ImagePS(
	float4 pixelPos  : SV_Position,
	float2 texCoord  : TEXCOORD,
	out float3 color : SV_Target
)
{
	color = tex2Dfetch(ReShade::BackBuffer, uint2(pixelPos.xy)).rgb;
	color = GammaConvert::to_linear(color); // linear workflow
	color *= DimBackground;

	if (!AspectCorrect) // bypass aspect ratio correction
	{
		float4 TestImageTex = tex2D(TestImageSampler, texCoord);
		color = lerp(color, TestImageTex.rgb, TestImageTex.a);
	}
	else // correct aspect ratio
	{
		// Gate test image aspect ratio
		float ImageAspect = float(TEST_IMAGE_SIZE_X)/float(TEST_IMAGE_SIZE_Y);
		// Test image aspect ratio
		if (ReShade::AspectRatio == ImageAspect) // Same aspect ratio
		{
			float4 TestImageTex = tex2D(TestImageSampler, texCoord);
			color = lerp(color, TestImageTex.rgb, TestImageTex.a);
		}
		else
		{
			if (xor(ReShade::AspectRatio > ImageAspect, FillImage)) // Image is narrower
				texCoord.x = (texCoord.x-0.5)*ReShade::AspectRatio/ImageAspect+0.5;
			else // Image is wider
				texCoord.y = (texCoord.y-0.5)*ImageAspect/ReShade::AspectRatio+0.5;
			// Sample test image
			float4 TestImageTex = tex2D(TestImageSampler, texCoord);
			// Blend image
			color = lerp(
				color,
				TestImageTex.rgb,
				min(Border(texCoord), TestImageTex.a)
			);
		}
	}

	color = GammaConvert::to_display(color);
	color = BlueNoise::dither(color, uint2(pixelPos.xy)); // Dither
}

	/* OUTPUT */

technique Image
<
	ui_tooltip =
		"Display image for testing.\n"
		"\n"
		"Source image can be changed with\n"
		"following preprocessor definitions:\n"
		"\n"
		"  TEST_IMAGE_PATH 'image.png'\n"
		"  TEST_IMAGE_SIZE_X 1440\n"
		"  TEST_IMAGE_SIZE_Y 1080\n"
		"\n"
		"This effect © 2019-2025 Jakub Maksymilian Fober\n"
		"Licensed under CC BY-SA 4.0";
>
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = ImagePS;
	}
}
