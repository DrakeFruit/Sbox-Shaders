HEADER
{
	Description = "Testing post process shader";
}

FEATURES
{
	#include "common/features.hlsl"
}

MODES
{
	VrForward();
	Depth();
}

COMMON
{
	#include "common/shared.hlsl"
	#include "postprocess/shared.hlsl"
}

struct VertexInput
{
	float3 vPositionOs : POSITION < Semantic( PosXyz ); >;
	float2 vTexCoord : TEXCOORD0 < Semantic( LowPrecisionUv ); >;
};

struct PixelInput
{
	float2 vTexCoord : TEXCOORD0;

	#if ( PROGRAM == VFX_PROGRAM_VS )
		float4 vPositionPs		: SV_Position;
	#endif

	#if ( ( PROGRAM == VFX_PROGRAM_PS ) )
		float4 vPositionSs		: SV_Position;
	#endif
};

VS
{
	PixelInput MainVs( VertexInput i )
	{
		PixelInput o;
		
		o.vPositionPs = float4( i.vPositionOs.xy, 0.0f, 1.0f );
		o.vTexCoord = i.vTexCoord;
		return o;
	}
}

PS
{
	#include "postprocess/common.hlsl"

	RenderState( DepthWriteEnable, false );
    RenderState( DepthEnable, false );

	CreateTexture2D( g_tColorBuffer ) < Attribute( "ColorBuffer" );  	SrgbRead( true ); Filter( MIN_MAG_LINEAR_MIP_POINT ); AddressU( MIRROR ); AddressV( MIRROR ); >;
    CreateTexture2D( g_tDepthBuffer ) < Attribute( "DepthBuffer" ); 	SrgbRead( false ); Filter( MIN_MAG_MIP_POINT ); AddressU( CLAMP ); AddressV( CLAMP ); >;

	float3 FogColor < Attribute( "FogColor" ); >;
	float FogDensity < Attribute( "FogDensity" ); >;
	float FogOffset < Attribute( "FogOffset" ); >;

	float4 MainPs( PixelInput i ) : SV_Target0
	{
		// Get screen UV
        float2 vScreenUv = i.vPositionSs.xy / g_vRenderTargetSize;
        // Get the current color at a given pixel
        float3 vFrameBufferColor = Tex2D( g_tColorBuffer, vScreenUv.xy ).rgb;

		// Get depth of pixel
		float vDepth = 1 - Depth::GetNormalized( i.vPositionSs.xy );
		// Convert to view space distance
		vDepth = ( 1 - g_flViewportMaxZ / g_flViewportMinZ ) * vDepth + ( g_flViewportMaxZ / g_flViewportMinZ );
		vDepth = 1.0 / vDepth;
		if ( vDepth >= 0.99 ) vDepth = 1;
        float viewDistance = vDepth * g_flViewportMaxZ;
		if ( viewDistance == 0 ) viewDistance = 1;

		// Calculate fog factor
        float fogFactor = ( FogDensity / sqrt( log(2) ) ) * max( 0.0, viewDistance - FogOffset );
        fogFactor = exp2(-fogFactor * fogFactor);
		// Blend fog and color
		float3 adjustedColor = lerp( FogColor, vFrameBufferColor, saturate(fogFactor) );

		return float4( adjustedColor, 1 );
	}
}