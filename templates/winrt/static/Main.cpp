#include <stdbool.h>
#include <SDL_main.h>
#include <configs\winrt\SDL_config.h>
#include <hxcpp.h>
#include <wrl.h>

#ifdef main
#undef main
#endif

#ifndef SDL_WINRT_METADATA_FILE_AVAILABLE
#ifndef __cplusplus_winrt
#error Main.cpp must be compiled with /ZW, otherwise build errors due to missing .winmd files can occur.
#endif
#endif

#ifdef _MSC_VER
#pragma warning(disable:4447)
#endif

#ifdef _MSC_VER
#pragma comment(lib, "runtimeobject.lib")
#endif


#define DEBUG_PRINTF
#ifdef DEBUG_PRINTF
# ifdef UNICODE
#  define DLOG(fmt, ...) {wchar_t buf[1024];swprintf(buf,L"****LOG: %s(%d): %s \n    [" fmt "]\n",__FILE__,__LINE__,__FUNCTION__, __VA_ARGS__);OutputDebugString(buf);}
# else
#  define DLOG(fmt, ...) {char buf[1024];sprintf(buf,"****LOG: %s(%d): %s \n    [" fmt "]\n",__FILE__,__LINE__,__FUNCTION__, __VA_ARGS__);OutputDebugString(buf);}
# endif
#else
# define DLOG(fmt, ...) {}
#endif

//#ifndef INCLUDED_ApplicationMain
//#include <ApplicationMain.h>
//#endif

extern "C" void __hxcpp_lib_main() { }

extern "C" const char *hxRunLibrary ();
extern "C" void hxcpp_set_top_of_stack ();
//extern "C" int zlib_register_prims ();
extern "C" int lime_register_prims ();
::foreach ndlls::::if (registerStatics)::
extern "C" int ::nameSafe::_register_prims ();::end::::end::
										
int _main(int argc, char *argv[])
{
   HX_TOP_OF_STACK
//   hx::Boot();
   try
   {
//      __boot_all();
//      ::ApplicationMain_obj::main();
        hxcpp_set_top_of_stack ();
        
        //zlib_register_prims ();
        //lime_cairo_register_prims ();
        //lime_openal_register_prims ();
        ::foreach ndlls::::if (registerStatics)::
        ::nameSafe::_register_prims ();::end::::end::
        
          const char *err = NULL;
          err = hxRunLibrary ();
          
          if (err) {
            
            DLOG("Error: %s\n", err);
            
          }

   }
   catch (Dynamic e)
   {
    DLOG("Error: %s\n", err);
//      __hx_dump_stack();
      return -1;
   }
   return 0;
}

int CALLBACK WinMain(HINSTANCE, HINSTANCE, LPSTR, int)
{ 

  if (FAILED(Windows::DC::Foundation::DC::Initialize(RO_INIT_MULTITHREADED))) 
  {
      DLOG("ERROR: Main.cpp can't initialize ");
      return 1;
  } 
  DLOG("HELLO WORLD");
    Sleep(20000);
    DLOG("HELLO WORLD");

    SDL_WinRTRunApp(_main, NULL);
  return 0;
}

