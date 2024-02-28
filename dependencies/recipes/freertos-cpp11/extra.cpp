#include <FreeRTOS.h>
#include <task.h>
#include <debug-printf.h>

int __override_libstdcpp_hack;

/* libstdc++ adaption, prevent using the version that uses newlib's puts(),
 * because that cannot be overridden by any other libc (like picolibc)  */
namespace __gnu_cxx {
    void __verbose_terminate_handler() {
        taskENTER_CRITICAL_FROM_ISR();
        debug_printf("*** TERMINATE CALLED ***\n");

        for(;;);
    }
}
