#version 300 es


precision highp float; 
out vec4 outColor;

#include "functions.glsl"

uniform vec2 u_resolution;  // Width and height of the shader
uniform float u_time;  // Time elapsed
uniform vec3 u_camera;
uniform float smoothFactor;
 
// Constants 
#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURFACE_DIST 0.01

vec3 lightPos = vec3(5.0, 5.0, 5.0);
vec3 ambientLight = vec3(1.0, 0.3686, 0.3686);
vec3 lightColor = vec3(1.0, 1.0, 1.0);

SO items[8];


void sceneDefinition()
{    
    items[0] = SO(SO_SPHERE, vec3(0,2,3), vec3(0.75, 1,1), vec3(0.7686, 0.7608, 0.5098));
    items[1] = SO(SO_GOOP, vec3(.0, 5.0, 3) , vec3(0.5, 1,1), vec3(0.9804, 0.3922, 0.0));
    items[2] = SO(SO_SIN_STRING, vec3(0, 0, 3) , vec3(0.5, 0.1, 0.1), vec3(1.0, 0.7333, 0.0));
    
}
 
float getDistance(vec3 rayPos, SO item)
{
    return (item.type == SO_SPHERE) 
                ? sphereSdf(rayPos, item, u_time) 
            : (item.type == SO_BOX)
                ? boxSdf(rayPos, item, u_time) 
            : (item.type == SO_GOOP)
                ? goopSdf(rayPos, item, u_time) 
            : (item.type == SO_SIN_STRING)
                ? sinStringSdf(rayPos, item, u_time) 
            : MAX_DIST;
} 
 
void main()
{
    sceneDefinition();

    vec2 uv = (gl_FragCoord.xy - u_resolution.xy * 0.5) / u_resolution.y;
    vec3 cameraPos =  vec3(u_camera.x, 2, u_camera.z - 5.0);
    vec3 rayDir  = normalize(vec3(uv.x, uv.y, 1));
 
    float dist = 0.0;
    vec3 lightPos = vec3(5.0, 4.0, -1.0);
    vec3 ambientLight = vec3(0.4667, 0.4275, 0.4275);
    vec3 lightColor = vec3(0.8235, 0.8549, 0.5647);
    vec3 surfaceColor = vec3(0.5922, 0.5922, 0.5922);
    
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 rayPos = cameraPos + dist * rayDir;
        float closestDist = 100.0;
        int closestItem = -1;
        for (int j = 0; j < items.length(); j++) {
                       
            float itemDist = getDistance(rayPos, items[j]);
            if (itemDist < closestDist) {
                closestDist = itemDist;                
            }
             
            if (closestDist < SURFACE_DIST)
            {
                closestItem = j;
                break;
            }            
        }
        if (closestItem != -1) {
            vec3 hitPos = rayPos + closestDist * rayDir;
            vec3 normal = normalize(hitPos - items[closestItem].position);
            float diffuse = max(dot(normal, normalize(lightPos - hitPos)), 0.0);
            surfaceColor = items[closestItem].color * (ambientLight + diffuse * lightColor);
            break;
        }
        dist += closestDist;    
        if (dist > MAX_DIST) {
            break;
        }
    }
    
    outColor = vec4(surfaceColor, 1.0);
}