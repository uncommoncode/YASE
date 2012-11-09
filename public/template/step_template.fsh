precision highp float;


// Noise Functions from:
// https://github.com/ashima/webgl-noise

vec3 _mod289(in vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}
vec4 _mod289(in vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}
vec4 _permute(in vec4 x) {
  return _mod289(((x * 34.0) + 1.0) * x);
}
vec4 taylorInvSqrt(in vec4 r) {
  return 1.79284291400159 - 0.85373472095314 * r;
}

/**
3-dimensional simplex noise
*/
float noise(in vec3 v) {
  const vec2 C = vec2(1.0 / 6.0, 1.0 / 3.0) ;
  const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);

  vec3 i = floor(v + dot(v, C.yyy));
  vec3 x0 = v - i + dot(i, C.xxx);
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min(g.xyz, l.zxy);
  vec3 i2 = max(g.xyz, l.zxy);
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy;
  vec3 x3 = x0 - D.yyy;

  i = _mod289(i);
  vec4 p = _permute(_permute(_permute(
    i.z + vec4(0.0, i1.z, i2.z, 1.0)) +
    i.y + vec4(0.0, i1.y, i2.y, 1.0)) +
    i.x + vec4(0.0, i1.x, i2.x, 1.0));

  float n_ = 0.142857142857;
  vec3 ns = n_ * D.wyz - D.xzx;
  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_);
  vec4 x = x_ * ns.x + ns.yyyy;
  vec4 y = y_ * ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);
  vec4 b0 = vec4(x.xy, y.xy);
  vec4 b1 = vec4(x.zw, y.zw);
  vec4 s0 = floor(b0) * 2.0 + 1.0;
  vec4 s1 = floor(b1) * 2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));
  vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww ;
  vec3 p0 = vec3(a0.xy, h.x);
  vec3 p1 = vec3(a0.zw, h.y);
  vec3 p2 = vec3(a1.xy, h.z);
  vec3 p3 = vec3(a1.zw, h.w);

  vec4 norm = taylorInvSqrt(vec4(
    dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)
  ));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

  vec4 m = max(0.6 - vec4(
    dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)
  ), 0.0);
  m = m * m;
  return 42.0 * dot(m * m, vec4(
    dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)
  ));
}
float noise(in float x, in float y, in float z) {
  return noise(vec3(x, y, z));
}


// YASE Specific

uniform sampler2D position, position_prev, index, amp_left, amp_right, shadow_depth;
uniform mat4 light_mvp;

/** Camera position */
uniform vec3 cameraPos;

/** Current and previous mouse positions in world space */
uniform vec3 mousePos;
uniform vec3 prevMousePos;

/** Current and previous mouse positions [0, 1] in screen space */
uniform vec3 screenMousePos;
uniform vec3 prevScreenMousePos;

/** Seconds since the page was loaded or a track was played */
uniform float time;

/** Current frame number */
uniform float frame;

/** Vertical and horizontal dimension of the simulation’s backing framebuffer */
uniform float resolution;
uniform float oneOverRes;

/** Total number of particles */
uniform float count;

/** Position in the currently playing track [0, 1] if there is one */
uniform float progress;

/** Coordinate of the currently rendering fragment */
varying vec2 texcoord;

/**
Circle diameter over circumference.
*/
#define PI 3.141592653589793

/**
Amplitude of the left channel at frequency {x} [0, 1]
*/
float ampLeft(in float x) {
  return texture2D(amp_left, vec2(x, 0.)).x;
}
/**
Amplitude of the left channel at frequency {x} [0, 1]
*/
float ampRight(in float x) {
  return texture2D(amp_right, vec2(x, 0.)).x;
}

/**
Get the un-normalized texture coordinate for particle at index {i}
*/
vec2 getCoord(in float i) {
  float y = floor(i * oneOverRes);
  return vec2(i - resolution * y, y) + .5;
}

/**
Get the current position of a particle at index {i}
*/
vec4 getPos(in float i) {
  return texture2D(position, getCoord(i) * oneOverRes);
}
vec4 getPos(in int i) {
  return getPos(float(i));
}

/**
Get the previous position of a particle at index {i}
*/
vec4 getPrevPos(in float i) {
  return texture2D(position_prev, getCoord(i) * oneOverRes);
}
vec4 getPrevPos(in int i) {
  return getPrevPos(float(i));
}

float getShadowDepth(in vec3 p) {
  vec4 pt = light_mvp * vec4(p, 1.);
  return pt.z - texture2D(shadow_depth, (pt.xy + 1.) * .5).x;
}

/**
Get the amount of shadow for a position in space.
Requires `#define shadows 1`
*/
float getShadow(in vec3 p, in float darkening_factor) {
  return clamp(exp(-darkening_factor * getShadowDepth(p)), 0., 1.);
}

/**
Pseudo-random value [0, 1] at vec2 {p}, {x, y}, or {x}
*/
float rand(in vec2 p) {
  return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}
float rand(in float x, in float y) {
  return rand(vec2(x, y));
}
float rand(in float x) {
  return rand(vec2(x, 0.));
}

/**
Pseudo-random point on the unit-sphere
*/
vec3 rand3(in vec2 p) {
  float phi = rand(p) * PI * 2.;
  float ct = rand(p.yx) * 2. - 1.;
  float rho = sqrt(1. - ct * ct);
  return vec3(rho * cos(phi), rho * sin(phi), ct);
}
vec3 rand3(in float x, in float y) {
  return rand3(vec2(x, y));
}
vec3 rand3(in float x) {
  return rand3(x, x * 2.);
}

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

<%= src_fragment %>

void main() {
  vec4 i = texture2D(index, texcoord)
     , p = texture2D(position, texcoord)
     , pp = texture2D(position_prev, texcoord);
  vec3 prevColor = float2color(pp.w)
     , color = float2color(p.w)
     , nextColor;
  stepPos(i.x, pp, p, gl_FragColor, prevColor, color, nextColor);
  gl_FragColor.w = color2float(nextColor);
}
