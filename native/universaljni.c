#include <jni.h>

JNIEXPORT jstring JNICALL Java_NativeInfo_platform(JNIEnv *env, jclass cls) {
	(void)cls;

#if defined(_WIN32)
	return (*env)->NewStringUTF(env, "windows");
#elif defined(__APPLE__)
	return (*env)->NewStringUTF(env, "macos");
#elif defined(__linux__)
	return (*env)->NewStringUTF(env, "linux");
#else
	return (*env)->NewStringUTF(env, "unknown");
#endif
}
