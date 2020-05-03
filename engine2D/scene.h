#include <glm\glm.hpp>
#include <vector>

using namespace glm;

class scene
{
private:
	vec4 eye;         //position + shine
	vec4 ambient;
	ivec3 sizes;
	std::vector<vec4> objects;      //center coordinates + radius / normal + d
	std::vector<vec4> lights;        //position + cos(angle)
	std::vector<vec4> directions;     //direction +  is directional 0.0/1.0
	std::vector<vec4> colors ;
	std::vector<vec4> intensities;		   //light intensity
public:
	void update(const std::string& fileName,int component);
	void update(vec4 value, int component);

};