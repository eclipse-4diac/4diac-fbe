#include <stdlib.h>
#include <unistd.h>

extern void __real_initForte();

void __wrap_initForte() {
	chdir(getenv("FORTE_RUNDIR"));
	__real_initForte();
}
