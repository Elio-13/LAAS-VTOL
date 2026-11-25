cmake_minimum_required(VERSION 3.16)

project(laas_motor_watchdog LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(gz-sim8 REQUIRED)
find_package(gz-transport13 REQUIRED)
find_package(gz-msgs10 REQUIRED)

add_library(laas_motor_watchdog SHARED
    MotorWatchdog.cc
)

target_link_libraries(laas_motor_watchdog PRIVATE
    gz-sim8::gz-sim8
    gz-transport13::gz-transport13
    gz-msgs10::gz-msgs10
)
