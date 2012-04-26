#include <sys/resource.h>
#include <caml/mlvalues.h>

unsigned int MAX_GC_MEM = 10485760;

value ml_memUsage(value p) {
	struct rusage ru;
	getrusage(0,&ru);
	return Val_long(ru.ru_maxrss);
}

void ml_setMaxGC(value max) {
	MAX_GC_MEM = Int64_val(max);
}
