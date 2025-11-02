
option(FORTE_MODULE_FBE_EXAMPLE OFF "Enable empty example module for testing purposes")

if (NOT FORTE_MODULE_FBE_EXAMPLE)
	return()
endif ()

message(STATUS "Example module has been found and enabled.")
