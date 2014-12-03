#include <sys/sysctl.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>


value ml_platform() {
  size_t size;
  sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	char answer[size];
  sysctlbyname("hw.machine", answer, &size, NULL, 0);
  return caml_copy_string(answer);
}


value ml_hwmodel() {
  size_t size;
  sysctlbyname("hw.model", NULL, &size, NULL, 0);
	char answer[size];
  sysctlbyname("hw.model", answer, &size, NULL, 0);
  return caml_copy_string(answer);
}


int getSysInfo(int typeSpecifier) {
  size_t size = sizeof(int);
  int results;
  int mib[2] = {CTL_HW, typeSpecifier};
  sysctl(mib, 2, &results, &size, NULL, 0);
  return results;
}


value ml_cpuFrequency() {
  return Val_int(getSysInfo(HW_CPU_FREQ));
}


value ml_busFrequency() {
  return Val_int(getSysInfo(HW_BUS_FREQ));
}

value ml_totalMemory() {
  return Val_int(getSysInfo(HW_PHYSMEM));
}

value ml_userMemory() {
  return Val_int(getSysInfo(HW_USERMEM));
};
