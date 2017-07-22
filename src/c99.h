#pragma once

#if defined( _MSC_VER ) && !defined( __clang__ )
    #define C99( expr )
    #define C99_FLOAT( hex, decimal ) decimal
    #define restrict /*...mrmlj...messes with __declspec(restrict)...__restrict*/
#else
    #define C99( expr ) expr
    #define C99_FLOAT( hex, decimal ) hex
#endif // _MSC_VER