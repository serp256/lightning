#include <stdio.h>
#include <sys/resource.h>

#include <caml/mlvalues.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/fail.h>



unsigned int MAX_GC_MEM = 10485760;

value ml_memUsage(value p) {
	struct rusage ru;
	getrusage(0,&ru);
	return Val_long(ru.ru_maxrss);
}

void ml_setMaxGC(value max) {
	MAX_GC_MEM = Int64_val(max);
}

#if defined(ANDROID) 
//in android/mlwrapper_android.c 
#else 
#if OS==LINUX

value ml_getMACID(value p) {
  return caml_copy_string("123");
}

#else

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

value ml_getMACID(value p) {
	int                 mib[6];
  size_t              len;
  char                *buf;
  unsigned char       *ptr;
  struct if_msghdr    *ifm;
  struct sockaddr_dl  *sdl;

  mib[0] = CTL_NET;
  mib[1] = AF_ROUTE;
  mib[2] = 0;
  mib[3] = AF_LINK;
  mib[4] = NET_RT_IFLIST;


  if ((mib[5] = if_nametoindex("en0")) == 0)
  {
    caml_failwith("Error: if_nametoindex error");
  }

  if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
  {
    caml_failwith("Error: sysctl, take 1");
  }

  if ((buf = malloc(len)) == NULL)
  {
    caml_failwith("Could not allocate memory. error!");
  }

  if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
  {
    caml_failwith("Error: sysctl, take 2");
  }

  ifm = (struct if_msghdr *)buf;
  sdl = (struct sockaddr_dl *)(ifm + 1);
  ptr = (unsigned char *)LLADDR(sdl);
	value res = caml_alloc_string(2 * 6);
	sprintf(String_val(res),"%02X%02X%02X%02X%02X%02X",*ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5));
  free(buf);
  return res;
}

#endif
#endif
