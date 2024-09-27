using System;

[Category( "Post Processing" )]
[Icon( "grain" )]
public sealed class TestPostProcess : PostProcess, Component.ExecuteInEditor
{
	[Property] public Color FogColor { get; set; } = Color.White;
	[Property] public float FogDensity { get; set; } = 0.25f;
	[Property] public float FogOffset { get; set; } = 0.25f;
	IDisposable renderHook;

	protected override void OnEnabled()
	{
		renderHook = Camera.AddHookBeforeOverlay( "Test Post Processing", 1000, RenderEffect );
	}

	protected override void OnDisabled()
	{
		renderHook?.Dispose();
		renderHook = null;
	}

	protected override void OnDestroy()
	{
		renderHook?.Dispose();
		renderHook = null;
	}

	RenderAttributes attributes = new RenderAttributes();

	public void RenderEffect( SceneCamera camera )
	{
		if ( !camera.EnablePostProcessing )
			return;

		// Pass the Color property to the shader
		attributes.Set( "FogColor", FogColor );
		attributes.Set( "FogDensity", FogDensity );
		attributes.Set( "FogOffset", FogOffset );

		// Pass the FrameBuffer to the shader
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );

		// Blit a quad across the entire screen with our custom shader
		Graphics.Blit( Material.FromShader( "shaders/testing.shader" ), attributes );
	}
}