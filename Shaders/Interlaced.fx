/* 
Interlaced effect PS v1.0.4 (c) 2018 Jacob Maximilian Fober, 
(blending fix thanks to Marty McFly)

This work is licensed under the Creative Commons 
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
http://creativecommons.org/licenses/by-sa/4.0/.
*/

#ifndef ShaderAnalyzer
uniform int FrameCount < source = "framecount"; >;
#endif

// Previous frame render target buffer
#if !defined(ResolutionX) || !defined(ResolutionY)
	texture InterlacedTargetBuffer { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
#else
	texture InterlacedTargetBuffer { Width = ResolutionX; Height = ResolutionY; };
#endif

sampler InterlacedBufferSampler { Texture = InterlacedTargetBuffer;
	MagFilter = POINT;
	MinFilter = POINT;
	MipFilter = POINT;
};

#include "ReShade.fxh"

void InterlacedTargetPass(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD,
out float4 Target : SV_Target)
{
	// Interlaced rows boolean
	bool OddPixel = frac(int(ReShade::ScreenSize.y * UvCoord.y) * 0.5) != 0;
	bool OddFrame = frac(FrameCount * 0.5) != 0;
	bool BottomHalf = UvCoord.y > 0.5;

	// Flip flop saving texture between top and bottom half of the RenderTarget
	float2 Coordinates;
	Coordinates.x = UvCoord.x;
	Coordinates.y = UvCoord.y * 2;
	// Adjust flip flop coordinates
	float hPixelSizeY = ReShade::PixelSize.y * 0.5;
	Coordinates.y -= BottomHalf ? 1 + hPixelSizeY : hPixelSizeY;
	// Flip flop save to Render Target texture
	Target = (OddFrame ? BottomHalf : UvCoord.y < 0.5) ?
		float4(tex2D(ReShade::BackBuffer, Coordinates).rgb, 1) : 0;
	// Outputs raw BackBuffer to InterlacedTargetBuffer for the next frame
}

void InterlacedPS(float4 vpos : SV_Position, float2 UvCoord : TEXCOORD,
out float3 Image : SV_Target)
{
	// Interlaced rows boolean
	bool OddPixel = frac(int(ReShade::ScreenSize.y * UvCoord.y) * 0.5) != 0;
	bool OddFrame = frac(FrameCount * 0.5) != 0;
	// Calculate coordinates of BackBuffer texture saved at previous frame
	float2 Coordinates = float2(UvCoord.x, UvCoord.y * 0.5);
	float qPixelSizeY = ReShade::PixelSize.y * 0.25;
	Coordinates.y += OddFrame ? qPixelSizeY : qPixelSizeY + 0.5;
	// Sample odd and even rows
	Image = OddPixel ? tex2D(ReShade::BackBuffer, UvCoord).rgb
	: tex2D(InterlacedBufferSampler, Coordinates).rgb;

	// Preview RenderTarget
//	Image = tex2D(InterlacedBufferSampler, UvCoord).rgb;
}

technique Interlaced
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = InterlacedTargetPass;
		RenderTarget = InterlacedTargetBuffer;
		ClearRenderTargets = false;
		BlendEnable = true;
			BlendOp = ADD; //mimic lerp
				SrcBlend = SRCALPHA;
				DestBlend = INVSRCALPHA;
	}
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = InterlacedPS;
	}
}
