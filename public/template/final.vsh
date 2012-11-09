uniform mat4 u_mvp;
uniform sampler2D u_position;
uniform float u_point_size;

attribute vec2 a_texcoord;

varying vec4 v_color;

// c_precision of 128 fits within 7 base-10 digits
const float c_precision = 128.0;
const float c_precisionp1 = c_precision + 1.0;

/*
\param color normalized RGB value
\returns 3-component encoded float
*/
float color2float(vec3 color) {
	color = clamp(color, 0.0, 1.0);
	return floor(color.r * c_precision + 0.5) 
		+ floor(color.b * c_precision + 0.5) * c_precisionp1
		+ floor(color.g * c_precision + 0.5) * c_precisionp1 * c_precisionp1;
}

/*
\param value 3-component encoded float
\returns normalized RGB value
*/
vec3 float2color(float value) {
	vec3 color;
	color.r = mod(value, c_precisionp1) / c_precision;
	color.b = mod(floor(value / c_precisionp1), c_precisionp1) / c_precision;
	color.g = floor(value / (c_precisionp1 * c_precisionp1)) / c_precision;
	return color;
}

void main() {
  vec4 t = texture2D(u_position, a_texcoord);

  gl_Position = u_mvp * vec4(t.xyz, 1.);
  gl_PointSize = u_point_size;

  v_color = vec4(float2color(t.w), 1.);
}
