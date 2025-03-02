/* >> Description << */

/* Curved Monitor PS (version 1.2.2)

Copyright:
This code © 2025 Jakub Maksymilian Fober

License:
This work is licensed under the Creative Commons Attribution-NoDerivs 3.0
Unported License. To view a copy of this license, visit:
http://creativecommons.org/licenses/by-nd/3.0/

Additional permissions under the Creative Commons Plus (CC+) protocol:

§ 1. Commercial Redistribution:
   - You may redistribute and include this effect in commercial shader or
     preset packs.
   - A 10% share of revenue from any commercial distribution must be paid
     to the copyright owner.

§ 2. Payment Terms:
   - Payments must be made weekly or monthly via PayPal:
     https://paypal.com/paypalme/fubax
   - Contact jakub.m.fober@protonmail.com for alternative payment
     arrangements.

§ 3. Compliance & Reporting:
   - Commercial users must maintain transparent records of revenue and
     payments.
   - Failure to comply with these terms may result in revocation of this
     license and legal action.

Important Notes:

- No Derivatives: Modifications, adaptations, or derivative works of this
  shader are NOT allowed under this license.
- Attribution Required: Any distribution must include credit to Jakub Fober,
  along with a link to the original work.
- Non-Compliance: If you do not agree to these terms, you CANNOT use this
  work in a commercial setting.

For further licensing inquiries, contact: jakub.m.fober@protonmail.com
*/

/* >> Macros << */

/* High quality sampling.
   0 disables mipmapping.
   1 gives level 2 mipmap.
   ...
   4 maximum mipmapping lvl, equivalent of x16 filtering. */
#ifndef MIPMAPPING_LEVEL
	#define MIPMAPPING_LEVEL 0
#endif

/* >> Commons << */

#include "ReShade.fxh"
#include "ReShadeUI.fxh"
#include "LinearGammaWorkflow.fxh"

/* >> Menu << */

uniform float MonitorHeight
<	__UNIFORM_SLIDER_FLOAT1
	ui_text = "> Match your monitor specs <";
	ui_category = "Monitor Parameters";
	ui_category_closed = true;
	ui_label = "Monitor height";
	ui_units = " cm";
	ui_tooltip = "Measure the height of the display image using tape measure or a ruler.";
	ui_min = 10f; ui_max = 100f; ui_step = 0.1;
> = 34f;

uniform uint MonitorCurvature
<	__UNIFORM_SLIDER_INT1
	ui_category = "Monitor Parameters";
	ui_units = "R";
	ui_label = "Monitor curvature";
	ui_tooltip = "Check manufacturer information for correct number.";
	ui_min = 800u; ui_max = 4000u; ui_step = 100u;
> = 1500u;

uniform uint ViewDistance
<	__UNIFORM_SLIDER_INT1
	ui_text = "\n> Gaming style <";
	ui_category = "Monitor Parameters";
	ui_units = " cm";
	ui_label = "Viewing distance";
	ui_tooltip = "Distance from the eye to the center of the monitor.";
	ui_min = 12u; ui_max = 150u; ui_step = 1u;
> = 70u;

// Border

uniform float BorderZoom
<	__UNIFORM_SLIDER_FLOAT1
	ui_category = "Border appearance";
	ui_category_closed = true;
	ui_label = "Border cropping";
	ui_units = "x";
	ui_tooltip = "This controls the cropping of the image.";
	ui_min = 0f; ui_max = 1f; ui_step = 0.01;
> = 1f;

uniform bool MirrorBorder
<	__UNIFORM_INPUT_BOOL1
	ui_text = "\n> Border cosmetics <";
	ui_category = "Border appearance";
	ui_label = "Mirror on border";
	ui_tooltip = "Choose mirrored or original image on the border.";
> = true;

uniform float4 BorderColor
<	__UNIFORM_COLOR_FLOAT4
	ui_category = "Border appearance";
	ui_label = "Border color";
	ui_tooltip = "Use alpha to change border transparency.";
> = float4(0.027, 0.027, 0.027, 0.96);

// Calibration Options

uniform bool CalibrationModeView
<	__UNIFORM_INPUT_BOOL1
	ui_category = "Calibration mode";
	ui_category_closed = true;
	nosave = true;
	ui_label = "Enable display calibration";
	ui_tooltip = "Display calibration grid for lens-matching.";
> = false;

uniform float GridSize
<	__UNIFORM_SLIDER_FLOAT1
	ui_text = "\n> Grid cosmetics <";
	ui_category = "Calibration mode";
	ui_units = " grid";
	ui_label = "Grid size";
	ui_tooltip = "Adjust calibration grid size.";
	ui_min = 2f; ui_max = 32f; ui_step = 0.01;
> = 16f;

uniform float GridWidth
<	__UNIFORM_SLIDER_FLOAT1
	ui_category = "Calibration mode";
	ui_units = " pixels";
	ui_label = "Grid width";
	ui_tooltip = "Adjust calibration grid bar width in pixels.";
	ui_min = 2f; ui_max = 16f; ui_step = 0.01;
> = 4f;

uniform float4 GridColor
<	__UNIFORM_COLOR_FLOAT4
	ui_category = "Calibration mode";
	ui_label = "Grid color";
	ui_tooltip = "Adjust calibration grid bar color.";
> = float4(1f, 1f, 0f, 1f);

uniform float BackgroundDim
<	__UNIFORM_SLIDER_FLOAT1
	ui_category = "Calibration mode";
	ui_label = "Background dimming";
	ui_tooltip = "Choose the calibration background dimming.";
	ui_min = 0f; ui_max = 1f; ui_step = 0.01;
> = 0.5;

/* >> Textures << */

#if MIPMAPPING_LEVEL
// Buffer texture target with mipmapping
texture2D BackBufferMipTarget_Tex
< pooled = true; >
{
	Width = BUFFER_WIDTH;
	Height = BUFFER_HEIGHT;

	// Storing linear gamma picture in higher bit depth
#if (BUFFER_COLOR_SPACE == RESHADE_COLOR_SPACE_SRGB) || (BUFFER_COLOR_SPACE == RESHADE_COLOR_SPACE_BT2020_PQ)
	Format = RGB10A2;
#else // BUFFER_COLOR_SPACE == RESHADE_COLOR_SPACE_SCRGB // Fall back on a higher quality in any other case, for future compatibility
	Format = RGBA16F;
#endif

	// Maximum MIP map level
	#if MIPMAPPING_LEVEL>0 && MIPMAPPING_LEVEL<=4
	MipLevels = MIPMAPPING_LEVEL+1;
	#else
	MipLevels = 5; // maximum MIP level
	#endif
};
#endif

// Define screen texture with mirror tiles and anisotropic filtering
sampler2D BackBuffer
{
#if MIPMAPPING_LEVEL
	Texture = BackBufferMipTarget_Tex; // back buffer texture target with additional MIP levels
#else
	Texture = ReShade::BackBufferTex; // back buffer texture target
#endif

	// Border style
	AddressU = MIRROR;
	AddressV = MIRROR;

	// Filtering
	MagFilter = ANISOTROPIC;
	MinFilter = ANISOTROPIC;
	MipFilter = ANISOTROPIC;
};

/* >> Functions << */

/* Linear pixel step function for anti-aliasing by Jakub Max Fober.
   This algorithm is part of scientific paper:
   · arXiv:2010.04077 [cs.GR] (2020) */
float aastep(float grad)
{
	// Differential vector
	float2 Del = float2(ddx(grad), ddy(grad));
	// Gradient normalization to pixel size, centered at the step edge
	return saturate(mad(rsqrt(dot(Del, Del)), grad, 0.5)); // half-pixel offset
}

// Generate lens-match grid
float3 GridModeViewPass(
	uint2  pixelCoord,
	float2 texCoord
)
{
	// Sample background without distortion
#if MIPMAPPING_LEVEL
	float3 display = tex2Dfetch(BackBuffer, pixelCoord).rgb;
#else // manual gamma linearization
	float3 display = GammaConvert::to_linear(tex2Dfetch(BackBuffer, pixelCoord).rgb);
#endif

	// Dim calibration background
	display *= clamp(1f-BackgroundDim, 0f, 1f);

	// Get view coordinates, normalized at the corner
	texCoord = (texCoord*2f-1f)*normalize(BUFFER_SCREEN_SIZE);

	// Get coordinates pixel size
	float2 delX = float2(ddx(texCoord.x), ddy(texCoord.x));
	float2 delY = float2(ddx(texCoord.y), ddy(texCoord.y));
	// Scale coordinates to grid size and center
	texCoord = frac(texCoord*GridSize)-0.5;
	/* Scale coordinates to pixel size for anti-aliasing of grid
	   using anti-aliasing step function from research paper
	   arXiv:2010.04077 [cs.GR] (2020) */
	texCoord *= float2(
		rsqrt(dot(delX, delX)),
		rsqrt(dot(delY, delY))
	)/GridSize; // pixel density
	// Set grid with
	texCoord = saturate(GridWidth*0.5-abs(texCoord)); // clamp values
	// Apply calibration grid colors
	display = lerp(
		GridColor.rgb,
		display,
		max((1f-texCoord.x)*(1f-texCoord.y), 1f-GridColor.a)
	);

	return display; // background picture with grid superimposed over it
}

// Generate flat projection from cylindrical view coordinates
float2 projectCylinderIncidence(float2 viewCoord)
{
	// Convert monitor height in centimeters to half in millimeters
	static const float halfHeight = MonitorHeight*5f;
	// Convert monitor X coordinates to arc angle in radians
	float cylinderAngle = viewCoord.x*halfHeight/MonitorCurvature;
	// Get incidence vector
	float3 incidence;
	incidence.x = sin(cylinderAngle)*MonitorCurvature;
	incidence.y = viewCoord.y*halfHeight;
	incidence.z = cos(cylinderAngle)*MonitorCurvature;
	// Offset by view position converted to millimeters
	incidence.z = incidence.z+(ViewDistance*10u)-MonitorCurvature;
	// Perform perspective projection
	viewCoord = incidence.xy/incidence.z;

	return viewCoord;
}

/* >> Shaders << */

#if MIPMAPPING_LEVEL
void BackBufferMipTarget_VS(
	in  uint   vertexId : SV_VertexID,
	out float4 position : SV_Position // no texture mapping
)
{
	// Generate vertex position for triangle ABC covering whole screen
	position.x = vertexId==2? 3f :-1f;
	position.y = vertexId==1?-3f : 1f;

	// Initialize other values
	position.z = 0f; // not used
	position.w = 1f; // not used
}

void BackBufferMipTarget_PS(
	in  float4 pos     : SV_Position,
	out float4 display : SV_Target
)
{
	// Generating MIP maps in linear gamma color space
	display.rgb = GammaConvert::to_linear(
		tex2Dfetch(
			ReShade::BackBuffer, // standard back-buffer
			uint2(pos.xy)        // pixel position without resampling
		).rgb
	);
	display.a = 1f;
}
#endif

// Vertex shader generating a triangle covering the entire screen
void CurvedMonitor_VS(
	in  uint   vertexId  : SV_VertexID,
	out float4 position  : SV_Position,
	out float2 texCoord  : TEXCOORD0,
	out float2 viewCoord : TEXCOORD1
)
{
	// Generate vertex position for triangle ABC covering whole screen
	position.x = vertexId==2? 3f :-1f;
	position.y = vertexId==1?-3f : 1f;
	// Initialize other values
	position.z = 0f; // not used
	position.w = 1f; // not used

	// Export screen centered texture coordinates
	texCoord.x = viewCoord.x =  position.x;
	texCoord.y = viewCoord.y = -position.y;
	// Map to corner and normalize texture coordinates
	texCoord = texCoord*0.5+0.5;
	// Correct aspect ratio, normalized to the height in [-1, 1] range
	viewCoord.x *= BUFFER_ASPECT_RATIO;
}

// Main perspective shader pass
void CurvedMonitor_PS(
	in  float4 pixelPos  : SV_Position,
	in  float2 texCoord  : TEXCOORD0,
	in  float2 viewCoord : TEXCOORD1,
	out float3 display   : SV_Target // output color
)
{
	// Project cylinder to perspective
	viewCoord = projectCylinderIncidence(viewCoord);
	// Get the normalization points
	static const float topNormalization = projectCylinderIncidence(
			float2(0f, 1f)
		).y*BUFFER_ASPECT_RATIO;
	static const float sideNormalization = projectCylinderIncidence(
			float2(BUFFER_ASPECT_RATIO, 0f)
		).x;
	// Normalize to the edge
	viewCoord /= lerp(topNormalization, sideNormalization, clamp(BorderZoom, 0f, 1f));
	// Convert to square aspect ratio
	texCoord.x = viewCoord.x;
	texCoord.y = viewCoord.y*BUFFER_ASPECT_RATIO;
	// Generate outside border mask
	float mask =
		aastep(1f-abs(texCoord.x))* // left-right edge
		aastep(1f-abs(texCoord.y)); // top-bottom edge

	// Map to corner
	texCoord = texCoord*0.5+0.5;

	if (CalibrationModeView) // draw curved calibration grid
		display = GridModeViewPass(uint2(pixelPos.xy), texCoord);
	else // correct curvature of the image
	{
		display = tex2Dgrad(BackBuffer, texCoord, ddx(texCoord), ddy(texCoord)).rgb;
#if !MIPMAPPING_LEVEL
		// Manually linearize gamma
		display = GammaConvert::to_linear(display);
#endif
	}
	// Convert border color to linear RGB
	static const float4 BorderLinearColor = GammaConvert::to_linear(BorderColor);
	// Apply border mask
	if (MirrorBorder) // blend border color with texture mirror sampling
		display = lerp(
			BorderLinearColor.rgb,
			display,
			max(mask, 1f-BorderLinearColor.a)
		);
	else // sample original background at the border and blend with color
	{
		display = lerp(
			lerp(
				GammaConvert::to_linear(tex2Dfetch(ReShade::BackBuffer, uint2(pixelPos.xy)).rgb),
				BorderLinearColor.rgb,
				BorderLinearColor.a
			),
			display,
			mask
		);
	}
	// Manually correct gamma for the final output
	display = GammaConvert::to_display(display);
}

/* >> Output << */

technique CurvedMonitor
<
	ui_label = "Curved Monitor (Ultrawide)";
	ui_tooltip =
		"Adjust picture for distortion-free experience on a curved\n"
		"ultra-wide display.\n"
		"\n"
		"\n"
		"Instruction:\n"
		"\n"
		"	1. Select proper curvature R and height, matching\n"
		"	   your display specs.\n"
		"\n"
		"	2. Adjust viewing distance according to your position.\n"
		"\n"
		"	 + use '4lex4nder/ReshadeEffectShaderToggler' add-on, to\n"
		"	   undistort the UI (user interface).\n"
		"\n"
		"	 + use sharpening, or run the game at Super-Resolution.\n"
		"\n"
		"	 + for best quality set MIPMAPPING_LEVEL to 1 or 2.\n"
		"\n"
		"\n"
		"Some elements of the effect are a part of a scientific article:\n"
		"	arXiv:2010.04077 [cs.GR] (2020)\n"
		"\n"
		"This effect © 2025 Jakub Maksymilian Fober\n"
		"Licensed under CC+ BY-ND 3.0\n"
		"Commercial use, like shader packs on Patreon requires a 10% revenue share.\n"
		"For details, see the source code header: [Right-click] > 'Edit source code'";
>
{
#if MIPMAPPING_LEVEL
	pass CreateMipMaps
	{
		VertexShader = BackBufferMipTarget_VS;
		PixelShader  = BackBufferMipTarget_PS;
		RenderTarget = BackBufferMipTarget_Tex;
	}
#endif
	pass CurveDistortion
	{
		VertexShader = CurvedMonitor_VS;
		PixelShader  = CurvedMonitor_PS;
	}
}
