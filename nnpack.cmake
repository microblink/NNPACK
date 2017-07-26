
set( nnpack_source ${CMAKE_CURRENT_LIST_DIR} )
set( nnpack_interface_includes "${nnpack_source}/include" "${nnpack_source}/pthreadpool/include" )

if ( WIN32 )
  set( NNPACK_USE_MB_DISPATCH true )
else()
  option( NNPACK_USE_MB_DISPATCH "Make NNPACK use mb::sweat_shop for parallel jobs" true )
endif()

if ( MSVC AND NOT NNPACK_IN_MSVC_SUBPROJECT )
  set( nnpack_binary_dir "${CMAKE_CURRENT_BINARY_DIR}/nnpack" )
  execute_process( COMMAND "${CMAKE_COMMAND}" -E make_directory "${nnpack_binary_dir}" )
  execute_process(
    COMMAND "${CMAKE_COMMAND}"
      -G ${CMAKE_GENERATOR}
      -T v141_clang_c2
      -DNNPACK_IN_MSVC_SUBPROJECT:BOOL=true
      -DMB_GLOBAL_ENABLE_TIMER:BOOL=false
      ${CMAKE_CURRENT_LIST_DIR}
    WORKING_DIRECTORY "${nnpack_binary_dir}"
    ERROR_VARIABLE    stderr
    OUTPUT_VARIABLE   stdout
  )
  message( STATUS ${stdout} )
  if ( stderr )
    message( FATAL_ERROR "NNPACK project creation failure:\n${stderr}" )
  endif()
  include_external_msproject( NNPACK "${nnpack_binary_dir}/NNPACK.vcxproj" )
  return()
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
if( NOT NNPACK_USE_MB_DISPATCH )
  set( pthread_pool_sources "${nnpack_source}/pthreadpool/src/threadpool-pthreads.c" )
endif()
list( APPEND nnpack_sources ${nnpack_common_headers} ${nnpack_common_sources} ${nnpack_scalar_sources} ${pthread_pool_sources} )
if ( ANDROID )
  if ( ANDROID_ABI MATCHES "arm" )
    list( APPEND nnpack_sources ${nnpack_neon_sources} ${nnpack_psimd_sources} )
  elseif( ANDROID_ABI MATCHES "x86" )
    # no Android ABI or version guarantees AVX2 required by the x86 NNPACK backend
    list( APPEND nnpack_sources ${nnpack_psimd_sources} )
  endif()
elseif ( iOS )
  list( APPEND nnpack_sources ${nnpack_neon_sources} ${nnpack_psimd_sources} )
elseif( MSVC AND CMAKE_CXX_COMPILER_ID STREQUAL Clang )
  # neither x86 nor PSIMD backends work (see later comments for more info)
else()
  list( APPEND nnpack_sources ${nnpack_psimd_sources} ) # ${nnpack_x86_sources} don't want to run PeachPy or require AVX2
  set( nnpack_explicit_backend PSIMD )
endif()
#set_source_files_properties( ${nnpack_sources} PROPERTIES LANGUAGE CXX )
build_static_library( NNPACK ${nnpack_source} ${nnpack_sources} )
target_include_directories( NNPACK PUBLIC  ${nnpack_interface_includes}   )
target_include_directories( NNPACK PRIVATE ${nnpack_source}/src           )
target_include_directories( NNPACK PRIVATE ${nnpack_source}/src/ref       )
target_include_directories( NNPACK PRIVATE ${nnpack_source}/fp16/include  )
target_include_directories( NNPACK PRIVATE ${nnpack_source}/FXdiv/include )
target_include_directories( NNPACK PRIVATE ${nnpack_source}/psimd/include )

if ( DEFINED nnpack_explicit_backend )
  target_compile_definitions( NNPACK PRIVATE NNP_BACKEND_${nnpack_explicit_backend}=1 )
endif()

force_include_header( NNPACK "${nnpack_source}/src/c99.h" )
if ( CMAKE_CXX_COMPILER_ID STREQUAL MSVC )
  set_source_files_properties( ${nnpack_sources} PROPERTIES LANGUAGE CXX )
  target_compile_options( NNPACK PRIVATE /WX- )
else()
  target_compile_options( NNPACK PRIVATE -Wno-error )
endif()

if ( WIN32 )
  target_compile_definitions( NNPACK PRIVATE
    NOMINMAX __STDC__ # minmax macros
    # __GNUC__ # for psimd.h
    # NNP_BACKEND_PSIMD=1 # '_mm256_blendv_ps': Intrinsic not yet implemented (in MSVC14.1u2+Clang 3.8)
    NNP_BACKEND_SCALAR=1 # nnpack\psimd\include\psimd.h(616): fatal error C1001: An internal error has occurred in the compiler (MSVC14.1u2)
  )
  target_compile_options( NNPACK PRIVATE -std=gnu11 -g2 -gdwarf-2 -mavx -ffast-math -fno-pic -fno-rtti -fno-exceptions $<$<CONFIG:RELEASE>:-O3 -fno-stack-protector> ) # -flto "fatal error LNK1136: invalid or corrupt file"
elseif( ANDROID )
  if ( ANDROID_ABI STREQUAL "armeabi-v7a" )
    target_compile_options( NNPACK PRIVATE -mfpu=neon-fp16 )
    target_link_libraries( NNPACK PUBLIC cpufeatures )
  endif()
elseif( iOS )
  string( REPLACE ";" " " neon_source_files "${nnpack_neon_sources}" )
  set_target_properties( NNPACK PROPERTIES
    XCODE_ATTRIBUTE_OTHER_CFLAGS[arch=armv7] "$(OTHER_CFLAGS) -mfpu=neon-fp16"
    XCODE_ATTRIBUTE_OTHER_CFLAGS[arch=armv7s] "$(OTHER_CFLAGS) -mfpu=neon-fp16"
    XCODE_ATTRIBUTE_EXCLUDED_SOURCE_FILE_NAMES[sdk=iphonesimulator*] "${neon_source_files}" # those sources fail to build for simulator
    XCODE_ATTRIBUTE_GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*] "NNP_BACKEND_PSIMD" # don't use AVX2 on iOS simulator
  )
endif()
