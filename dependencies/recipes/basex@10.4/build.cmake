project(basex_c_src NONE)
CMAKE_MINIMUM_REQUIRED(VERSION 3.1)

install(DIRECTORY basex-api/src/main/c/
    DESTINATION src/basex-c
    FILES_MATCHING PATTERN "*.h"
)

install(DIRECTORY basex-api/src/main/c/
    DESTINATION src/basex-c
    FILES_MATCHING PATTERN "*.c"
)