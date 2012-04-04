#include <sys/resource.h>
#include <caml/mlvalues.h>


value ml_memUsage(value p) {
	struct rusage ru;
	getrusage(0,&ru);
	return Val_long(ru.ru_maxrss);
}
