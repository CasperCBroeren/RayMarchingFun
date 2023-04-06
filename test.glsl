precision highp float; 
uniform vec2 u_resolution;  // Width and height of the shader
uniform float u_time;  // Time elapsed
uniform vec3 u_camera;
uniform float smoothFactor;
 
// Constants
#define PI 3.1415925359

#define MAX_STEPS 200
#define MAX_DIST 100.
#define SURFACE_DIST .01
#define ZOOM 0.9


struct Sphere { vec3 position; float size; vec3 color; };

// Boolean operators
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

float smoothUnionSdf(float distanceA, float distanceB)
{
    float k = smoothFactor;
    float h = clamp(0.5 + 0.5 * (distanceB - distanceA) / k, 0.0, 1.0);
    return mix(distanceB, distanceA, h) - k * h * (1.0 -h);
}

mat2 Rotate(float point) {
    float s = sin(point);
    float c = cos(point);
    return mat2(c,-s,s,c);
}
 
float sphereSDF( vec3 point, float size ) {
  return length(point)-size;
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
  

vec4 scene2(vec3 position)
{      
    Sphere head = Sphere(vec3(0,1,0), 1.0, vec3(1,0,0));
    Sphere earL = Sphere(vec3(-1,2,0), 0.5, vec3(0,1,0));
    Sphere earR = Sphere(vec3(1,2,0), 0.5, vec3(0,0,1));
     
    return vec4(head.color.rgb, 
                smoothUnionSdf(
                smoothUnionSdf(sphereSDF(position-head.position, head.size),
                               sphereSDF(position-earL.position, earL.size)), 
                               sphereSDF(position-earR.position, earR.size)));
    
}

vec4 scene(vec3 position)
{
    vec3 floorColor = vec3(0.4471, 0.7608, 0.9059);
    float floorPlane = position.y+0.25;  
    return unionSdf(scene2(position), vec4(floorColor.rgb, floorPlane));
}
 
float RayMarch(vec3 camera, vec3 farPlane, inout vec3 color) 
{
    float distanceOrigin = 0.;
    for(int i=0;i<MAX_STEPS;i++)
    {
        if(distanceOrigin > MAX_DIST)        break;
        
        vec3 ray = camera + farPlane * distanceOrigin;
        vec4 distanceScene = scene(ray); 
        
        if (distanceScene.w < SURFACE_DIST) 
        {
            color = distanceScene.rgb;
            break;
        }
        distanceOrigin += distanceScene.w;
    }
    return distanceOrigin;
}

vec3 GetNormal(vec3 position)
{
    vec4 distance = scene(position);
    vec2 epsilon = vec2(0.01, 0);
    vec3 normal = distance.w - vec3(
        scene(position - epsilon.xyy).w,
    scene(position - epsilon.yxy).w,
    scene(position - epsilon.yyx).w);

    return normalize(normal);
}

vec3 GetLight(vec3 position, vec3 color)
{
    vec3 lightPos = vec3(5.0,5., -5.0);
    vec3 light = normalize(lightPos - position);

    vec3 normal = GetNormal(position);
    float diffuse = dot(normal, light);
    diffuse = clamp(diffuse, 0., 1.);

    float d = RayMarch(position + normal  * SURFACE_DIST * 2., light, color);
    
    if (d < length(lightPos - position)) diffuse *= 0.1;
 
    return  color * diffuse;
}
 
void main()
{
    vec2 viewPlane = (gl_FragCoord.xy-.5*u_resolution.xy)/u_resolution.y;
    vec3 camera = vec3(u_camera.x,  1, u_camera.z); 
    vec3 projection = normalize(vec3(viewPlane.x, viewPlane.y, 1));
    vec3 color = vec3(1,1,1);
    
    float distance = RayMarch(camera, projection, color); 
    vec3 ray = camera + projection * distance;

    vec3 light = GetLight(ray, color);
        
    gl_FragColor = vec4(light,1.0);
}