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

Sphere spheres[7];


void sceneDefinition()
{
    float goopTime = u_time * 0.5;
    spheres[0] = Sphere(vec3(0,2,3), 0.75, vec3(0.7686, 0.7608, 0.5098));
    spheres[1] = Sphere(vec3(1.0* sin(4.0 - goopTime), 2.0+1.0* cos(4.0 - goopTime), 3) , 0.5, vec3(0.7176, 0.9412, 0.2));
    spheres[2] = Sphere(vec3(1.0* sin(4.0 + goopTime), 2.0+1.0* cos(4.0 + goopTime), 3) , 0.5, vec3(0.2, 0.7686, 0.9412));
    spheres[3] = Sphere(vec3(1.0* sin(2.0 - goopTime), 2.0+1.0* cos(2.0 - goopTime), 3) , 0.5, vec3(0.902, 0.0392, 0.6118));
    spheres[4] = Sphere(vec3(1.0* sin(2.0 + goopTime), 2.0+1.0* cos(2.0 + goopTime), 3) , 0.5, vec3(0.9804, 0.3922, 0.0));
    spheres[5] = Sphere(vec3(1.0* sin(6.0 + goopTime), 2.0+1.0* cos(6.0 + goopTime), 3) , 0.5, vec3(0.9412, 0.2, 0.2));
    spheres[6] = Sphere(vec3(1.0* sin(6.0 - goopTime), 2.0+1.0* cos(6.0 - goopTime), 3) , 0.5, vec3(0.2863, 0.0118, 0.6471));
    
}
 
 
void main()
{
    sceneDefinition();

    vec2 uv = (gl_FragCoord.xy - u_resolution.xy * 0.5) / u_resolution.y;
    vec3 cameraPos =  vec3(u_camera.x, 2, u_camera.z - 5.0);
    vec3 rayDir  = normalize(vec3(uv.x, uv.y, 1));
 
    float dist = 0.0;
    vec3 lightPos = vec3(5.0, 4.0, -1.0);
    vec3 ambientLight = vec3(0.1608, 0.149, 0.149);
    vec3 lightColor = vec3(0.8235, 0.8549, 0.5647);
    vec3 surfaceColor = vec3(0.9608, 1.0, 0.4235);
    
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 rayPos = cameraPos + dist * rayDir;
        float closestDist = 100000.0;
        int closestSphere = -1;
        for (int j = 0; j < spheres.length(); j++) {
            float sphereDist = sphereSDF(rayPos, spheres[j]);
            if (sphereDist < closestDist) {
                closestDist = sphereDist;                
            }
             
            if (closestDist < SURFACE_DIST)
            {
                closestSphere = j;
                break;
            }            
        }
        if (closestSphere != -1) {
            vec3 hitPos = rayPos + closestDist * rayDir;
            vec3 normal = normalize(hitPos - spheres[closestSphere].position);
            float diffuse = max(dot(normal, normalize(lightPos - hitPos)), 0.0);
            surfaceColor = spheres[closestSphere].color * (ambientLight + diffuse * lightColor);
            break;
        }
        dist += closestDist;    
        if (dist > MAX_DIST) {
            break;
        }
    }
    
    outColor = vec4(surfaceColor, 1.0);
}