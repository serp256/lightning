#define WRITEBUFFERSIZE (8192)
#define CASESENSITIVITY (0)

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <unistd.h>
#include <utime.h>
#include <sys/stat.h>
#include <pthread.h>

#include "assets_extractor.h"

void change_file_date(const char *filename,uLong dosdate,tm_unz tmu_date)
{
  struct utimbuf ut;
  struct tm newdate;
  newdate.tm_sec = tmu_date.tm_sec;
  newdate.tm_min=tmu_date.tm_min;
  newdate.tm_hour=tmu_date.tm_hour;
  newdate.tm_mday=tmu_date.tm_mday;
  newdate.tm_mon=tmu_date.tm_mon;
  if (tmu_date.tm_year > 1900)
      newdate.tm_year=tmu_date.tm_year - 1900;
  else
      newdate.tm_year=tmu_date.tm_year ;
  newdate.tm_isdst=-1;

  ut.actime=ut.modtime=mktime(&newdate);
  utime(filename,&ut);
}

int mymkdir(const char* dirname)
{
    int ret=0;
    ret = mkdir (dirname,0775);
    return ret;
}

int makedir (char *newdir)
{
  char *buffer ;
  char *p;
  int  len = (int)strlen(newdir);

  if (len <= 0)
    return 0;

  buffer = (char*)malloc(len+1);
        if (buffer==NULL)
        {
                PRINT_DEBUG("Error allocating memory\n");
                return UNZ_INTERNALERROR;
        }
  strcpy(buffer,newdir);

  if (buffer[len-1] == '/') {
    buffer[len-1] = '\0';
  }
  if (mymkdir(buffer) == 0)
    {
      free(buffer);
      return 1;
    }

  p = buffer+1;
  while (1)
    {
      char hold;

      while(*p && *p != '\\' && *p != '/')
        p++;
      hold = *p;
      *p = 0;
      if ((mymkdir(buffer) == -1) && (errno == ENOENT))
        {
          PRINT_DEBUG("couldn't create directory %s\n",buffer);
          free(buffer);
          return 0;
        }
      if (hold == 0)
        break;
      *p++ = hold;
    }
  free(buffer);
  return 1;
}

int do_extract_currentfile(unzFile uf, const char* dst)
{
    char filename_inzip[256];
    char* filename_withoutpath;
    char* p;
    int err=UNZ_OK;
    FILE *fout=NULL;
    void* buf;
    uInt size_buf;

    unz_file_info64 file_info;
    err = unzGetCurrentFileInfo64(uf,&file_info,filename_inzip,sizeof(filename_inzip),NULL,0,NULL,0);

    if (!strstr(filename_inzip, "assets")) {
        return UNZ_OK;
    }

    if (err!=UNZ_OK)
    {
        PRINT_DEBUG("error %d with zipfile in unzGetCurrentFileInfo\n",err);
        return err;
    }

    size_buf = WRITEBUFFERSIZE;
    buf = (void*)malloc(size_buf);
    if (buf==NULL)
    {
        PRINT_DEBUG("Error allocating memory\n");
        return UNZ_INTERNALERROR;
    }

    int dstlen = strlen(dst);
    int filenamelen = strlen(filename_inzip);

    char* write_filename = malloc(dstlen + filenamelen + 1);
    strcpy(write_filename, dst);
    strcpy(write_filename + dstlen, filename_inzip);
    *(write_filename + dstlen + filenamelen) = '\0';

    p = filename_withoutpath = write_filename;

    while ((*p) != '\0')
    {
        if (((*p)=='/') || ((*p)=='\\'))
            filename_withoutpath = p+1;
        p++;
    }

    if ((*filename_withoutpath)=='\0')
    {
        makedir(write_filename);
    }
    else
    {
        int skip=0;

        err = unzOpenCurrentFile(uf);
        if (err!=UNZ_OK)
        {
            PRINT_DEBUG("error %d with zipfile in unzOpenCurrentFile\n",err);
        }

        if ((skip==0) && (err==UNZ_OK))
        {
            fout=fopen64(write_filename,"wb");

            /* some zipfile don't contain directory alone before file */
            if ((fout==NULL) && (filename_withoutpath!=(char*)filename_inzip))
            {
                char c=*(filename_withoutpath-1);
                *(filename_withoutpath-1)='\0';
                makedir(write_filename);
                *(filename_withoutpath-1)=c;
                fout=fopen64(write_filename,"wb");
            }

            if (fout==NULL)
            {
                PRINT_DEBUG("error opening %s\n",write_filename);
            }
        }

        if (fout!=NULL)
        {
            PRINT_DEBUG(" extracting: %s\n",write_filename);

            do
            {
                err = unzReadCurrentFile(uf,buf,size_buf);
                if (err<0)
                {
                    PRINT_DEBUG("error %d with zipfile in unzReadCurrentFile\n",err);
                    break;
                }
                if (err>0)
                    if (fwrite(buf,err,1,fout)!=1)
                    {
                        PRINT_DEBUG("error in writing extracted file\n");
                        err=UNZ_ERRNO;
                        break;
                    }
            }
            while (err>0);
            if (fout)
                    fclose(fout);

            if (err==0)
                change_file_date(write_filename,file_info.dosDate,
                                 file_info.tmu_date);
        }

        if (err==UNZ_OK)
        {
            err = unzCloseCurrentFile (uf);
            if (err!=UNZ_OK)
            {
                PRINT_DEBUG("error %d with zipfile in unzCloseCurrentFile\n",err);
            }
        }
        else
            unzCloseCurrentFile(uf); /* don't lose the error */
    }

    free(write_filename);
    free(buf);
    return err;
}

int do_extract(const char* zip_path, const char* dst)
{
  unzFile uf = unzOpen64(zip_path);

  if (uf == NULL) {
    PRINT_DEBUG("cannot unzip file %s", zip_path);
    return UNZ_ERRNO;
  }

  uLong i;
  unz_global_info64 gi;
  int err;

  err = unzGetGlobalInfo64(uf,&gi);
  if (err!=UNZ_OK) {
    PRINT_DEBUG("error %d with zipfile in unzGetGlobalInfo \n",err);
    return err;
  }

  for (i=0;i<gi.number_entry;i++)
  {
      if (do_extract_currentfile(uf, dst) != UNZ_OK)
          break;

      if ((i+1)<gi.number_entry)
      {
          err = unzGoToNextFile(uf);
          if (err!=UNZ_OK)
          {
              PRINT_DEBUG("error %d with zipfile in unzGoToNextFile\n",err);
              break;
          }
      }
  }

  unzClose(uf);

  return err;
}

static value vapkPath;
static value vexternalStoragePath;

value getPath(const char* methodName, value* vpath) {
  if (!(*vpath)) {
    JNIEnv *env;
    (*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

    jmethodID mid = (*env)->GetMethodID(env, jViewCls, methodName, "()Ljava/lang/String;");
    jstring jpath = (*env)->CallObjectMethod(env, jView, mid);
    const char* cpath = (*env)->GetStringUTFChars(env, jpath, JNI_FALSE);

    *vpath = caml_copy_string(cpath);
    caml_register_generational_global_root(vpath);

    (*env)->ReleaseStringUTFChars(env, jpath, cpath);
    (*env)->DeleteLocalRef(env, jpath);
  }

  return *vpath;
}

value ml_apkPath() {
  return getPath("getApkPath", &vapkPath);
}

value ml_externalStoragePath() {
  return getPath("getExternalStoragePath", &vexternalStoragePath);
}

typedef struct {
  char* zipPath;
  char* dstPath;
} unzip_paths_t;

static jmethodID gCallUnzipCompleteMid;

void* miniunz_thread(void* params) {
  unzip_paths_t* paths = (unzip_paths_t*) params;
  do_extract(paths->zipPath, paths->dstPath);

  JNIEnv *env;
  (*gJavaVM)->AttachCurrentThread(gJavaVM, &env, NULL);

  if (!gCallUnzipCompleteMid) {
    gCallUnzipCompleteMid = (*env)->GetMethodID(env, jViewCls, "callUnzipComplete", "(Ljava/lang/String;Ljava/lang/String;)V");
  }

  jstring jzipPath = (*env)->NewStringUTF(env, paths->zipPath);
  jstring jdstPath = (*env)->NewStringUTF(env, paths->dstPath);
  (*env)->CallVoidMethod(env, jView, gCallUnzipCompleteMid, jzipPath, jdstPath);

  (*env)->DeleteLocalRef(env, jzipPath);
  (*env)->DeleteLocalRef(env, jdstPath);
  (*gJavaVM)->DetachCurrentThread(gJavaVM);

  free(paths->zipPath);
  free(paths->dstPath);
  free(paths);

  pthread_exit(NULL);
}

void ml_miniunz(value vzipPath, value vdstPath) {
  unzip_paths_t* paths = (unzip_paths_t*)malloc(sizeof(unzip_paths_t));

  char* czipPath = String_val(vzipPath);
  char* cdstPath = String_val(vdstPath);

  paths->zipPath = (char*)malloc(strlen(czipPath) + 1);
  paths->dstPath = (char*)malloc(strlen(cdstPath) + 1);

  strcpy(paths->zipPath, czipPath);
  strcpy(paths->dstPath, cdstPath);

  pthread_t tid;

  if (pthread_create(&tid, NULL, miniunz_thread, (void*) paths)) {
    PRINT_DEBUG("cannot create thread");
  }
}

static jclass gRunnableCls;
static jfieldID gZipPathFid;
static jfieldID gDstPathFid;

JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024UnzipCallbackRunnable_run(JNIEnv *env, jobject this) {
  if (!gRunnableCls) {
    jclass runnableCls = (*env)->GetObjectClass(env, this);
    gRunnableCls = (*env)->NewGlobalRef(env, runnableCls);
    (*env)->DeleteLocalRef(env, runnableCls);

    gZipPathFid = (*env)->GetFieldID(env, gRunnableCls, "zipPath", "Ljava/lang/String;");
    gDstPathFid = (*env)->GetFieldID(env, gRunnableCls, "dstPath", "Ljava/lang/String;");
  }

  jstring jzipPath = (*env)->GetObjectField(env, this, gZipPathFid);
  jstring jdstPath = (*env)->GetObjectField(env, this, gDstPathFid);
  const char* czipPath = (*env)->GetStringUTFChars(env, jzipPath, JNI_FALSE);
  const char* cdstPath = (*env)->GetStringUTFChars(env, jdstPath, JNI_FALSE);

  value vzipPath = caml_copy_string(czipPath);
  value vdstPath = caml_copy_string(cdstPath);

  caml_callback2(*caml_named_value("unzipComplete"), vzipPath, vdstPath);

  (*env)->ReleaseStringUTFChars(env, jzipPath, czipPath);
  (*env)->ReleaseStringUTFChars(env, jdstPath, cdstPath);
  (*env)->DeleteLocalRef(env, jzipPath);
  (*env)->DeleteLocalRef(env, jdstPath);
}