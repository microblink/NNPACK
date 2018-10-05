
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
endif()

set( CPUINFO_SOURCE_DIR     "${CMAKE_CURRENT_LIST_DIR}/cpuinfo"                           )
set( FP16_SOURCE_DIR        "${CMAKE_CURRENT_LIST_DIR}/fp16"                              )
set( FXDIV_SOURCE_DIR       "${CMAKE_CURRENT_LIST_DIR}/fxdiv"                             )
set( PSIMD_SOURCE_DIR       "${CMAKE_CURRENT_LIST_DIR}/psimd"                             )
set( PTHREADPOOL_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/pthreadpool"                       )
set( GOOGLETEST_SOURCE_DIR  "${CMAKE_CURRENT_LIST_DIR}/../../core-utils/GTest/googletest" )

if ( NOT WIN32 )
  # ...mrmlj... weird quick-fix attempts for weird find_package( Threads ) failures in cpuinfo CMakeLists.txt
  # https://stackoverflow.com/questions/40361522/cmake-failed-to-find-threads-package-with-cryptic-error-message
  # https://stackoverflow.com/questions/14171740/cmake-with-ios-toolchain-cant-find-threads
  enable_language( C )
  find_package( Threads )
  set( Threads_FOUND              TRUE      CACHE INTERNAL "" FORCE )
  set( CMAKE_THREAD_LIBS_INIT     "-DDUMMY" CACHE INTERNAL "" FORCE )
  set( CMAKE_USE_PTHREADS_INIT    1         CACHE INTERNAL "" FORCE )
  set( CMAKE_HAVE_THREADS_LIBRARY 1         CACHE INTERNAL "" FORCE )
endif()