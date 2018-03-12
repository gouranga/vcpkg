include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Cylix/cpp_redis
    REF 4.4.0
    SHA512 b4dc368ec47aa97562a8e532caf2f3290eb409d7d15c2736bdce83119e9be9ee022bea17e3cfb20eda42485624920375e294966c64c455febad476e35c6994b1
    HEAD_REF master
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/tacopie/CMakeLists.txt DESTINATION ${SOURCE_PATH}/tacopie)

if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
    set(MSVC_RUNTIME_LIBRARY_CONFIG "/MD")
else()
    set(MSVC_RUNTIME_LIBRARY_CONFIG "/MT")
endif()

# cpp-redis forcibly removes "/RTC1" in its cmake file. Because this is an ABI-sensitive flag, we need to re-add it in a form that won't be detected.
set(VCPKG_CXX_FLAGS_DEBUG "${VCPKG_CXX_FLAGS_DEBUG} -RTC1")
set(VCPKG_C_FLAGS_DEBUG "${VCPKG_C_FLAGS_DEBUG} -RTC1")

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DMSVC_RUNTIME_LIBRARY_CONFIG=${MSVC_RUNTIME_LIBRARY_CONFIG}
        -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE
)

vcpkg_install_cmake()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

file(GLOB_RECURSE FILES "${CURRENT_PACKAGES_DIR}/include/*")
foreach(file ${FILES})
    file(READ ${file} _contents)
    string(REPLACE "ifndef __CPP_REDIS_USE_CUSTOM_TCP_CLIENT" "if 1" _contents "${_contents}")
    if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
        string(REPLACE
            "extern std::unique_ptr<logger_iface> active_logger;"
            "extern __declspec(dllimport) std::unique_ptr<logger_iface> active_logger;"
            _contents "${_contents}")
    endif()
    file(WRITE ${file} "${_contents}")
endforeach()

file(GLOB FILES_TO_REMOVE "${CURRENT_PACKAGES_DIR}/debug/bin/cpp_redis.ilk" "${CURRENT_PACKAGES_DIR}/bin/cpp_redis.dll.manifest")
if(FILES_TO_REMOVE)
    file(REMOVE_RECURSE ${FILES_TO_REMOVE})
endif()

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/cpp-redis RENAME copyright)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/debug/bin)
endif()

vcpkg_copy_pdbs()
