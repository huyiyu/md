
```bash
# 编译 c 代码 
gcc -fPIC -I $JAVA_HOME/include -I $JAVA_HOME/include/darwin -I . -shared -o libmyThreadNative.jnilib MyJavaThread.c
```