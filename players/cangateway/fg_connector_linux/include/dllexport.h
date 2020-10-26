// Copyright (C) 2008,2009,2010 by Philipp Münzel. All rights reserved.
// Released under the terms of the license described in license.txt

#ifndef DLLEXPORT_H
#define DLLEXPORT_H
// @see http://gcc.gnu.org/wiki/Visibility
// @see http://people.redhat.com/drepper/dsohowto.pdf
// @see http://www.eventhelix.com/RealtimeMantra/HeaderFileIncludePatterns.htm

// Generic helper definitions for shared library support
#if defined(_WIN32) || defined(__CYGWIN__)
#    if defined(_MSC_VER)   // Windows && MS Visual C
#        if _MSC_VER < 1310    //Version < 7.1?
#            pragma message ("Compiling with a Visual C compiler version < 7.1 (2003) has not been tested!")
#        endif // Version > 7.1
#        define CANAERO_HELPER_DLL_IMPORT __declspec(dllimport)
#        define CANAERO_HELPER_DLL_EXPORT __declspec(dllexport)
#        define CANAERO_HELPER_DLL_LOCAL
#    elif defined (__GNUC__)
#        define CANAERO_HELPER_DLL_IMPORT __attribute__((dllimport))
#        define CANAERO_HELPER_DLL_EXPORT __attribute__((dllexport))
#        define CANAERO_HELPER_DLL_LOCAL
#    endif
#    define BOOST_ALL_NO_LIB  //disable the msvc automatic boost-lib selection in order to link against the static libs!
#elif defined(__linux__) || defined(linux) || defined(__linux) || defined(__APPLE__)
#    if __GNUC__ >= 4
#        define CANAERO_HELPER_DLL_IMPORT __attribute__ ((visibility("default")))
#        define CANAERO_HELPER_DLL_EXPORT __attribute__ ((visibility("default")))
#        define CANAERO_HELPER_DLL_LOCAL  __attribute__ ((visibility("hidden")))
#    else
#        define CANAERO_HELPER_DLL_IMPORT
#        define CANAERO_HELPER_DLL_EXPORT
#        define CANAERO_HELPER_DLL_LOCAL
#    endif
#endif

// Now we use the generic helper definitions above to define CANAERO_API and CANAERO_LOCAL.
// CANAERO_API is used for the public API symbols. It either DLL imports or DLL exports (or does nothing for static build)
// CANAERO_LOCAL is used for non-api symbols.


#ifdef CANAERO_DLL // defined if CANAERO is compiled as a DLL
#    ifdef CANAERO_DLL_EXPORTS // defined if we are building the CANAERO DLL (instead of using it)
#        define DLL_PUBLIC CANAERO_HELPER_DLL_EXPORT
#    else
#        define DLL_PUBLIC CANAERO_HELPER_DLL_IMPORT
#    endif // CANAERO_DLL_EXPORTS
#    define DLL_LOCAL CANAERO_HELPER_DLL_LOCAL
#else // CANAERO_DLL is not defined: this means CANAERO is a static lib.
#    define DLL_PUBLIC
#    define DLL_LOCAL
#endif // CANAERO_DLL



// disable some nasty MSVC Warnings
#ifdef _MSC_VER   // Windows && MS Visual C
#        pragma warning( disable : 4996 )     // disable deprecation warnings
#        pragma warning( disable : 4091 )    // disable typedef warning without variable declaration
#        pragma warning( disable : 4275 )    // non &#8211; DLL-interface classkey 'identifier' used as base for DLL-interface classkey 'identifier'
#        pragma warning( disable : 4251 )    // like warning above but for templates (like std::string)
#        pragma warning( disable : 4290 )    // exception handling of MSVC is lousy
#endif


#endif //DLLEXPORT_H
