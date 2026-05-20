set(PROJECT_NAME A2retroNET)

cmake_minimum_required(VERSION 3.13...3.27)
include(pico_sdk_import.cmake)
project(${PROJECT_NAME} C CXX ASM)
pico_sdk_init()

add_executable(${PROJECT_NAME})
pico_add_extra_outputs(${PROJECT_NAME})

target_compile_definitions(${PROJECT_NAME} PRIVATE HOST=1)

execute_process(
        COMMAND git describe --tags
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE GIT_TAG
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )
message("GIT_TAG is ${GIT_TAG}")
target_compile_definitions(${PROJECT_NAME} PRIVATE GIT_TAG="${GIT_TAG}")

# Make sure TinyUSB can find tusb_config.h
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_LIST_DIR})

# http://elm-chan.org/fsw/ff/ requires ffconf.h to be
# modified in order to set some configuration options
target_include_directories(${PROJECT_NAME} PRIVATE
        fatfs/source
        )
target_sources(${PROJECT_NAME} PRIVATE
        fatfs/source/ff.c
        fatfs/source/ffsystem.c
        fatfs/source/ffunicode.c
        )

# https://github.com/carlk3/no-OS-FatFS-SD-SPI-RPi-Pico provides
# utility code used by the USB-only storage stack
target_include_directories(${PROJECT_NAME} PRIVATE
#@@        sd_spi/sd_driver
        new_sd_spi
        )
target_sources(${PROJECT_NAME} PRIVATE
#@@        sd_spi/sd_driver/crc.c
        new_sd_spi/crc.c
        new_sd_spi/f_util.c
        new_sd_spi/my_rtc.c
        )

include(FetchContent)
set(A2PICO_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/_deps/a2pico-src" CACHE PATH
        "Path to a local a2pico checkout")
if (EXISTS "${A2PICO_SOURCE_DIR}/CMakeLists.txt")
        add_subdirectory("${A2PICO_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/a2pico")
else()
        FetchContent_Declare(a2pico
                GIT_REPOSITORY https://github.com/oliverschmidt/a2pico.git
                GIT_TAG main
                )
        FetchContent_MakeAvailable(a2pico)
endif()

set_source_files_properties(incbin.S OBJECT_DEPENDS firmware.rom)
add_custom_command(
        COMMAND cl65 -t apple2 -C apple2-asm.cfg
                        ${CMAKE_CURRENT_SOURCE_DIR}/6502/SMARTPORT.ROM.S
                     -o ${CMAKE_CURRENT_BINARY_DIR}/firmware.rom
        MAIN_DEPENDENCY 6502/SMARTPORT.ROM.S
        OUTPUT firmware.rom
        DEPENDS 6502/SMARTPORT.ROM.S 6502/SMARTPORT.S
        VERBATIM
        )

target_sources(${PROJECT_NAME} PRIVATE
        board.c
        config.c
        diskio.c
        gen.c
        hdd.c
        incbin.S
        main.c
        msc_host.c
        sp.c
        usb_diskio.c
        )

target_link_libraries(${PROJECT_NAME} PRIVATE
        a2pico
        pico_aon_timer
        pico_multicore
        pico_stdlib
        pico_unique_id
        )
target_link_libraries(${PROJECT_NAME} PRIVATE
        tinyusb_host
        )
