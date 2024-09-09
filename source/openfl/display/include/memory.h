// thank u daniel <3

#ifdef _WIN32 // Windows
#include <windows.h>
#include <psapi.h>
#elif __APPLE__ // Apple
#include <mach/mach.h>
#elif __linux__ // Linux (and android i think)
#include <stdio.h>
#include <unistd.h>
#endif

size_t get_memory_usage() {
   #ifdef _WIN32 // Windows
   PROCESS_MEMORY_COUNTERS pmc;
   if (GetProcessMemoryInfo( GetCurrentProcess(), &pmc, sizeof(pmc) )) {
      return (size_t) pmc.WorkingSetSize;
   } else {
      return (size_t) 0;
   }
   #elif __APPLE__
   struct task_basic_info tbi;
   mach_msg_type_number_t tbi_count = TASK_BASIC_INFO_COUNT;
   if (task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&tbi, &tbi_count) != KERN_SUCCESS) {
      return (size_t) 0;
   }
   return (size_t) tbi.resident_size;
   #elif __linux__
   FILE *fp = fopen("/proc/self/statm", "r");
   if (fp == NULL) { // if it da fails
      return (size_t) 0;
   }
   int rss;
   if (fscanf(fp, "%*s%d", &rss) != 1) {
      return (size_t) 0;
   }
   fclose(fp);
   return (size_t) rss * (size_t) sysconf(_SC_PAGESIZE);
   #else
   return (size_t) 0;
   #endif
}