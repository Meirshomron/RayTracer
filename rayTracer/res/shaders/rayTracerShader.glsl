#version 130 

uniform vec4 eye;
uniform vec4 ambient;
uniform vec4[20] objects;
uniform vec4[20] objColors;
uniform vec4[10] lightsDirection;
uniform vec4[10] lightsIntensity;
uniform vec4[10] lightPosition;
uniform ivec3 sizes; //number of objects & number of lights

in vec3 position1;

// Once this flag is on, all planes are treated like mirrors.
bool mirrorActive = (eye.w == 0.0);

// The minimum value used to decide whether the result is positive or not. 
const float minThreshold = 0.0001;

// The max distance of an object from the eye / light source.
const float maxDistanceThreshold = 100000;

// The offset added to the mirror origin so we don't intersect ourselves.
const vec3 mirrorOffset = vec3(0.001);

// The specular intensity.
const float specularIntensity = 0.7;

// @tparam rayOrigin Ray origin. 
// @tparam rayDirection Ray direction
// @tparam planeNormal Plane normal.
// @tparam d Distance of the plane from the origin.
// @treturn Distance from rayOrigin to first intersecion with plane, or -1.0 if no intersection.
float calcRayToPlaneDistance(vec3 rayOrigin, vec3 rayDirection, vec3 planeNormal, float d)
 {
	planeNormal = normalize(planeNormal);
	rayDirection = normalize(rayDirection);

	float numerator = d + dot(rayOrigin, planeNormal);
	float denominator = dot(rayDirection, planeNormal);
	float distance = -numerator / denominator;

	if (distance > minThreshold)
	{
		return distance;
	}
	return -1.0;
}

// @tparam rayOrigin Ray origin. 
// @tparam rayDirection Ray direction
// @tparam sphereCenter Sphere center.
// @tparam sphereRadius Sphere radius.
// @treturn Distance from rayOrigin to first intersecion with sphere, or -1.0 if no intersection.
float calcRayToSphereDistance(vec3 rayOrigin, vec3 rayDirection, vec3 sphereCenter, float sphereRadius)
 {
    rayDirection = normalize(rayDirection);
    vec3 oc = rayOrigin - sphereCenter;
	float a = dot(rayDirection, rayDirection);
    float b = 2.0 * dot(rayDirection, oc);
    float c = dot(oc, oc) - (sphereRadius * sphereRadius);
	float discriminant = b * b - 4 * a * c;
	float numerator = -b - sqrt(discriminant);
	float denominator = 2.0 * a;

	// No intersection.
    if (discriminant < 0.0) 
    {
        return -1.0;
    }

	if ((numerator / denominator) > minThreshold)
	{	
		return (numerator / denominator);
	}
	else
	{
		numerator = -b + sqrt(discriminant);
		return (numerator / denominator);
	}  
}

// @tbrief Calculate the index of the object the first intersects the ray input.
// @tparam origin Ray origin.
// @tparam direction Ray direction.
// @treturn The distance and the index of the first object this ray intersects.
vec2 calcClosestObject(vec3 origin, vec3 direction)
{
	float distance = -1.0;
	int closestObjectIndex = -1;
	float minDistance = maxDistanceThreshold;

	for(int i = 0; i < sizes.x; i++)
	{
		bool isCurrentObjectPlane = (objects[i].w <= 0);

		// Calulate the distance accoridng to the object type.
		distance = isCurrentObjectPlane ? calcRayToPlaneDistance(origin, direction, objects[i].xyz, objects[i].w) : calcRayToSphereDistance(origin, direction, objects[i].xyz, objects[i].w);			

		if (distance < minDistance && distance > minThreshold)
		{
			minDistance = distance;
			closestObjectIndex = i;
		}	
	}

	return vec2(minDistance, closestObjectIndex);
}

// @tbrief Every plane is an infinite plane and will be divided to squares in checkers board pattern.
vec3 calcPlaneDesign(vec3 color, vec3 intersectPoint)
{
	// The seperate handling of every Quarter is for the squares in the borders not to combine to a rectangle.

	// Q1 (X and Y positive) and Q3 (X and Y negative).
	if (intersectPoint.x * intersectPoint.y > 0)
	{
		// Determine the size of every square.
		if (mod(int(1.5 * intersectPoint.x), 2) == mod(int(1.5 * intersectPoint.y), 2))
		{
			color *= 0.5;
		}				
	}
	// Q2 and Q4 (X and Y opposites).
	else
	{
		// Determine the size of every square.
		if (mod(int(1.5 * intersectPoint.x), 2) != mod(int(1.5 * intersectPoint.y), 2))
		{
			color *= 0.5;
		}
	}
	return color;
}

// @tbrief Calculate the ambient part of the light calculation.
// @tparam origin The origin of the ray.
// @tparam direction The direction of the ray.
// @treturn The color of the object first hit by this ray.
vec4 calcAmbient(vec3 origin, vec3 direction)
{
	vec2 result = calcClosestObject(origin, direction);
	int closestToOriginIndex = int(result.y);
	vec4 color = objColors[closestToOriginIndex];

	return color;
}

// @tbrief Calculate the diffuse part of the light calculation.
vec3 calcDiffuse(vec3 lightDirection, vec4 objectColor, vec3 objectNormal)
{
	vec3 kd = objectColor.xyz;
	vec3 diffuse = kd * max( dot(objectNormal, -lightDirection), 0.0);

	diffuse = clamp(diffuse, vec3(0.0), vec3(1.0));

	return diffuse;
}

// @tbrief specular the diffuse part of the light calculation.
vec3 calcSpecular(vec3 lightDirection, vec4 objectColor, vec3 objectNormal, vec3 intersectPoint, vec3 origin)
{
	vec3 Ks = vec3(specularIntensity);
	vec3 lightReflection = normalize(lightDirection - 2 * objectNormal * dot(lightDirection, objectNormal));
	vec3 ViewDirection = normalize(origin - intersectPoint);

	// The larger objectColor.w, the more dense and sharp the specular effect is.
	vec3 specular = Ks * max( pow( dot(ViewDirection, lightReflection), objectColor.w), 0);

	specular = clamp(specular, vec3(0.0), vec3(1.0));

	return specular;
}

// @tbrief Calculate the light for the given light source. Check calcLightSource() documentation for argument meanings.
vec4 calcLightDirection(int lightIdx, vec3 intersectPoint, vec3 direction, vec3 closestToOriginNormal, vec2 closestToOriginObj, bool isPlane, float maxDistanceLimit, vec3 origin, vec3 originDirection)
{
	vec4 color = vec4(0.0);

	// Calculate the diffuse.
	vec3 diffuse = calcDiffuse(direction, objColors[int(closestToOriginObj.y)], closestToOriginNormal);

	// Add diffuse plane pattern.
	diffuse = isPlane ? calcPlaneDesign(diffuse, intersectPoint) : diffuse;

	// Calculate the specular.
	vec3 specular = calcSpecular(direction, objColors[int(closestToOriginObj.y)], closestToOriginNormal, intersectPoint, origin);

	// Add the diffuse with specular and multiply by the light's intensity.
	color = (vec4(diffuse, 1.0) + vec4(specular, 1.0)) * lightsIntensity[lightIdx];			

	color = clamp(color, vec4(0.0), vec4(1.0));
	
	return color;
}

// @tbrief Calculate the reflection light for the given light source. Check calcLightSource() documentation for argument meanings.
vec4 calcLightReflection(int lightIdx, vec3 intersectPoint, vec3 direction, vec3 closestToOriginNormal, float maxDistanceLimit, vec3 originDirection)
{
	// Caclulate the reflection lighting.
	vec3 directionReflection = normalize(originDirection - 2 * closestToOriginNormal * dot(originDirection, closestToOriginNormal));
	vec3 mirrorOrigin = intersectPoint + mirrorOffset;

	// Caclulate intersection from the origin values.
	vec2 mirrorObj = calcClosestObject(mirrorOrigin, directionReflection);
	vec3 mirrorIntersectPoint = mirrorOrigin + (mirrorObj.x * directionReflection);
	int closestToMirrorIdx = int(mirrorObj.y);
	bool isMirrorIntersectPlane = (objects[closestToMirrorIdx].w <= 0);

	// If the reflection of this plane intersects a plane - return the color black.
	if (isMirrorIntersectPlane)
	{
		return vec4(0.0);
	}

	// Set the sphere calculation for the normal.
	vec3 closestToMirrorNormal = normalize(mirrorIntersectPoint - objects[closestToMirrorIdx].xyz);

	vec3 diffuse = calcDiffuse(directionReflection, objColors[closestToMirrorIdx], closestToMirrorNormal);
	vec3 specular = calcSpecular(directionReflection, objColors[closestToMirrorIdx], closestToMirrorNormal, mirrorIntersectPoint, mirrorOrigin);
	vec4 color = (vec4(diffuse, 1.0) + vec4(specular, 1.0)) * lightsIntensity[lightIdx];
	
	return color;
}

// @tbrief Calculate the diffuse and the specular of a single light source.
// @tparam lightIdx The specific light index in the array.
// @tparam intersectPoint The intersection point on the surface to calculate.
// @tparam direction The direction of this light source.
// @tparam closestToEyeNormal The normal of the intersectPoint.
// @tparam closestToEyeObj The surface with the intersectPoint.
// @tparam isPlane True if this surface is a plane.
// @tparam maxDistanceLimit The max distance we consider an object close enough to the intersectPoint to block the light. with directional light this value is the maxDistanceThreshold.
// @treturn The color produced by this light source.
vec4 calcLightSource(int lightIdx, vec3 intersectPoint, vec3 direction, vec3 closestToOriginNormal, vec2 closestToOriginObj, bool isPlane, float maxDistanceLimit, vec3 origin, vec3 originDirection)
{
	vec4 color = vec4(0.0);

	vec2 result = calcClosestObject(intersectPoint, -direction);

	// No object blocking this light source from the intersectPoint, or this object's father then the light's reach.
	if (result.y == -1 || result.x >= maxDistanceLimit)
	{	
		// Calucalte the reflection of the light on the plane that acts as a mirror. 
		if (mirrorActive && isPlane)
		{
			color = calcLightReflection(lightIdx, intersectPoint, direction, closestToOriginNormal, maxDistanceLimit, originDirection);
		}		
		// Calucalte the light on the intersected object. 
		else
		{
			color = calcLightDirection(lightIdx, intersectPoint, direction, closestToOriginNormal, closestToOriginObj, isPlane, maxDistanceLimit, origin, originDirection);
		}
	}
	return color;
}

// @tbrief Calculate the diffuse and the specular lighting of all the light sources.
vec4 calcLighting(vec3 origin, vec3 direction)
{
	vec4 color = vec4(0.0);
	vec3 lightDirection; 

	// Calc intersection from the origin values.
	vec2 closestToOriginObj = calcClosestObject(origin, direction);
	vec3 intersectionPoint = origin + (closestToOriginObj.x * direction);
	int closestToOriginIdx = int(closestToOriginObj.y);
	bool isPlane = (objects[closestToOriginIdx].w <= 0);

	// Set the normal according to the object type (sphere or plane).
	vec3 closestToOriginNormal = isPlane? -normalize(objects[closestToOriginIdx].xyz) : normalize(intersectionPoint - objects[closestToOriginIdx].xyz);

	// Iterate all light sources.
	for (int i = 0; i < sizes.y; i++)
	{
		bool isLightDirectional = (lightsDirection[i].w == 0.0);

		// Directinal light.
		if (isLightDirectional)				
		{
			lightDirection = normalize(lightsDirection[i].xyz);	
			color += calcLightSource(i, intersectionPoint, lightDirection, closestToOriginNormal, closestToOriginObj, isPlane, maxDistanceThreshold, origin, direction);
		}
		// Spot light.
		else
		{
			lightDirection = normalize(intersectionPoint - lightPosition[i].xyz);

			// Make sure that an object that is farther away from the intersectionPoint then the light position, can't be blocking.
			if (dot (lightDirection, normalize(lightsDirection[i].xyz)) > lightPosition[i].w)
			{
				float maxDistanceLimit = distance(intersectionPoint, lightPosition[i].xyz);
				color += calcLightSource(i, intersectionPoint, lightDirection, closestToOriginNormal, closestToOriginObj, isPlane, maxDistanceLimit, origin, direction);
			}
		}
	}
	return color;
}

// @tbrief Calculate the color at this position.
vec4 calcColor()
{
	vec3 origin = eye.xyz;
	vec3 direction = normalize(position1 - origin);

	// Default color calculation according to phong.
	vec4 color = ambient * calcAmbient(origin, direction) + calcLighting(origin, direction); 

	if (mirrorActive)
	{
		// Calculate the intersection point of the first object in this direction. 
		vec2 closestToOriginObj = calcClosestObject(origin, direction);
		int intersectionIdx = int(closestToOriginObj.y);
		bool isPlane = (objects[intersectionIdx].w <= 0);

		// Special color calculating for a plane in case the mirrorActive flag is on.
		if (isPlane)
		{
			// Calculate the reflection to this direction at the intersection point.
			vec3 intersectionPoint = origin + (closestToOriginObj.x * direction);
			vec3 normal = -normalize(objects[intersectionIdx].xyz);
			vec3 reflection = normalize(direction - 2 * normal * dot(direction, normal));

			// Add an mirrorOffset to the intersection point so we don't intersect ourselves when we calcuate rays from this new origin.
			vec3 mirrorOrigin = intersectionPoint + mirrorOffset;
			color = calcAmbient(mirrorOrigin, reflection) + calcLighting(origin, direction); 
		}
	}
    return color;
}

// @tbrief Main Entry function.
void main()
{  
	// The final pixel color is assigned to the reserved global variable.
	 gl_FragColor = calcColor();      
}
