/**
 * Orton Bloom
 * By moriz1
 */

uniform float BlurMulti <
	ui_label = "Blur Multiplier";
	ui_type = "drag";
	ui_min = 0.0; ui_max = 1.0;
    ui_tooltip = "Blur strength";
> = 1.0;
uniform int BlackPoint <
	ui_type = "drag";
	ui_min = 0; ui_max = 255;
	ui_tooltip = "The new black point for blur texture. Everything darker than this becomes completely black.";
> = 60;
uniform int WhitePoint <
	ui_type = "drag";
	ui_min = 0; ui_max = 255;
	ui_tooltip = "The new white point for blur texture. Everything brighter than this becomes completely white.";
> = 150;
uniform float MidTonesShift <
	ui_type = "drag";
	ui_min = -1.0; ui_max = 1.0;
	ui_tooltip = "Adjust midtones for blur texture.";
> = -0.84;
uniform float BlendStrength <
	ui_label = "Blend Strength";
	ui_type = "drag";
	ui_min = 0.00; ui_max = 1.0;
	ui_tooltip = "Opacity of blur texture. Keep this value low, or image will get REALLY blown out.";
> = 0.07;

#include "ReShade.fxh"

texture GaussianBlurTex { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler GaussianBlurSampler { Texture = GaussianBlurTex; };

texture GaussianBlurTex2 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler GaussianBlurSampler2 { Texture = GaussianBlurTex2; };

float3 GaussianBlur1(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float blurPower = pow((color.r*2 + color.b + color.g*3) / 6, 1/2.2);

    float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2D(ReShade::BackBuffer, texcoord + float2(offset[i] * ReShade::PixelSize.x, 0.0) * blurPower * BlurMulti).rgb * weight[i];
		color += tex2D(ReShade::BackBuffer, texcoord - float2(offset[i] * ReShade::PixelSize.x, 0.0) * blurPower * BlurMulti).rgb * weight[i];
	}

    return saturate(color);
}

float3 GaussianBlur2(in float4 pos : SV_Position, in float2 texcoord : TEXCOORD) : SV_Target
{
    float3 color = tex2D(GaussianBlurSampler, texcoord).rgb;
	float3 original = tex2D(ReShade::BackBuffer, texcoord).rgb;
    float blurPower = pow((original.r*2 + original.b + original.g*3) / 6, 1/2.2);

    float offset[18] = { 0.0, 1.4953705027, 3.4891992113, 5.4830312105, 7.4768683759, 9.4707125766, 11.4645656736, 13.4584295168, 15.4523059431, 17.4461967743, 19.4661974725, 21.4627427973, 23.4592916956, 25.455844494, 27.4524015179, 29.4489630909, 31.445529535, 33.4421011704 };
	float weight[18] = { 0.033245, 0.0659162217, 0.0636705814, 0.0598194658, 0.0546642566, 0.0485871646, 0.0420045997, 0.0353207015, 0.0288880982, 0.0229808311, 0.0177815511, 0.013382297, 0.0097960001, 0.0069746748, 0.0048301008, 0.0032534598, 0.0021315311, 0.0013582974 };
	
	color *= weight[0];
	
	[loop]
	for(int i = 1; i < 18; ++i)
	{
		color += tex2D(GaussianBlurSampler, texcoord + float2(0.0, offset[i] * ReShade::PixelSize.y) * blurPower * BlurMulti).rgb * weight[i];
		color += tex2D(GaussianBlurSampler, texcoord - float2(0.0, offset[i] * ReShade::PixelSize.y) * blurPower * BlurMulti).rgb * weight[i];
	}

    return saturate(color);
}

float3 LevelsAndBlend(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float black_point_float = BlackPoint / 255.0;
	float white_point_float = WhitePoint == BlackPoint ? (255.0 / 0.00025) : (255.0 / (WhitePoint - BlackPoint)); // Avoid division by zero if the white and black point are the same
	float mid_point_float = (white_point_float + black_point_float) / 2.0 + MidTonesShift;

	if (mid_point_float > white_point_float) { mid_point_float = white_point_float; }
	else if (mid_point_float < black_point_float) { mid_point_float = black_point_float; }

	float3 color = tex2D(GaussianBlurSampler2, texcoord).rgb;
	float3 original = tex2D(ReShade::BackBuffer, texcoord).rgb;;
	color = (color * white_point_float - (black_point_float * white_point_float)) * mid_point_float;

	return saturate(max(0.0, max(original, lerp(original, (1 - (1 - saturate(color)) * (1 - saturate(color))), BlendStrength))));
}

technique OrtonBloom
{
    pass GaussianBlur1
    {
        VertexShader = PostProcessVS;
        PixelShader = GaussianBlur1;
        RenderTarget = GaussianBlurTex;
    }
    pass GaussianBlur2
    {
        VertexShader = PostProcessVS;
        PixelShader = GaussianBlur2;
        RenderTarget = GaussianBlurTex2;
    }
    pass LevelsAndBlend
    {
        VertexShader = PostProcessVS;
        PixelShader = LevelsAndBlend;
    }
}