#define SO_SPHERE 1
#define SO_BOX 2
#define SO_GOOP 20


struct SO { int type; vec3 position; vec3 size; vec3 color; };


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
    float h = clamp(0.5 + 0.5 * (distanceB - distanceA) / smoothFactor, 0.0, 1.0);
    return mix(distanceB, distanceA, h) - smoothFactor * h * (1.0 -h);
}

vec4 smoothUnionSdf(vec4 a, vec4 b, float k)
{
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

float _sphereSdf(vec3 ray, float size)  {
  return length( ray)-size;
}


float sphereSdf(vec3 ray, SO sphere, float u_time)  {
  return _sphereSdf(ray-sphere.position, sphere.size.x);
}

float boxSdf(vec3 ray, SO box, float u_time)  {
  vec3 q = abs(ray - box.position) - box.size;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float goopSdf(vec3 ray, SO goop, float u_time)
{
    float goopTime = u_time * 0.25;
    
    float k = 1.0;
    float size = goop.size.x;
    
    ray -= goop.position;
    vec3 head = vec3(0,0,0);
    vec3 ear1 = vec3(1.0* sin(4.0 - goopTime), 1.0* cos(4.0 - goopTime), 0);
    vec3 ear2 = vec3(1.0* sin(4.0 + goopTime), 1.0* cos(4.0 + goopTime), 0);
    vec3 ear3 = vec3(1.0* sin(2.0 - goopTime), 1.0* cos(2.0 - goopTime), 0);
    vec3 ear4 = vec3(1.0* sin(2.0 + goopTime), 1.0* cos(2.0 + goopTime), 0);
    vec3 ear5 = vec3(1.0* sin(6.0 + goopTime), 1.0* cos(6.0 + goopTime), 0);
    vec3 ear6 = vec3(1.0* sin(6.0 - goopTime), 1.0* cos(6.0 - goopTime), 0);

    return  smoothUnionSdf(
            smoothUnionSdf(
            smoothUnionSdf(
            smoothUnionSdf(
            smoothUnionSdf(
            smoothUnionSdf(_sphereSdf(ray-head, size*1.25),
                            _sphereSdf(ray-ear1, size / 2.0), k), 
                            _sphereSdf(ray-ear2, size / 2.0), k), 
                            _sphereSdf(ray-ear3, size / 2.0), k), 
                            _sphereSdf(ray-ear4, size / 2.0), k),
                            _sphereSdf(ray-ear5, size / 2.0), k),
                            _sphereSdf(ray-ear6, size / 2.0), k);
}
 


float cappedCylinderSdf( vec3 point, float height, float radius)
{
    vec2 distance = abs(vec2(length(point.xz), point.y)) - vec2(radius, height);
    return min(max(distance.x, distance.y), 0.0) + length(max (distance, 0.0));
}