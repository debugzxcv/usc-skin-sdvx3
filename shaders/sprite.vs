#version 330
#extension GL_ARB_separate_shader_objects : enable
layout(location=0) in vec2 inPos;
layout(location=1) in vec2 inTex;

out gl_PerVertex
{
	vec4 gl_Position;
};
layout(location=1) out vec2 fsTex;

uniform mat4 proj;
uniform mat4 camera;
uniform mat4 world;

void main()
{
	fsTex = inTex;
	gl_Position = proj * camera * world * vec4(inPos.xy, 0, 1);

	// mat4 originalMatrix = camera * world;
	// mat4 result;
	// result[0] = vec4(length(originalMatrix[0].xyz), .0, .0, .0);
	// result[1] = vec4(.0, length(originalMatrix[1].xyz), .0, .0);
	// result[2] = vec4(.0, .0, length(originalMatrix[2].xyz), .0);
	// result[3] = originalMatrix[3];
	// gl_Position = proj * (result * vec4(inPos.xy, 0, 1));
}