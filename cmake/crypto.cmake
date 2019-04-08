cmake_minimum_required( VERSION 3.8.0 )
# kudos to https://github.com/madwax/3ndparty.cmake.openssl/

include( CMakeParseArguments )
project( crypto )

set( TARGET_SOURCE_DIR_TRUE "${OpenSSL_SOURCE_PATH}/crypto" )
set( TARGET_INCLUDE_DIRS ${OpenSLL_INCLUDE_PATH} )
set( TARGET_INCLUDE_DIRS_PRIVATE "${TARGET_SOURCE_DIR_TRUE}" "${TARGET_SOURCE_DIR_TRUE}/asn1" "${TARGET_SOURCE_DIR_TRUE}/evp" "${TARGET_SOURCE_DIR_TRUE}/modes")
set( TARGET_DEFINES "OPENSSL_THREADS" )
set( TARGET_DEFINES_PRIVATE "${OpenSSL_COMPILER_DEFINES}" )
set( TARGET_COMPILE_FLAGS_PRIVATE -ffunction-sections -fdata-sections)
set( TARGET_LINK "" )
set( TARGET_LINK_PRIVATE "" )
set( TARGET_SOURCES "" )

# Because OpenSSL does silly things we have to create a proper include dir to build everything
file( COPY ${OpenSSL_SOURCE_PATH}/e_os.h DESTINATION ${OpenSLL_INCLUDE_PATH}/ )
file( COPY ${OpenSSL_SOURCE_PATH}/e_os2.h DESTINATION ${OpenSLL_INCLUDE_PATH}/openssl/ )

# we hold the sources (.c) under XSRC and headers (.h) under XINC
# we do this as we need to copy headers else the lib will not build.
set( XSRC "" )
set( XINC "" )
set( XSRC_SHARED "")

# OpenSSL Has a lot of source files so we separated it.
include( crypto_sources )

file( COPY ${XINC} DESTINATION ${OpenSLL_INCLUDE_PATH}/openssl FILES_MATCHING REGEX "\.h$" )
file( COPY ${TARGET_SOURCE_DIR_TRUE}/opensslconf.h.in DESTINATION ${OpenSLL_INCLUDE_PATH}/openssl )

if(WIN32)
    # TODO: Replicate build flags for cl
    # Flags taken from OpenSSL Configure file for VC-WIN64A target.  More care may be required for other targets.
    set(TARGET_COMPILE_FLAGS -O1 -W3 -Gs0 -Gy -nologo -DOPENSSL_SYSNAME_WIN32 -DWIN32_LEAN_AND_MEAN -DL_ENDIAN -DUNICODE -D_UNICODE)
else()
    set( TARGET_COMPILE_FLAGS -fno-rtti -fno-stack-protector -O1 -fno-unwind-tables -fno-asynchronous-unwind-tables
        -fno-math-errno -fno-unroll-loops -fmerge-all-constants)
endif()

file( READ "${OpenSLL_INCLUDE_PATH}/openssl/opensslconf.h.in" CONF )
set( CONF "
#define OPENSSL_NO_GMP
#define OPENSSL_NO_JPAKE
#define OPENSSL_NO_KRB5
#define OPENSSL_NO_MD2
#define OPENSSL_NO_RFC3779
#define OPENSSL_NO_STORE
#define OPENSSL_NO_DYNAMIC_ENGINE
#define OPENSSL_NO_SCTP
#define OPENSSL_NO_EC_NISTP_64_GCC_128
#define OPENSSL_NO_CAMELLIA
#define OPENSSL_NO_RIPEMD
#define OPENSSL_NO_RC5
#define OPENSSL_NO_BF
#define OPENSSL_NO_IDEA
#define OPENSSL_NO_ENGINE
#define OPENSSL_NO_DES
#define OPENSSL_NO_MDC2
#define OPENSSL_NO_SEED
#define OPENSSL_NO_DEPRECATED
#define OPENSSL_NO_DSA
#define OPENSSL_NO_DH
#define OPENSSL_NO_EC
#define OPENSSL_NO_ECDSA
#define OPENSSL_NO_ECDH
#define OPENSSL_NO_WHIRLPOOL
#define OPENSSL_NO_RC4
#define OPENSSL_NO_RC2
#define OPENSSL_NO_SSL2
#define OPENSSL_NO_SSL3
#define OPENSSL_NO_CAST
#define OPENSSL_NO_CMAC
#define OPENSSL_NO_ZLIB
#define OPENSSL_NO_DGRAM
#define OPENSSL_NO_SOCK
#define OPENSSL_NO_BF
#define OPENSSL_NO_MD4
#define OPENSSL_NO_CMS
#define OPENSSL_NO_OCSP
#define OPENSSL_NO_SRP
${CONF}" )
file( WRITE "${OpenSLL_INCLUDE_PATH}/openssl/opensslconf.h" "${CONF}" )

set( BuildInfH " 
#ifndef MK1MF_BUILD
	/* Generated by crypto.cmake - does it break anything? */
  #define CFLAGS \"\"
  #define PLATFORM \"${CMAKE_SYSTEM_NAME}\"
  #define DATE \"\"
#endif
" )
file( WRITE ${OpenSLL_INCLUDE_PATH}/buildinf.h "${BuildInfH}" )

set(TARGET_SOURCES ${XSRC} ${XINC})

# OpenSSL is not the best when it comes to how it handles headers.  
# Where they are we need to create the projects include dir and copy stuff into it!
message(STATUS "MSIX takes a static dependency on openssl")
add_library(crypto STATIC ${TARGET_SOURCES})

target_include_directories( crypto PRIVATE ${TARGET_INCLUDE_DIRS} ${TARGET_INCLUDE_DIRS_PRIVATE} )
target_compile_definitions( crypto PRIVATE ${TARGET_DEFINES} ${TARGET_DEFINES_PRIVATE} )
target_compile_options    ( crypto PRIVATE ${TARGET_COMPILE_FLAGS} ${TARGET_COMPILE_FLAGS_PRIVATE})
target_include_directories( crypto PUBLIC  ${TARGET_INCLUDE_DIRS} ${OpenSLL_INCLUDE_PATH} ${OpenSLL_INCLUDE_PATH}/openssl)
target_compile_definitions( crypto PUBLIC  ${TARGET_DEFINES} )
target_compile_options    ( crypto PUBLIC  ${TARGET_COMPILE_FLAGS})