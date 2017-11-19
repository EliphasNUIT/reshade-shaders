/**
 * Green Screen
 * By moriz1
 */

uniform float ScreenDepth <
    ui_label = "Screen Depth";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
    ui_tooltip = "How deep you want the screen.";
> = 0.7;
uniform float3 ScreenColor <
    ui_label = "Screen Color";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
> = float3(0.0, 1.0, 0.0);

#include "ReShade.fxh"

float3 Screen(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
    float depth = ReShade::GetLinearizedDepth(texcoord);
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

    if (depth >= ScreenDepth) { return ScreenColor; }

    return color;
}

technique GreenScreen
{
    pass Screen
    {
        VertexShader = PostProcessVS;
		PixelShader = Screen;
    }
}