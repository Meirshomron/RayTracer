#include "sceneParser.h"

glm::vec4 scene::parseVec4(const std::string& line) 
{
    unsigned int tokenLength = line.length();
    const char* tokenString = line.c_str();
    
    unsigned int vertIndexStart = 2;
    
    while(vertIndexStart < tokenLength)
    {
        if(tokenString[vertIndexStart] != ' ')
            break;
        vertIndexStart++;
    }
    
    unsigned int vertIndexEnd = FindNextChar(vertIndexStart, tokenString, tokenLength, ' ');
    
    float x = ParseFloatValue(line, vertIndexStart, vertIndexEnd);
    
    vertIndexStart = vertIndexEnd + 1;
    vertIndexEnd = FindNextChar(vertIndexStart, tokenString, tokenLength, ' ');
    
    float y = ParseFloatValue(line, vertIndexStart, vertIndexEnd);
    
    vertIndexStart = vertIndexEnd + 1;
    vertIndexEnd = FindNextChar(vertIndexStart, tokenString, tokenLength, ' ');
    
    float z = ParseFloatValue(line, vertIndexStart, vertIndexEnd);
    
	vertIndexStart = vertIndexEnd + 1;
    vertIndexEnd = FindNextChar(vertIndexStart, tokenString, tokenLength, ' ');
    
    float w = ParseFloatValue(line, vertIndexStart, vertIndexEnd);

    return glm::vec4(x,y,z,w);

    //glm::vec3(atof(tokens[1].c_str()), atof(tokens[2].c_str()), atof(tokens[3].c_str()))
}

void scene::loadtoShader(Shader &shader)
{
			shader.set_uniform4v(0,1,&eye);			
			shader.set_uniform4v(1,objects.size(),&objects[0]);
			shader.set_uniform4v(2,colors.size(),&colors[0]);
			shader.set_uniform4v(3,lights.size(),&lights[0]);
			shader.set_uniform4v(4,directions.size(),&directions[0]);
			shader.set_uniform4v(5,intensities.size(),&intensities[0]);
			shader.set_uniform4v(6,1,&ambient);
			shader.set_uniform3vi(7,1,sizes);
			//objects[1].x +=0.001;
}


scene::scene(const std::string& fileName)
{
	std::ifstream file;
    file.open((fileName).c_str());

    std::string line;
    if(file.is_open())
    {
        while(file.good())
        {
            getline(file, line);
        
            unsigned int lineLength = line.length();
            
            if(lineLength < 2)
                continue;
            
            const char* lineCStr = line.c_str();
            
            switch(lineCStr[0])
            {
			
                case 'e':
					eye = parseVec4(line);
				break;
				case 'a':
					ambient = parseVec4(line);
				break;
				case 'o':
					objects.push_back( parseVec4(line));
				break;
				case 'c':
					colors.push_back( parseVec4(line));
				break;
				case 'd':
					directions.push_back( parseVec4(line));
				break;
				case 'p':
					lights.push_back( parseVec4(line));
				break;
				case 'i':
					intensities.push_back( parseVec4(line));
				break;
				
			}
		}
		sizes =  glm::ivec3(objects.size(),directions.size(),1);
	}
	else
	{
		char buf[100];
		//std::cout<<"can not open file!"<<std::endl;
		strerror_s(buf,errno);
		std::cerr << "Error: " << buf; 
		sizes = glm::ivec3(0,0,0);
	}
	
}
