sdl:
	$(MAKE) -f Makefile.pc

clean: 
	$(MAKE) -f Makefile.pc clean

ios:
	$(MAKE) -f Makefile.ios

cleanios:
	$(MAKE) -f Makefile.ios clean

android: 
	$(MAKE) -f Makefile.android so

androidr: 
	$(MAKE) -f Makefile.android release

android-install:
	adb install -r android/bin/LightTest-debug.apk

android-installr:
	adb install -r android/bin/LightTest-release.apk

android-install-s:
	adb install -r -s android/bin/LightTest-debug.apk

android-log:
	adb logcat LIGHTNING:* LIGHTTEST:* *:E *:F *:S

android-log-error:
	adb logcat LIGHTNING:* DEBUG:* dalvikvm:* *:E *:F *:S

.PHONY: android ios sdl


KAZMATHOBJS = utility.o vec2.o vec4.o vec3.o mat3.o quaternion.o mat4.o neon_matrix_impl.o GL/mat4stack.o GL/matrix.o
KAZMATH = $(patsubst %,../src/kazmath/%,$(KAZMATHOBJS))

mat: mat.c
	gcc -o mat -I ../src mat.c $(KAZMATH)
