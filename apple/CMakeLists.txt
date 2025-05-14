add_library(bare_kit STATIC)

set_target_properties(
  bare_kit
  PROPERTIES
  OBJC_STANDARD 11
  OUTPUT_NAME bare-kit
  PUBLIC_HEADER BareKit/BareKit.h
)

target_sources(
  bare_kit
  PUBLIC
    BareKit/BareKit.h
  PRIVATE
    BareKit/BareKit.m
    $<TARGET_OBJECTS:utf>
    $<TARGET_OBJECTS:uv>
    # $<TARGET_OBJECTS:log>
    $<TARGET_OBJECTS:rlimit>
    $<TARGET_OBJECTS:bare>
    $<TARGET_OBJECTS:bare_worklet>
)

target_include_directories(
  bare_kit
  PUBLIC
    .
    $<TARGET_PROPERTY:utf,INCLUDE_DIRECTORIES>
    $<TARGET_PROPERTY:uv,INCLUDE_DIRECTORIES>
    $<TARGET_PROPERTY:bare,INCLUDE_DIRECTORIES>
)

link_bare_modules(bare_kit WORKING_DIRECTORY ..)

bare_platform(platform)
bare_arch(arch)
bare_simulator(simulator)

if(simulator)
  set(suffix "-simulator")
else()
  set(suffix)
endif()

if(IOS)
  # TODO: prob will have to screw whole xcframework thing and go with plain *.a
  install(
    CODE
    "execute_process(COMMAND xcodebuild -create-xcframework -framework $<TARGET_BUNDLE_DIR:bare_kit> -output $<INSTALL_PREFIX>/${platform}-${arch}${suffix}/frameworks/BareKit.xcframework)"
  )
else()
  install(
    TARGETS
      bare_kit
    PUBLIC_HEADER DESTINATION
      "${platform}-${arch}${suffix}/include"
    ARCHIVE DESTINATION
      "${platform}-${arch}${suffix}/lib"
  )
  install(
    FILES
      $<TARGET_FILE:js_static>
      $<TARGET_FILE:v8>
    DESTINATION
      "${platform}-${arch}${suffix}/lib"
  )
endif()
