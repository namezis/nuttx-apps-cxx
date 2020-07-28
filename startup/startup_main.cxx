//***************************************************************************
//
//   Copyright (C) 2009, 2011-2013, 2017 Gregory Nutt. All rights reserved.
//   Author: Gregory Nutt <gnutt@nuttx.org>
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
// 3. Neither the name NuttX nor the names of its contributors may be
//    used to endorse or promote products derived from this software
//    without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
// OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
// AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
// ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
//***************************************************************************

//***************************************************************************
// Included Files
//***************************************************************************

#include <nuttx/config.h>

#include <cstdio>
#include <debug.h>
#include <unistd.h>

#include <nuttx/arch.h>

#include <array>
#include <vector>
#include <algorithm>
#include <thread>
#include <string>

#include "func.h"

//***************************************************************************
// Definitions
//***************************************************************************
// Configuration ************************************************************

// Debug ********************************************************************
// Non-standard debug that may be enabled just for testing the constructors

#ifndef CONFIG_DEBUG_FEATURES
#  undef CONFIG_DEBUG_CXX
#endif

#ifdef CONFIG_DEBUG_CXX
#  define cxxinfo     _info
#else
#  define cxxinfo(x...)
#endif

//***************************************************************************
// Private Classes
//***************************************************************************

class CHelloWorld
{
  public:
    CHelloWorld(void) : mSecret(42)
    {

        std::array<uint8_t, 10> test = {5, 4, 3, 2, 1, 6, 7, 8, 9, 0};

        for (const auto& i: test)
        {
             printf("%i=", i);
//             std::cout << i;
        }
        printf("\n");

        std::vector<char> vec{'h','e','l','l','o',' ','w','o','r','l', 'd', '\n'};
//        std::for_each(vec.begin(), vec.end(), [](char c){std::cout << c;});
        std::for_each(vec.begin(), vec.end(), [](char c){ printf("%c-",c); });
        printf("\n");

//      cxxinfo("Constructor: mSecret=%d\n", mSecret);
//        std::ostringstream oss;
//        oss << "Hello World! " << mSecret << "\n";
//        std::cout << oss.str();
        printf("Hello World! %i\n", mSecret);
    }

    ~CHelloWorld(void)
    {
      cxxinfo("Destructor\n");
    }

    bool HelloWorld(void)
    {
        cxxinfo("HelloWorld: mSecret=%d\n", mSecret);

        if (mSecret != 42)
          {
            printf("CHelloWorld::HelloWorld: CONSTRUCTION FAILED!\n");
            return false;
          }
        else
          {
            printf("CHelloWorld::HelloWorld: Hello, World!!\n");
            return true;
          }
    }

  private:
    int mSecret;
};

//***************************************************************************
// Private Data
//***************************************************************************

// Define a statically constructed CHellowWorld instance if C++ static
// initializers are supported by the platform

#ifdef CONFIG_HAVE_CXXINITIALIZE
static CHelloWorld g_HelloWorld;
#endif

//***************************************************************************
// Public Functions
//***************************************************************************

void task1(std::string msg)
{
  for (int i=0; i<3; i++)
  {
    printf("%s\n", msg.c_str());
    usleep(3 * 1000 * 1000);
  }
}

/****************************************************************************
 * Name: helloxx_main
 ****************************************************************************/

extern "C"
{
  int main(int argc, FAR char *argv[])
 {
    // Exercise an explicitly instantiated C++ object

    func1();

    CHelloWorld *pHelloWorld = new CHelloWorld;
    printf("helloxx_main: Saying hello from the dynamically constructed instance\n");
    pHelloWorld->HelloWorld();

    // Exercise an C++ object instantiated on the stack

    CHelloWorld HelloWorld;

    printf("helloxx_main: Saying hello from the instance constructed on the stack\n");
    HelloWorld.HelloWorld();

    // Exercise an statically constructed C++ object

#ifdef CONFIG_HAVE_CXXINITIALIZE
    printf("helloxx_main: Saying hello from the statically constructed instance\n");
    g_HelloWorld.HelloWorld();
#endif

    std::thread t1(task1, "Hello from thread1");
    std::thread t2(task1, "Hello from thread2");
    t1.join();
    t2.join();

    delete pHelloWorld;

    printf("helloxx_main: finished\n");
    return 0;
  }
}
