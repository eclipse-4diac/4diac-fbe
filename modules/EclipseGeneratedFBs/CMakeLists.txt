#********************************************************************************
# Copyright (c) 2018, 2024 OFFIS e.V.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# SPDX-License-Identifier: EPL-2.0
# 
# Contributors:
#    Jörg Walter - initial implementation
# *******************************************************************************/
#

set_directory_properties(PROPERTIES CMAKE_CONFIGURE_DEPENDS generated)
file(MAKE_DIRECTORY generated edited edited/original)

file(GLOB gen RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/generated generated/*.cpp generated/*.h)
file(GLOB edit RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/edited edited/*.cpp edited/*.h)

# process new file dump if present
if (NOT gen STREQUAL "")

  # check for completely new and previously-known new files
  set(newfiles "${gen}")
  foreach(src IN LISTS newfiles)
	if (NOT EXISTS "edited/${src}")
	  message(STATUS "*!* Adding new source file: ${src}")
	  file(COPY "generated/${src}" DESTINATION "${CMAKE_CURRENT_SOURCE_DIR}/edited/original/")
	  file(COPY "generated/${src}" DESTINATION "${CMAKE_CURRENT_SOURCE_DIR}/edited/")
	else()
	  message(FATAL_ERROR "New source file would overwrite unknown file: edited/${src}")
	endif()
  endforeach()

  # update changed files
  foreach(src IN LISTS gen)
	set(old "${CMAKE_CURRENT_SOURCE_DIR}/edited/original/${src}")
	set(new "${CMAKE_CURRENT_SOURCE_DIR}/generated/${src}")
	set(edited "${CMAKE_CURRENT_SOURCE_DIR}/edited/${src}")
	set(diff "${CMAKE_CURRENT_BINARY_DIR}/${src}.diff")
	set(patched "${CMAKE_CURRENT_BINARY_DIR}/${src}")

	execute_process(COMMAND diff -q "${old}" "${new}" OUTPUT_QUIET
	  RESULT_VARIABLE rc)
	if (rc EQUAL 0)
	  file(REMOVE "${new}" "${diff}")
	elseif (rc EQUAL 1)
	  message(STATUS "*!* Updating source file: ${src}")
	  execute_process(COMMAND diff -u "${old}" "${edited}" OUTPUT_FILE "${diff}"
		RESULT_VARIABLE rc)
	  if (NOT (rc EQUAL 0 OR rc EQUAL 1))
		message(FATAL_ERROR "Could not diff ${old} and ${edited}!")
	  endif()
	  file(COPY "${new}" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
	  execute_process(COMMAND patch -N "${patched}" "${diff}"
		RESULT_VARIABLE rc)
	  if (NOT rc EQUAL 0)
		message(FATAL_ERROR "Could not update ${edited}! Please update manually, then copy ${new} to edited/original/")
	  endif()
	  file(RENAME "${patched}" "${edited}")
	  file(COPY "${new}" "${old}")
	  file(REMOVE "${diff}")
	else()
	  message(FATAL_ERROR "Could not diff ${old} and ${new}!")
	endif()
  endforeach()
endif()

# clean up orphaned original files
file(GLOB edit_orig RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/edited/original edited/original/*.cpp edited/original/*.h)
foreach(src IN LISTS edit_orig)
  if (NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/edited/${src}")
	message(STATUS "*!* Missing source file: ${src}, removing related data...")
	file(REMOVE "${CMAKE_CURRENT_SOURCE_DIR}/edited/original/${src}")
  endif()
endforeach()

# now work with the updated files
set(FORTE_MODULE_CUSTOM_FBS ON CACHE BOOL "")
forte_add_module(CUSTOM_FBS ON "Custom FBs")

file(GLOB CUSTOM_SRCS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} edited/*.cpp)

foreach(CUSTOM_SRC IN LISTS CUSTOM_SRCS)
  string(REGEX REPLACE "\\.cpp" "" CUSTOM_SRC "${CUSTOM_SRC}")
  message(STATUS ">>> Adding custom FB: ${CUSTOM_SRC}")
  forte_add_sourcefile_hcpp(${CUSTOM_SRC})
endforeach()
