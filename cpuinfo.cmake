
if ( NOT TARGET cpuinfo )
  set( CPUINFO_BUILD_TOOLS      OFF CACHE BOOL "" )
  set( CPUINFO_BUILD_UNIT_TESTS OFF CACHE BOOL "" )
  set( CPUINFO_BUILD_MOCK_TESTS OFF CACHE BOOL "" )
  set( CPUINFO_BUILD_BENCHMARKS OFF CACHE BOOL "" )
  if ( CMAKE_SYSTEM_PROCESSOR STREQUAL "armv7" ) #...mrmlj...quick fix for cpuinfo searching for an exact (but different) string
    set( CMAKE_SYSTEM_PROCESSOR          "armv7-a" )
    set( CMAKE_SYSTEM_PROCESSOR_ORIGINAL "armv7"   )
  endif()
  if ( iOS )
    set( CMAKE_SYSTEM_PROCESSOR_ORIGINAL ${CMAKE_SYSTEM_PROCESSOR} )
    unset( CMAKE_SYSTEM_PROCESSOR )
  endif()
  if ( NOT WIN32 ) # mrmlj copy-pasted from nnpack_pre.cmake
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
  add_subdirectory( "${CMAKE_CURRENT_LIST_DIR}/cpuinfo" "${CMAKE_CURRENT_BINARY_DIR}/cpuinfo" )
  if ( DEFINED CMAKE_SYSTEM_PROCESSOR_ORIGINAL )
    set( CMAKE_SYSTEM_PROCESSOR ${CMAKE_SYSTEM_PROCESSOR_ORIGINAL} )
  endif()
endif()
