#ifndef DEBUGTIMER_H_INCLUDED
#define DEBUGTIMER_H_INCLUDED

#include <GLFW\glfw3.h>
#include <iostream>
#include <string>

class DebugTimer
{
public:
    void Start()
    {
        startTime = glfwGetTimerValue();
    }
    
    void End(const std::string& message)
    {
        unsigned int endTime = glfwGetTimerValue();
        std::cout << message << (endTime - startTime) << "ms" << std::endl;
    }

	unsigned int GetTime()
	{
		unsigned int endTime = glfwGetTimerValue();
        return (endTime - startTime);
	}
    
protected:
private:
    unsigned int startTime;
};

#endif // DEBUGTIMER_H_INCLUDED
