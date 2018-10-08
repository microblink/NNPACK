
if ( WIN32 )
  set( NNPACK_USE_MB_DISPATCH ON )
else()
  option( NNPACK_USE_MB_DISPATCH "Make NNPACK use mb::sweat_shop for parallel jobs" ON )
endif()

set( NNPACK_CONVOLUTION_ONLY  ON                        CACHE BOOL     ""       )
set( NNPACK_INFERENCE_ONLY    ON                        CACHE BOOL     ""       )
set( NNPACK_CUSTOM_THREADPOOL ${NNPACK_USE_MB_DISPATCH} CACHE INTERNAL "" FORCE )
set( NNPACK_LIBRARY_TYPE      static                    CACHE STRING   ""       )
set( NNPACK_BUILD_TESTS       OFF                       CACHE BOOL     ""       )

if ( iOS )
  unset( CMAKE_SYSTEM_PROCESSOR )
elseif ( CMAKE_SYSTEM_PROCESSOR STREQUAL "armv7" ) #...mrmlj...quick fix for nnpack searching for an exact (but different) string
    set( CMAKE_SYSTEM_PROCESSOR          "armv7-a" )
    set( CMAKE_SYSTEM_PROCESSOR_ORIGINAL "armv7"   )
endif()

set( CPUINFO_SOURCE_DIR     "${CMAKE_CURRENT_LIST_DIR}/cpuinfo"                           )
set( FP16_SOURCE_DIR        "${CMAKE_CURRENT_LIST_DIR}/fp16"                              )
set( FXDIV_SOURCE_DIR       "${CMAKE_CURRENT_LIST_DIR}/fxdiv"                             )
set( PSIMD_SOURCE_DIR       "${CMAKE_CURRENT_LIST_DIR}/psimd"                             )
set( PTHREADPOOL_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/pthreadpool"                       )
set( GOOGLETEST_SOURCE_DIR  "${CMAKE_CURRENT_LIST_DIR}/../../core-utils/GTest/googletest" )

include( cpuinfo.cmake )