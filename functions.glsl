struct Sphere { vec3 position; float size; vec3 color; };
struct Gloob { Sphere[7] spheres; vec3 position; };

vec4 intersectSdf(vec4 distanceA, vec4 distanceB)
{
    return distanceA.w > distanceB.w? distanceA : distanceB;
}

vec4 unionSdf(vec4 distanceA, vec4 distanceB)
{
    return distanceA.w < distanceB.w? distanceA : distanceB;
}

vec4 differenceSdf(vec4 distanceA, vec4 distanceB)
{
   return distanceA.w > distanceB.w? distanceA : vec4(distanceB.rgb, -distanceB.w);
}

float smoothUnionSdf(float distanceA, float distanceB, float smoothFactor)
{
    float k = smoothFactor;
    float h = clamp(0.5 + 0.5 * (distanceB - distanceA) / k, 0.0, 1.0);
    return mix(distanceB, distanceA, h) - k * h * (1.0 -h);
}

vec4 smoothUnionSdf(vec4 a, vec4 b, float smoothFactor)
{
    float k = smoothFactor;
    float h = clamp(0.5 - 0.5*(a.w+b.w)/k, 0., 1.);
    vec3 c = mix(a.rgb,b.rgb,h);
    float d = mix(a.w, -b.w, h ) + k*h*(1.-h);
   
    return vec4(c,d);
}



mat2 Rotate(float point) {
    float s = sin(point);
    float c = cos(point);
    return mat2(c,-s,s,c);
}
 
float sphereSDF(vec3 ray, Sphere sphere)  {
  return length(sphere.position - ray)-sphere.size;
}
 
float boxSDF( vec3 point, vec3 boxSize) {
  vec3 q = abs(point) - boxSize;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float cappedCylinderSdf( vec3 point, float height, float radius)
{
    vec2 distance = abs(vec2(length(point.xz), point.y)) - vec2(radius, height);
    return min(max(distance.x, distance.y), 0.0) + length(max (distance, 0.0));
}