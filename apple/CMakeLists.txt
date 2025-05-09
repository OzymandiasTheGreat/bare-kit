add_library(bare_kit STATIC)

set_target_properties(
  bare_kit
  PROPERTIES
  OBJC_STANDARD 11
  FRAMEWORK TRUE
  OUTPUT_NAME BareKit
  PUBLIC_HEADER BareKit/BareKit.h

  MACOSX_FRAMEWORK_BUNDLE_NAME "BareKit"
  MACOSX_FRAMEWORK_IDENTIFIER "to.holepunch.bare.kit"
  MACOSX_FRAMEWORK_BUNDLE_VERSION ${PROJECT_VERSION}
  MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${PROJECT_VERSION}
)

if(IOS)
  set_target_properties(
    bare_kit
    PROPERTIES
    MACOSX_FRAMEWORK_INFO_PLIST "${CMAKE_CURRENT_LIST_DIR}/BareKit/iOS.plist"
  )
else()
  set_target_properties(
    bare_kit
    PROPERTIES
    MACOSX_FRAMEWORK_INFO_PLIST "${CMAKE_CURRENT_LIST_DIR}/BareKit/macOS.plist"
  )
endif()

target_sources(
  bare_kit
  PUBLIC
    BareKit/BareKit.h
  PRIVATE
    BareKit/BareKit.m
)

target_include_directories(
  bare_kit
  PUBLIC
    .
)

target_link_libraries(
  bare_kit
  PUBLIC
    "-framework Foundation"
    "-framework UserNotifications"
  PUBLIC
    bare_worklet
)

if(IOS)
  target_link_libraries(
    bare_kit
    PUBLIC
      "-framework UIKit"
  )
endif()

bare_platform(platform)
bare_arch(arch)
bare_simulator(simulator)

if(simulator)
  set(suffix "-simulator")
else()
  set(suffix)
endif()

if(IOS)
  install(CODE "execute_process(COMMAND xcodebuild -create-xcframework -framework $<TARGET_BUNDLE_DIR:bare_kit> -output $<INSTALL_PREFIX>/${platform}-${arch}${suffix}/frameworks/BareKit.xcframework)")
else()
  install(TARGETS bare_kit FRAMEWORK DESTINATION "${platform}-${arch}${suffix}/frameworks")
endif()
