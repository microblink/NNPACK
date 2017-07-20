
set( nnpack_source ${CMAKE_CURRENT_LIST_DIR} )
set( nnpack_interface_includes "${nnpack_source}/include" "${nnpack_source}/pthreadpool/include" )

if ( MSVC AND NOT NNPACK_IN_MSVC_SUBPROJECT )
  set( binary_dir "${CMAKE_BINARY_DIR}/nnpack" )
  execute_process( COMMAND "${CMAKE_COMMAND}" -E make_directory "${binary_dir}" )
  execute_process(
    COMMAND "${CMAKE_COMMAND}"
      -T v141_clang_c2
      -DNNPACK_IN_MSVC_SUBPROJECT:BOOL=true
      -DNNPACK_USE_MB_DISPATCH:BOOL=true
      -DMB_GLOBAL_ENABLE_TIMER:BOOL=false
      ${CMAKE_CURRENT_LIST_DIR}
    WORKING_DIRECTORY "${binary_dir}"
    ERROR_VARIABLE    stderr
    OUTPUT_VARIABLE   stdout
  )
  message( STATUS ${stdout} )
  if ( stderr )
    message( FATAL_ERROR "NNPACK project creation failure:\n${stderr}" )
  endif()
  include_external_msproject( NNPACK ${binary_dir}/NNPACK.vcxproj )
  return()
endif()

if ( NOT WIN32 )
  option( NNPACK_USE_MB_DISPATCH "Make NNPACK use mb::sweat_shop for parallel jobs" true )
endif()

#include( "${CMAKE_CURRENT_LIST_DIR}/../../core-utils/cmake-build/common_settings.cmake" )
include( "${CMAKE_CURRENT_LIST_DIR}/../../core-utils/cmake-build/common_utils.cmake"    )

#file( GLOB_RECURSE nnpack_sources "${nnpack_source}/src/*.c" )
file( GLOB_RECURSE nnpack_common_headers "${nnpack_source}/include/*.h"        )
file( GLOB         nnpack_common_sources "${nnpack_source}/src/*.c"            )
file( GLOB_RECURSE nnpack_neon_sources   "${nnpack_source}/src/neon/*.c"       )
file( GLOB_RECURSE nnpack_psimd_sources  "${nnpack_source}/src/psimd/*.c"      )
file( GLOB_RECURSE nnpack_ref_sources    "${nnpack_source}/src/ref/*.c"        )
file( GLOB_RECURSE nnpack_scalar_sources "${nnpack_source}/src/scalar/*.c"     )
file( GLOB_RECURSE nnpack_x86_sources    "${nnpack_source}/src/x86_64-fma/*.c" )
source_group( "Headers" FILES ${nnpack_common_headers} )
if( NNPACK_USE_MB_DISPATCH )
  set_source_files_properties( ${SRC_PATH}/pthreadpoolImpl.cpp PROPERTIES COMPILE_FLAGS "-DNN_NNPACK_USE_SWEATER=1" )
else()
  set( pthread_pool_sources "${nnpack_source}/pthreadpool/src/threadpool-pthreads.c" )
endif()
list( APPEND nnpack_sources ${nnpack_common_headers} ${nnpack_common_sources} ${nnpack_scalar_sources} ${pthread_pool_sources} )
if ( ANDROID OR iOS )
  list( APPEND nnpack_sources ${nnpack_neon_sources} ${nnpack_psimd_sources} )
elseif( MSVC AND CMAKE_CXX_COMPILER_ID STREQUAL Clang )
  # neither x86 nor PSIMD backends work (see later comments for more info)
else()
  list( APPEND nnpack_sources ${nnpack_x86_sources} )
endif()
#set_source_files_properties( ${nnpack_sources} PROPERTIES LANGUAGE CXX )
build_static_library( NNPACK ${nnpack_source} ${nnpack_sources} )
target_include_directories( NNPACK PUBLIC ${nnpack_interface_includes} )
target_include_directories( NNPACK PRIVATE ${nnpack_source}/src           )
target_include_directories( NNPACK PRIVATE ${nnpack_source}/src/ref       )
target_include_directories( NNPACK PRIVATE ${nnpack_source}/fp16/include  )
target_include_directories( NNPACK PRIVATE ${nnpack_source}/FXdiv/include )
target_include_directories( NNPACK PRIVATE ${nnpack_source}/psimd/include )

force_include_header( NNPACK "${nnpack_source}/src/c99.h" )
if ( CMAKE_CXX_COMPILER_ID STREQUAL MSVC )
  set_source_files_properties( ${nnpack_sources} PROPERTIES LANGUAGE CXX )
  target_compile_options( NNPACK PRIVATE /WX- )
else()
  target_compile_options( NNPACK PRIVATE -Wno-error )
endif()

if ( WIN32 )
  target_compile_options( NNPACK PRIVATE
    -DNOMINMAX -D__STDC__ # minmax macros
    # -D__GNUC__ # for psimd.h
    # -DNNP_BACKEND_PSIMD=1 # '_mm256_blendv_ps': Intrinsic not yet implemented (in MSVC14.1u2+Clang 3.8)
    -DNNP_BACKEND_SCALAR=1 # nnpack\psimd\include\psimd.h(616): fatal error C1001: An internal error has occurred in the compiler (MSVC14.1u2)
  )
endif()
