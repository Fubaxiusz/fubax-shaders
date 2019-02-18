/*
/// VR shader ///

Make any game VR and any screen with lenses a VR headset.
Thanks to this shader you'll be able to correct distortions of any lens types
(DIY, experimental) and chromatic aberration.
Also if a game outputs depth pass you can have a stereo-3D vision thanks to
the parallax mapping (which needs some further improvement).

Copyright (c) 2019 Jacob Max Fober

This work is licensed under the Creative Commons 
Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-nc-sa/4.0/

If you want to use it commercially, contact me at jakubfober@gmail.com
If you have questions, visit https://reshade.me/forum/shader-discussion/

I'm author of most of equations present here,
beside Brown-Conrady distortion correction model and
Parallax Steep and Occlusion mapping which
I changed and adopted from various sources.

Version 0.2.0 alpha
*/

#include "ReShade.fxh"



	////////////
	/// MENU ///
	////////////

#ifndef MaximumParallaxSteps
	#define MaximumParallaxSteps 128 // Defefine max steps to make loop finite
#endif
// Grid settings
#ifndef BoxAmount
	#define BoxAmount 31 // Number of boxes horizontally (choose odd number)
#endif
#ifndef thicknessA
	#define thicknessA 0.25 // White grid thickness
#endif
#ifndef thicknessB
	#define thicknessB 0.125 // Yellow cross thickness
#endif
#ifndef crossColor
	#define crossColor float3(1.0, 1.0, 0.0) // Center cross color (yellow)
#endif


#ifndef ShaderAnalyzer

//Depth Buffer Adjust//
uniform int Depth_Map <
	ui_type = "combo";
	ui_items = "Z-Buffer Normal\0Z-Buffer Reversed\0";
	ui_label = "·Z-Buffer Selection·";
	ui_tooltip = "Select Depth Buffer Linearization.";
	ui_category = "Depth Buffer Adjust";
> = 0;

uniform float Depth_Map_Adjust <
	ui_type = "drag";
	ui_min = 1.0; ui_max = 250.0; ui_step = 0.125;
	ui_label = " Z-Buffer Adjustment";
	ui_tooltip = "This allows for you to adjust Depth Buffer Precision.\n"
				 "Try to adjust this to keep it as low as possible.\n"
				 "Don't go too high with this adjustment.\n"
				 "Default is 7.5";
	ui_category = "Depth Buffer Adjust";
> = 7.5;

uniform float zOffset <
	ui_type = "drag";
	ui_min = 0; ui_max = 1.0;
	ui_label = " Z-Buffer Offset";
	ui_tooltip = "Depth Buffer Offset is for non conforming Z-Buffer.\n"
				 "It's rare if you need to use this in any game.\n"
				 "This makes adjustments to Normal and Reversed.\n"
				 "Default is Zero & Zero is Off.";
	ui_category = "Depth Buffer Adjust";
> = 0.0;

uniform float Convergence <
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.125;
	ui_label = " Convergence";
	ui_tooltip = "Convergence controls the focus distance for the screen Pop-out effect also known as ZPD.\n"
				 "For FPS Games keeps this low Since you don't want your gun to pop out of screen.\n"
				 "If you want to push this higher you need to adjust your Weapon Hand below.\n"
				 "It helps to keep this around 0.03 when adjusting the DM or Weapon Hand.\n"
				 "Default is 0.010, Zero is off.";
	ui_category = "Depth Buffer Adjust";
> = 0.010;

uniform bool Depth_Map_Flip <
	ui_label = " Flip Depth";
	ui_tooltip = "Flip the Depth Buffer if it is upside down.";
	ui_category = "Depth Buffer Adjust";
> = false;

uniform bool TestGrid <
	ui_label = "Display calibration grid";
	ui_tooltip = "Toggle test grid for lens calibration";
	ui_category = "Calibration grid";
> = true;

uniform bool Horizontal <
	ui_label = "Horizontal grid lines visible";
	ui_tooltip = "Only visible in grid mode";
	ui_category = "Calibration grid";
> = true;

uniform bool Vertical <
	ui_label = "Vertical grid lines visible";
	ui_tooltip = "Only visible in grid mode";
	ui_category = "Calibration grid";
> = true;

uniform bool RadialPattern <
	ui_label = "Switch to radial pattern";
	ui_tooltip = "Toggle test pattern for chromatic aberration";
		ui_category = "Calibration grid";
> = false;

uniform float IPD <
	ui_label = "IPD (interpupillary distance)";
	ui_tooltip = "Adjust lens center relative to the screen size";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 0.75; ui_step = 0.001;
	ui_category = "Stereo-vision adjustment";
> = 0.477;

uniform bool StereoSwitch <
	ui_label = "Stereoscopic view enabled";
	ui_tooltip = "Toggle stereo vision";
	ui_category = "Stereo-vision adjustment";
> = true;

uniform float ParallaxOffset <
	ui_label = "Parallax horizontal offset (disparity)";
	ui_tooltip = "Adjust 3D effect power\n(disparity in screen percent)";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_category = "Parallax 3D effect";
> = 0.355;

uniform float ParallaxCenter <
	ui_label = "Parallax rotation center (ZPD)";
	ui_tooltip = "Adjust 3D effect middle point\n(zero parallax distance)";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0; ui_step = 0.001;
	ui_category = "Parallax 3D effect";
> = 1.0;

uniform int ParallaxSteps <
	ui_label = "Parallax sampling steps";
	ui_tooltip = "Adjust 3D effect quality\n(higher numbers may decrease performance)";
	ui_type = "drag";
	ui_min = 1; ui_max = 128; ui_step = 0.2;
	ui_category = "Parallax 3D effect";
> = 16;

uniform int ParallaxMaskScalar <
	ui_label = "Parallax gaps compensation";
	ui_tooltip = "Adjust gaps from parallax offset\n(some glithes may occur due to lack of\nanti-aliasing in the depth pass)";
	ui_type = "drag";
	ui_min = 0; ui_max = 32; ui_step = 0.2;
	ui_category = "Parallax 3D effect";
> = 10;

uniform bool ParallaxSwitch <
	ui_label = "Parallax enabled";
	ui_tooltip = "Toggle parallax 3D effect\n(disable MSAA if parallax does not work)";
	ui_category = "Parallax 3D effect";
> = true;

uniform int FOV <
	ui_label = "Lens distortion power";
	ui_tooltip = "Adjust lens distortion main profile (vertical FOV)";
	ui_type = "drag";
	ui_min = 0; ui_max = 170; ui_step = 0.1;
	ui_category = "Perspective distortion";
> = 96;

uniform int LensType <
	ui_label = "Type of lens distortion";
	ui_tooltip = "Adjust lens distortion profile type";
	ui_type = "combo";
	ui_items = "Orthographic\0Equisolid\0Equidistant\0Stereographic\0";
	ui_category = "Perspective distortion";
> = 0;

uniform float4 K <
	ui_label = "Radial correction";
	ui_tooltip = "Adjust lens radial distortion K\n(Brown-Conrady model)\n[K1,K2,K3,K4]";
	ui_type = "drag";
	ui_step = 0.01;
	ui_category = "Perspective distortion";
> = float4(0.0, 0.0, 0.0, 0.0);

uniform float3 P <
	ui_label = "Tangental correction";
	ui_tooltip = "Adjust lens tangental distortion P\n(Brown-Conrady model)\n[P1,P2,P3]";
	ui_type = "drag";
	ui_step = 0.001;
	ui_category = "Perspective distortion";
> = float3(0.0, 0.0, 0.0);

uniform bool PerspectiveSwitch <
	ui_label = "Lens correction enabled";
	ui_tooltip = "Toggle lens distortion correction";
	ui_category = "Perspective distortion";
> = true;

uniform float2 ChGreenOffsetL <
	ui_label = "Left green center offset";
	ui_tooltip = "Adjust lens center for chromatic aberration";
	ui_type = "drag";
	ui_min = -0.2; ui_max = 0.2; ui_step = 0.001;
	ui_category = "Chromatic left-eye center";
> = float2(0.0, 0.0);

uniform float2 ChBlueOffsetL <
	ui_label = "Left blue center offset";
	ui_tooltip = "Adjust lens center for chromatic aberration";
	ui_type = "drag";
	ui_min = -0.2; ui_max = 0.2; ui_step = 0.001;
	ui_category = "Chromatic left-eye center";
> = float2(0.0, 0.0);

uniform float2 ChGreenOffsetR <
	ui_label = "Right green center offset";
	ui_tooltip = "Adjust lens center for chromatic aberration";
	ui_type = "drag";
	ui_min = -0.2; ui_max = 0.2; ui_step = 0.001;
	ui_category = "Chromatic right-eye center";
> = float2(0.0, 0.0);

uniform float2 ChBlueOffsetR <
	ui_label = "Right blue center offset";
	ui_tooltip = "Adjust lens center for chromatic aberration";
	ui_type = "drag";
	ui_min = -0.2; ui_max = 0.2; ui_step = 0.001;
	ui_category = "Chromatic right-eye center";
> = float2(0.0, 0.0);

uniform float4 ChGreenK <
	ui_label = "Chromatic green correction";
	ui_tooltip = "Adjust lens color fringing K\nfor green channel\n(Brown-Conrady model)\n[Zoom,K1,K2,K3]";
	ui_type = "drag";
	ui_step = 0.001;
	ui_category = "Chromatic radial correction";
> = float4(0.0, 0.0, 0.0, 0.0);

uniform bool SoloGreen <
	ui_label = "Green channel adjustment solo";
	ui_tooltip = "Visible only on calibration grid preview";
	ui_category = "Chromatic radial correction";
> = false;

uniform float4 ChBlueK <
	ui_label = "Chromatic blue correction";
	ui_tooltip = "Adjust lens color fringing K\nfor blue channel\n(Brown-Conrady model)\n[Zoom,K1,K2,K3]";
	ui_type = "drag";
	ui_step = 0.001;
	ui_category = "Chromatic radial correction";
> = float4(0.0, 0.0, 0.0, 0.0);

uniform bool SoloBlue <
	ui_label = "Blue channel adjustment solo";
	ui_tooltip = "Visible only on calibration grid preview";
	ui_category = "Chromatic radial correction";
> = false;

uniform bool ChromaticAbrSwitch <
	ui_label = "Chromatic correction enabled";
	ui_tooltip = "Toggle color fringing correction";
	ui_category = "Chromatic radial correction";
> = true;

uniform float Strength <
	ui_label = "Sharpen strength";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 100.0; ui_step = 0.01;
	ui_category = "Sharpen image";
> = 25.0;

uniform float Clamp <
	ui_label = "Sharpen clamping";
	ui_type = "drag";
	ui_min = 0.5; ui_max = 1.0; ui_step = 0.001;
	ui_category = "Sharpen image";
> = 0.65;

uniform float Offset <
	ui_label = "High-pass offset";
	ui_tooltip = "High-pass cross offset in pixels";
	ui_type = "drag";
	ui_min = 0.01; ui_max = 2; ui_step = 0.002;
	ui_category = "Sharpen image";
> = 0.1;

uniform bool Preview <
	ui_label = "Preview sharpen layer";
	ui_category = "Sharpen image";
> = false;

uniform bool Sharpen <
	ui_label = "Enable sharpening";
	ui_category = "Sharpen image";
> = true;

#endif

sampler DepthBuffer
{
	Texture = ReShade::DepthBufferTex;
};

float Depth(in float2 texcoord : TEXCOORD0) //This is done because adjusting the DepthBuffer is anoying in reshade.
{	
	if (Depth_Map_Flip)
		texcoord.y =  1 - texcoord.y;
	//Had to use tex2Dlod so it don't error out in DX9	
	float zBuffer = tex2Dlod(DepthBuffer,float4(texcoord,0,0)).x, DMA = Depth_Map_Adjust * 2.0f; //Depth Buffer adjusted for this shader.

	//Conversions to linear space.....
	//Near & Far Adjustment
	float Far = 1.0, Near = 0.125/DMA; //Division Depth Map Adjust - Near
	//zOffset to adjust for no conforming depth buffers like in the Game Fez.
	float2 Offsets = float2(1 + zOffset,1 - zOffset), Z = float2( zBuffer, 1-zBuffer );
	
	if (Offset > 0)
	Z = min( 1, float2( Z.x*Offsets.x , Z.y /  Offsets.y  ));
		
	if (Depth_Map == 0)//DM0. Normal
		zBuffer = Far * Near / (Far + Z.x * (Near - Far));		
	else if (Depth_Map == 1)//DM1. Reverse
		zBuffer = Far * Near / (Far + Z.y * (Near - Far));
		
	//Convergence Code aka ZPD
	//Keep in mind Perspective needs to me adjusted along with Convergence for VR. You can adapt your ZPD code to push contents back in to the screen.
	return 1 - Convergence / zBuffer; 
}

	/////////////////
	/// FUNCTIONS ///
	/////////////////

// Adjust to limited RGB
float3 tv(float3 Input)
{ return Input*((235-16)/255.0)+16/255.0; }

// Generate test grid
float3 Grid(float2 Coordinates, float AspectRatio)
{
	// Grid settings
	#ifndef BoxAmount
		#define BoxAmount 31 // Number of boxes horizontally (choose odd number)
	#endif
	#ifndef thicknessA
		#define thicknessA 0.25 // White grid thickness
	#endif
	#ifndef thicknessB
		#define thicknessB 0.125 // Yellow cross thickness
	#endif
	#ifndef crossColor
		#define crossColor float3(1.0, 1.0, 0.0) // Center cross color (yellow)
	#endif

	float2 GridCoord = Coordinates;
	// Correct aspect ratio
	GridCoord.y -= 0.5; // Center coordinates vertically
	GridCoord.y /= AspectRatio; // Correct aspect
	GridCoord.y += 0.5; // Center at middle

	float2 CrossUV = GridCoord; // Store center cross coordinates

	float2 PixelSize; float3 gridColor;
	// Generate grid pattern
	GridCoord = RadialPattern ? length(GridCoord-0.5)*1.618 : GridCoord; // Switch to radial pattern
	GridCoord = abs(frac(GridCoord*BoxAmount)*2.0-1.0)*(thicknessA+1.0);
	// Anti-aliased grid
	PixelSize = fwidth(GridCoord);
	GridCoord = smoothstep(1.0-PixelSize, 1.0+PixelSize, GridCoord);

	// Combine vertical and horizontal lines
	
	gridColor = max(Vertical ? GridCoord.x : 0.0, Horizontal ? GridCoord.y : 0.0);

	// Generate center cross
	CrossUV = 1.0-abs(CrossUV*2.0-1.0);
	CrossUV = CrossUV*(thicknessB/BoxAmount+1.0);
	// Anti-aliased cross
	PixelSize = fwidth(CrossUV);
	CrossUV = smoothstep(1.0-PixelSize, 1.0+PixelSize, CrossUV);
	// Combine vertical and horizontal line
	float CrossMask = max(CrossUV.y, CrossUV.x);

	// Blend grid and center cross
	gridColor = lerp(gridColor, (RadialPattern ? 1.0 : crossColor), CrossMask);

	// Solo colors
	if(SoloGreen) gridColor.b = 0.0;
	if(SoloBlue) gridColor.g = 0.0;

	// Reduce grid brightness
	return tv(gridColor);
};


// Divide screen into two halfs
float2 StereoVision(float2 Coordinates, float Center)
{
	float2 StereoCoord = Coordinates;
	StereoCoord.x = 0.25 + abs( StereoCoord.x*2.0-1.0 ) * 0.5; // Divide screen in two
	StereoCoord.x -= lerp(-0.25, 0.25, Center); // Change center for interpupillary distance (IPD)
	// Mirror left half
	float ScreenSide = step(0.5, Coordinates.x);
	StereoCoord.x *= ScreenSide*2.0-1.0;
	StereoCoord.x += 1.0 - ScreenSide;
	return StereoCoord;
};
// Convert stereo coordinates to mono
float2 InvStereoVision(float2 Coordinates, int ScreenMask, float Center)
{
	float2 stereoCoord = Coordinates;
	stereoCoord.x += Center*0.5 * ScreenMask;
	return stereoCoord;
};


// Generate border mask with anti-aliasing from UV coordinates
float BorderMaskAA(float2 Coordinates)
{
	float2 RaidalCoord = abs(Coordinates*2.0-1.0);
	// Get pixel size in transformed coordinates (for anti-aliasing)
	float2 PixelSize = fwidth(RaidalCoord);

	// Create borders mask (with anti-aliasing)
	float2 Borders = smoothstep(1.0-PixelSize, 1.0+PixelSize, RaidalCoord);

	// Combine side and top borders
	return max(Borders.x, Borders.y);
};


// Horizontal parallax offset effect
float2 Parallax(float2 Coordinates, float Offset, float Center, int GapOffset, int Steps)
{
	// Limit amount of loop steps to make it finite
	#ifndef MaximumParallaxSteps
		#def MaximumParallaxSteps 64
	#endif

	// Offset per step progress
	float LayerDepth = 1.0 / min(MaximumParallaxSteps, Steps);

	// Netto layer offset change
	float deltaCoordinates = Offset * LayerDepth;

	float2 ParallaxCoord = Coordinates;
	// Offset image horizontally so that parallax is in the depth appointed center
	ParallaxCoord.x += Offset * Center;
	float CurrentDepthMapValue = Depth(ParallaxCoord).x; // Replace function

	// Steep parallax mapping
	float CurrentLayerDepth = 0.0;
	while(CurrentLayerDepth < CurrentDepthMapValue)
	{
		// Shift coordinates horizontally in linear fasion
		ParallaxCoord.x -= deltaCoordinates;
		// Get depth value at current coordinates
		CurrentDepthMapValue = Depth(ParallaxCoord).x; // Replace function
		// Get depth of next layer
		CurrentLayerDepth += LayerDepth;
	}

	// Parallax Occlusion Mapping
	float2 PrevParallaxCoord = ParallaxCoord;
	PrevParallaxCoord.x += deltaCoordinates;
	float afterDepthValue = CurrentDepthMapValue - CurrentLayerDepth;
	float beforeDepthValue = Depth(PrevParallaxCoord).x; // Replace function
	// Store depth read difference for masking
	float DepthDifference = beforeDepthValue - CurrentDepthMapValue;

	beforeDepthValue += LayerDepth - CurrentLayerDepth;
	// Interpolate coordinates
	float weight = afterDepthValue / (afterDepthValue - beforeDepthValue);
	ParallaxCoord = PrevParallaxCoord * weight + ParallaxCoord * (1.0 - weight);

	// Apply gap masking (by JMF)
	DepthDifference *= GapOffset * Offset * 100.0;
	DepthDifference *= ReShade::PixelSize.x; // Replace function
	ParallaxCoord.x += DepthDifference;

	return ParallaxCoord;
};


// Lens projection model (algorithm by JMF)
float Orthographic(float rFOV, float R){ return tan(asin(sin(rFOV*0.5)*R))/(tan(rFOV*0.5)*R); }
float Equisolid(float rFOV, float R){ return tan(asin(sin(rFOV*0.25)*R)*2.0)/(tan(rFOV*0.5)*R); }
float Equidistant(float rFOV, float R){ return tan(R*rFOV*0.5)/(tan(rFOV*0.5)*R); }
float Stereographic(float rFOV, float R){ return tan(atan(tan(rFOV*0.25)*R)*2.0)/(tan(rFOV*0.5)*R); }

// Brown-Conrady radial distortion model (multiply by coordinates)
float kRadial(float R2, float K1, float K2, float K3, float K4)
{ return 1.0 + K1*R2 + K2*pow(R2,2) + K3*pow(R2,4) + K4*pow(R2,6); };

// Brown-Conrady tangental distortion model (add to coordinates)
float2 pTangental(float2 Coord, float R2, float P1, float P2, float P3, float P4)
{
	return float2(
		(P1*(R2+pow(Coord.x,2)*2.0)+2.0*P2*Coord.x*Coord.y)*(1.0+P3*R2+P4*pow(R2,2)),
		(P2*(R2+pow(Coord.y,2)*2.0)+2.0*P1*Coord.x*Coord.y)*(1.0+P3*R2+P4*pow(R2,2))
	);
};

// RGB to YUV709.luma
float Luma(float3 Input)
{
	static const float3 Luma709 = float3(0.2126, 0.7152, 0.0722);
	return dot(Input, Luma709);
}

// Overlay blending mode
float Overlay(float LayerA, float LayerB)
{
	float MinA = min(LayerA, 0.5);
	float MinB = min(LayerB, 0.5);
	float MaxA = max(LayerA, 0.5);
	float MaxB = max(LayerB, 0.5);
	return 2 * (MinA * MinB + MaxA + MaxB - MaxA * MaxB) - 1.5;
}


	//////////////
	/// SHADER ///
	//////////////

float3 VR_ps(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Get display aspect ratio (horizontal/vertical resolution)
	static const float rAspect = ReShade::AspectRatio;

	// Divide screen in two
	float2 UvCoord = StereoSwitch? StereoVision(texcoord, IPD) : texcoord;

	// Generate negative-positive stereo mask
	float StereoMask = step(0.5, texcoord.x)*2.0-1.0;

	// Correct lens distortion
	if(PerspectiveSwitch)
	{
		// Center coordinates
		UvCoord = UvCoord*2.0-1.0;
		UvCoord.x *= rAspect;
		float2 StereoCoord = UvCoord; // Save coordinates for Brown-Conrady correction

		// Base distortion correction
		if(bool(FOV)) // If FOV is not equal 0
		{
			float radFOV = radians(FOV);
			// Calculate radius
			float Radius = length(UvCoord);
			// Apply base lens correction
			switch(LensType)
			{
				case 0:
					{ UvCoord *= Orthographic(radFOV, Radius); break; }
				case 1:
					{ UvCoord *= Equisolid(radFOV, Radius); break; }
				case 2:
					{ UvCoord *= Equidistant(radFOV, Radius); break; }
				case 3:
					{ UvCoord *= Stereographic(radFOV, Radius); break; }
			}
		};

		// Lens geometric aberration correction (Brown-Conrady model)
		float Diagonal = rAspect; Diagonal *= StereoSwitch ? 0.5 : 1.0;
		Diagonal = length(float2(Diagonal, 1.0));
		float InvDiagonal2 = 1.0 / pow(Diagonal, 2);

		StereoCoord /= Diagonal; // Normalize diagonally
		float Radius2 = dot(StereoCoord, StereoCoord); // Squared radius
		float correctionK = kRadial(Radius2, K.x, K.y, K.z, K.w);
		// Apply negative-positive stereo mask for tangental distortion (flip side)
		float SideScreenSwitch = (StereoSwitch) ? StereoMask : 1.0;

		float2 correctionP = pTangental(
			StereoCoord,
			Radius2,
			P.x * SideScreenSwitch,
			P.y,
			P.z,
			0.0
		);
		// Expand background to vertical border (but not for test grid for ease of calibration)
		UvCoord /= TestGrid ? 1.0 : kRadial(InvDiagonal2, K.x, K.y, K.z, K.w);
		UvCoord = UvCoord * correctionK + correctionP; // Apply lens correction

		// Revert aspect ratio to square
		UvCoord.x /= rAspect;
		// Move origin back to left top corner
		UvCoord = UvCoord*0.5 + 0.5;
	}

	// Display test grid
	if(TestGrid) return Grid(UvCoord, rAspect);

	// Create parallax effect
	if(ParallaxSwitch)
	{
		float ParallaxDirection = ParallaxOffset*0.01;
		// For stereo-vison flip direction on one side
		ParallaxDirection *= StereoSwitch ? StereoMask : 1.0;
		// Apply parallax effect
		UvCoord = Parallax(
			UvCoord,
			ParallaxDirection,
			ParallaxCenter,
			ParallaxMaskScalar,
			ParallaxSteps
		);
	};

	// Sample image with black borders to display
	float3 Image = lerp(
		tex2D(ReShade::BackBuffer, UvCoord).rgb, // Display image
		0.0, // Black borders
		BorderMaskAA(UvCoord) // Anti-aliased border mask
	);

	// Display image
	return Image;
};

float3 Chromatic_ps(float4 vois : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
	// Bypass chromatic aberration switch
	if(!ChromaticAbrSwitch){ return tex2D(ReShade::BackBuffer, texcoord).rgb; }

	// Get display aspect ratio (horizontal/vertical resolution)
	float rAspect = ReShade::AspectRatio;

	// Generate negative-positive stereo mask
	float SideScreenSwitch = step(0.5, texcoord.x)*2.0-1.0;

	// Divide screen in two if stereo vision mode enabled
	float2 CenterCoord = StereoSwitch? StereoVision(texcoord, IPD) : texcoord;

	CenterCoord = CenterCoord*2.0-1.0; // Center coordinates
	CenterCoord.x *= rAspect; // Correct aspect ratio

	float Diagonal = rAspect; Diagonal *= StereoSwitch ? 0.5 : 1.0;
	Diagonal = length(float2(Diagonal, 1.0));

	CenterCoord /= Diagonal; // Normalize diagonally

	// Left/right eye mask
	float L = step(0.5, 1.0-texcoord.x), R = step(0.5, texcoord.x);

	// Offset center green
	float2 CoordGreen = ChGreenOffsetL * L + ChGreenOffsetR * R;
	CoordGreen.x *= -1.0;
	CoordGreen = 0.01 * CoordGreen + CenterCoord;
	// Offset center blue
	float2 CoordBlue = ChBlueOffsetL * L + ChBlueOffsetR * R;
	CoordBlue.x *= -1.0;
	CoordBlue = 0.01 * CoordBlue + CenterCoord;

//	float RadiusGreen = dot(CoordGreen, CoordGreen); // Radius squared (techically accurate)
//	float RadiusBlue = dot(CoordBlue, CoordBlue); // Radius squared (techically accurate)
	float RadiusGreen = length(CoordGreen); // Radius
	float RadiusBlue = length(CoordBlue); // Radius

	// Calculate radial distortion K
	float correctionGreenK = (1.0+ChGreenK.x)*kRadial(RadiusGreen, ChGreenK.y, ChGreenK.z, ChGreenK.w, 0.0);
	float correctionBlueK = (1.0+ChBlueK.x)*kRadial(RadiusBlue, ChBlueK.y, ChBlueK.z, ChBlueK.w, 0.0);

	// Apply chromatic aberration correction
	CoordGreen = CoordGreen * correctionGreenK;
	CoordBlue = CoordBlue * correctionBlueK;

	CoordGreen *= Diagonal; CoordBlue *= Diagonal; // Back to vertical normalization
	CoordGreen.x /= rAspect; CoordBlue.x /= rAspect; // Back to square

	// Move origin to left top corner
	CoordGreen = CoordGreen * 0.5 + 0.5; CoordBlue = CoordBlue * 0.5 + 0.5;

	// Generate border mask for green and blue channel
	float MaskBlue, MaskGreen; if(StereoSwitch)
	{
		// Mask compensation for center cut
		float CenterCut = 0.5+(0.5-IPD)*SideScreenSwitch;

		// Mask sides and center cut for blue channel
		float2 MaskCoordBlue;
		MaskCoordBlue.x = CoordBlue.x*2.0 - CenterCut; // Compensate for 2 views
		MaskCoordBlue.y = CoordBlue.y;
		MaskBlue = BorderMaskAA(MaskCoordBlue);

		// Mask sides and center cut for green channel
		float2 MaskCoordGreen;
		MaskCoordGreen.x = CoordGreen.x*2.0 - CenterCut; // Compensate for 2 views
		MaskCoordGreen.y = CoordGreen.y;
		MaskGreen = BorderMaskAA(MaskCoordGreen);

		// Reverse stereo coordinates to single view
		CoordGreen = InvStereoVision(CoordGreen, SideScreenSwitch, IPD);
		CoordBlue = InvStereoVision(CoordBlue, SideScreenSwitch, IPD);
	}
	else
	{
		MaskBlue = BorderMaskAA(CoordBlue);
		MaskGreen = BorderMaskAA(CoordGreen);
	};

	float3 Image;
	// Sample image red
	Image.r = tex2D(ReShade::BackBuffer, texcoord).r;
	// Sample image green
	Image.g = lerp(
		tex2D(ReShade::BackBuffer, CoordGreen).g,
		0.0, // Black borders
		MaskGreen // Anti-aliased border mask
	);
	// Sample image blue
	Image.b = lerp(
		tex2D(ReShade::BackBuffer, CoordBlue).b,
		0.0, // Black borders
		MaskBlue // Anti-aliased border mask
	);

	// Display chromatic aberration
	return Image;
};


// Sharpen pass
float3 FilmicSharpenPS(float4 vois : SV_Position, float2 UvCoord : TexCoord) : SV_Target
{
	// Bypass sharpening
	if(!Sharpen) return tex2D(ReShade::BackBuffer, UvCoord).rgb;
	
	float2 Pixel = ReShade::PixelSize * Offset;
	// Sample display image
	float3 Source = tex2D(ReShade::BackBuffer, UvCoord).rgb;

	float2 NorSouWesEst[4] = {
		float2(UvCoord.x, UvCoord.y + Pixel.y),
		float2(UvCoord.x, UvCoord.y - Pixel.y),
		float2(UvCoord.x + Pixel.x, UvCoord.y),
		float2(UvCoord.x - Pixel.x, UvCoord.y)
	};

	// Luma high-pass
	float HighPass = 0;
	for(int i=0; i<4; i++) HighPass += Luma(tex2D(ReShade::BackBuffer, NorSouWesEst[i]).rgb);
	HighPass = 0.5 - 0.5 * (HighPass * 0.25 - Luma(Source));

	// Sharpen strength
	HighPass = lerp(0.5, HighPass, Strength);

	// Clamping sharpen
	HighPass = (Clamp != 1) ? max(min(HighPass, Clamp), 1 - Clamp) : HighPass;

	float3 Sharpen = float3(
		Overlay(Source.r, HighPass),
		Overlay(Source.g, HighPass),
		Overlay(Source.b, HighPass)
	);

	return (Preview) ? HighPass : Sharpen;
}


technique VR{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = VR_ps;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = FilmicSharpenPS;
	}
	pass{
		VertexShader = PostProcessVS;
		PixelShader = Chromatic_ps;
	}
};
