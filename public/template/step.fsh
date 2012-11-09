
void stepPos(in float i, in vec4 prevPos, in vec4 pos, out vec4 nextPos, in vec3 prevColor, in vec3 color, out vec3 nextColor) {
  float t = i / count;
  float t1 = t * 500.;
  nextPos.x = sin(t1) * t * 10.;
  nextPos.y = cos(t1) * t * 10.;
  nextPos.z = t * (sin(t * 10. - time) + sin(t1 * 10. + time));
  nextPos.w = 1.0;
  nextColor = vec3(1.0);
}
