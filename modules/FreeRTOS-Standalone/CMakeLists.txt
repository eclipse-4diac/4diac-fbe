forte_add_module(FREERTOS_STANDALONE OFF "build freertos image with FORTE as only application")

if (FORTE_MODULE_FREERTOS_STANDALONE)
  if (NOT FORTE_ARCHITECTURE STREQUAL "FreeRTOSLwIP")
    message(FATAL_ERROR "This module is only available when building for FreeRTOS")
  endif()

  find_package(freertos-cpp11)
  find_package(freertos)

  forte_add_sourcefile_c(main.c)

  add_executable(freertos-forte.elf ${FREERTOS_CONFIG}.c)
  target_link_libraries(freertos-forte.elf FORTE_LITE freertos-cpp11::freertos-cpp11)
  install(TARGETS freertos-forte.elf DESTINATION bin)

  add_custom_command(OUTPUT freertos-forte.bin DEPENDS freertos-forte.elf
    COMMAND ${CMAKE_OBJCOPY} freertos-forte.elf -O binary freertos-forte.bin)
  add_custom_target(binary-image ALL DEPENDS freertos-forte.bin)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/freertos-forte.bin DESTINATION bin)
endif()
