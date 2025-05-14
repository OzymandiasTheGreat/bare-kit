function(add_bare_module result)
  bare_module_target("." target NAME name)

  add_library(${target} STATIC)

  set_target_properties(
    ${target}
    PROPERTIES
    C_STANDARD 11
    CXX_STANDARD 20
    POSITION_INDEPENDENT_CODE ON
  )

  target_include_directories(
    ${target}
    PRIVATE
      $<TARGET_PROPERTY:bare,INTERFACE_INCLUDE_DIRECTORIES>
  )

  set(${result} ${target})

  return(PROPAGATE ${result})
endfunction()

function(add_napi_module result)
  napi_module_target("." target NAME name)

  add_library(${target} STATIC)

  set_target_properties(
    ${target}
    PROPERTIES
    C_STANDARD 11
    CXX_STANDARD 20
    POSITION_INDEPENDENT_CODE ON
  )

  target_include_directories(
    ${target}
    PRIVATE
      $<TARGET_PROPERTY:bare,INTERFACE_INCLUDE_DIRECTORIES>
  )

  set(${result} ${target})

  return(PROPAGATE ${result})
endfunction()

function(include_bare_module specifier result)
  set(one_value_keywords
    SOURCE_DIR
    BINARY_DIR
    WORKING_DIRECTORY
  )

  cmake_parse_arguments(
    PARSE_ARGV 2 ARGV "${option_keywords}" "${one_value_keywords}" ""
  )

  if(ARGV_WORKING_DIRECTORY)
    cmake_path(ABSOLUTE_PATH ARGV_WORKING_DIRECTORY BASE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}" NORMALIZE)
  else()
    set(ARGV_WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")
  endif()

  resolve_node_module(
    ${specifier}
    source_dir
    WORKING_DIRECTORY "${ARGV_WORKING_DIRECTORY}"
  )

  bare_module_target("${source_dir}" target NAME name VERSION version)

  string(REGEX MATCH "^[0-9]+" major "${version}")

  set(${result} ${target})

  cmake_path(RELATIVE_PATH source_dir BASE_DIRECTORY "${ARGV_WORKING_DIRECTORY}" OUTPUT_VARIABLE binary_dir)

  if(ARGV_SOURCE_DIR)
    set(${ARGV_SOURCE_DIR} "${source_dir}" PARENT_SCOPE)
  endif()

  if(ARGV_BINARY_DIR)
    set(${ARGV_BINARY_DIR} "${binary_dir}" PARENT_SCOPE)
  endif()

  add_subdirectory("${source_dir}" "${binary_dir}")

  return(PROPAGATE ${result})
endfunction()

function(link_bare_module receiver specifier)
  set(one_value_keywords
    WORKING_DIRECTORY
  )

  cmake_parse_arguments(
    PARSE_ARGV 2 ARGV "" "${one_value_keywords}" ""
  )

  if(ARGV_WORKING_DIRECTORY)
    cmake_path(ABSOLUTE_PATH ARGV_WORKING_DIRECTORY BASE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}" NORMALIZE)
  else()
    set(ARGV_WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}")
  endif()

  set(PREBUILD)

  include_bare_module(
    ${specifier}
    target
    ${PREBUILD}
    SOURCE_DIR source_dir
    WORKING_DIRECTORY "${ARGV_WORKING_DIRECTORY}"
  )

  bare_module_target("${source_dir}" target NAME name VERSION version HASH hash)

  string(MAKE_C_IDENTIFIER ${target} id)

  target_compile_definitions(
    ${target}
    PRIVATE
      BARE_MODULE_FILENAME="${name}@${version}"
      BARE_MODULE_REGISTER_CONSTRUCTOR
      BARE_MODULE_CONSTRUCTOR_VERSION=${hash}

      NAPI_MODULE_FILENAME="${name}@${version}"
      NAPI_MODULE_REGISTER_CONSTRUCTOR
      NAPI_MODULE_CONSTRUCTOR_VERSION=${hash}

      NODE_GYP_MODULE_NAME=${id}
  )

  target_link_libraries(
    ${receiver}
    PRIVATE
      $<TARGET_OBJECTS:${target}>
    PRIVATE
      ${target}
  )

  bare_platform(platform)
  bare_arch(arch)
  bare_simulator(simulator)

  if(simulator)
    set(suffix "-simulator")
  else()
    set(suffix)
  endif()

  install(
    TARGETS
      ${target}
    ARCHIVE DESTINATION
      "${platform}-${arch}${suffix}/lib/addons"
  )

  install_dependencies(${target})
endfunction()

function(install_dependencies target)
  get_target_property(dependencies ${target} INTERFACE_LINK_LIBRARIES)

  foreach(dependency ${dependencies})
    if(TARGET ${dependency})
      get_target_property(imported ${dependency} IMPORTED_LOCATION)

      if(imported)
        install(
          FILES
            $<TARGET_FILE:${dependency}>
          DESTINATION
            "${platform}-${arch}${suffix}/lib/addons"
        )
      else()
        install(
          TARGETS
            ${dependency}
          ARCHIVE DESTINATION
            "${platform}-${arch}${suffix}/lib/addons"
        )

        install_dependencies(${dependency})
      endif()
    endif()
  endforeach()
endfunction()
