
include( ${CMAKE_CURRENT_LIST_DIR}/../../core-utils/CoreUtils/CoreUtils.cmake )

target_compile_definitions( nnpack PRIVATE NNP_DISABLE_HALF_PRECISION=1 )
if( NOT MSVC )
    target_compile_options( nnpack PRIVATE ${TNUN_compiler_fastmath} )
    # Workaround for PCH not supporting multiple elements inside generator expression
    foreach( flag ${TNUN_compiler_optimize_for_speed} )
        target_compile_options( nnpack PRIVATE $<$<CONFIG:RELEASE>:${flag}> )
    endforeach()
endif()

# silence NNPack warnings (noone is going to fix them anyway)
target_compile_options( nnpack PRIVATE "-w" )
if ( CMAKE_CXX_COMPILER_ID STREQUAL MSVC )
  set_source_files_properties( ${nnpack_sources} PROPERTIES LANGUAGE CXX )
  target_compile_options( nnpack PRIVATE /WX- )
else()
  target_compile_options( nnpack PRIVATE -Wno-error )
endif()

if( iOS )
  set_target_properties( nnpack PROPERTIES
    XCODE_ATTRIBUTE_OTHER_CFLAGS[arch=armv7]  "$(OTHER_CFLAGS) -mfpu=neon-fp16"
    XCODE_ATTRIBUTE_OTHER_CFLAGS[arch=armv7s] "$(OTHER_CFLAGS) -mfpu=neon-fp16"
    XCODE_ATTRIBUTE_GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*] "NNP_BACKEND_PSIMD" # don't use AVX2 on iOS simulator
  )

  enable_language( ASM )
  add_library( nnpack_asm src/neon/blas/h4gemm-aarch32.S src/neon/blas/s4gemm-aarch32.S src/neon/blas/sgemm-aarch32.S )
  set_source_files_properties( src/neon/blas/h4gemm-aarch32.S PROPERTIES COMPILE_FLAGS "-mfpu=neon-vfpv4" )
  set_source_files_properties( src/neon/blas/s4gemm-aarch32.S PROPERTIES COMPILE_FLAGS "-mfpu=neon-vfpv4" )
  target_include_directories( nnpack_asm PRIVATE include )
  target_link_libraries( nnpack PUBLIC nnpack_asm )
endif()
