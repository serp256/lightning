#include <stdio.h>      
#include <time.h>       
#import "light_common.h"
#import <caml/memory.h>
#import <caml/mlvalues.h>
#import <caml/alloc.h>
#import <caml/threads.h>

value ml_deviceLocalTime (value unit) {
	CAMLparam0();

	time_t rawtime;
	struct tm * timeinfo, *gm_timeinfo;

	time (&rawtime);
	timeinfo = localtime (&rawtime);
	gm_timeinfo = gmtime (&rawtime);
	PRINT_DEBUG("Current local time and date: %s", asctime(timeinfo));
	PRINT_DEBUG("Current local time and date: %s", asctime(gm_timeinfo));

	int secondsFromGMT = (timeinfo->tm_hour - gm_timeinfo->tm_hour) * 3600;
	double result = (double)(rawtime + secondsFromGMT);

	CAMLreturn(caml_copy_double(result));
}
