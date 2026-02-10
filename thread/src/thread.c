#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

void *run(void *arguments){
  while(1){
    printf("thread 1 run\n");
    usleep(100);
  }

}

int main(){
  pthread_t pid;
  int err = pthread_create(&pid, NULL,run,NULL);
  while(1){
    usleep(100);
    printf("main run\n");
  }
  return 0;
}
