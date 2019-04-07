#version 330
#extension GL_ARB_separate_shader_objects : enable

layout(location=1) in vec2 fsTex;
layout(location=0) out vec4 target;

uniform sampler2D mainTex;
uniform vec4 color;

const vec3 white = vec3(1., 1., 1.);
const vec3 black = vec3(0, 0, 0);

void main()
{
	vec4 mainColor;

	// if (color.xyz == white) {
		mainColor  = texture(mainTex, fsTex.xy);
		target = mainColor * color;
	// } else {
	// 	mainColor = texture(mainTex, vec2(fsTex.x / 2, fsTex.y));
	// 	vec4 mask = texture(mainTex, vec2(fsTex.x / 2 + 0.5, fsTex.y));
	// 	if (mask.x > 0) {
	// 		target.xyz = mainColor.xyz * color.xyz;
	// 		target.a = mainColor.a;
	// 	} else {
	// 		target = mainColor;
	// 	}
	// 	target.a *= color.a;
	// }
}