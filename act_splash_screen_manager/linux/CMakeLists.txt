# SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
#
# SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "act_splash_screen_manager")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "act_splash_screen_manager_plugin")

# Any new source files that you add to the plugin should be added here.
# Sources shared by every platform, which know nothing of the platform they are built for.
set(SHARED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../common")
list(APPEND SHARED_SOURCES
  "${SHARED_DIR}/splash_config.cc"
)

list(APPEND PLUGIN_SOURCES
  ${SHARED_SOURCES}
  "act_splash_screen_manager_plugin.cc"
  "act_splash_screen.cc"
  "overlay_splash_presenter.cc"
  "splash_config_reader.cc"
  "splash_image_loader.cc"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE "${SHARED_DIR}")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(act_splash_screen_manager_bundled_libraries
  ""
  PARENT_SCOPE
)

# === Tests ===
# The unit tests cover the configuration shared by the platforms. They are only built when the
# example asks for them, so that an application which uses the plugin does not build them.

if (${include_${PROJECT_NAME}_tests})
if(${CMAKE_VERSION} VERSION_LESS "3.11.0")
  message("Unit tests require CMake 3.11.0 or later")
else()
  set(TEST_RUNNER "${PROJECT_NAME}_test")
  enable_testing()

  include(FetchContent)
  FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
  )
  # Prevent overriding the parent project's compiler/linker settings
  set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
  # Disable install commands for gtest so it doesn't end up in the bundle.
  set(INSTALL_GTEST OFF CACHE BOOL "Disable installation of googletest" FORCE)

  FetchContent_MakeAvailable(googletest)

  # The tested sources are built into the test binary rather than linked from the shared library:
  # what they need is a compiler, not a window.
  add_executable(${TEST_RUNNER}
    "${SHARED_DIR}/test/splash_config_test.cc"
    ${SHARED_SOURCES}
  )
  apply_standard_settings(${TEST_RUNNER})
  target_include_directories(${TEST_RUNNER} PRIVATE "${SHARED_DIR}")
  target_link_libraries(${TEST_RUNNER} PRIVATE gtest_main)

  include(GoogleTest)
  gtest_discover_tests(${TEST_RUNNER})
endif()  # CMake version check
endif()  # include_${PROJECT_NAME}_tests
