#pragma once

#ifndef _MSC_VER
    #define C99( expr ) expr
    #define C99_FLOAT( hex, decimal ) hex
#else
    #define C99( expr )
    #define C99_FLOAT( hex, decimal ) decimal
    #define restrict /*...mrmlj...messes with __declspec(restrict)...__restrict*/
#endif // _MSC_VER