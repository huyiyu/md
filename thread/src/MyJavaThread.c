#include <stdio.h>
#include <MyThread.h>

JNIEXPORT void JNICALL Java_MyThread_start(JNIEnv* env, jobject jobj){
     // 获取运行时的class
     jclass jcls = (*env)->FindClass(env,"MyThread");
     // 查询run方法
     jmethodID jrun = (*env)->GetMethodID(env,jcls,"run","()V");
     // 执行run方法
     jint i= (*env)->CallIntMethod(env,jobj,jrun,NULL);
}