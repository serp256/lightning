#define WRITEBUFFERSIZE (8192)
#define CASESENSITIVITY (0)

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <time.h>
#include <unistd.h>
#include <utime.h>
#include <sys/stat.h>

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

void ml_miniunz(value zipPath, value dstPath) {

}

static value vapkPath;
static value vexternalStoragePath;

value getPath(const char* methodName, value* vpath) {
  if (*vapkPath == NULL) {
    JNIEnv *env;
    (*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

    jmethodID mid = (*env)->GetMethodID(env, jViewCls, methodName, "()Ljava/lang/String;");
    jstring jpath = (*env)->CallObjectMethod(env, jView, mid);
    char* cpath = (*env)->GetStringUTFChars(env, jpath, JNI_FALSE);

    *vpath = caml_copy_string(capkPath);
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

void ml_miniunz(value vzipPath, value vdstPath) {  
}

/*JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024ExtractAssetsTask_extractAssets(JNIEnv *env, jobject this, jstring apkPath, jstring dst) {
  const char* capkPath = (*env)->GetStringUTFChars(env, apkPath, JNI_FALSE);
  const char* cdst = (*env)->GetStringUTFChars(env, dst, JNI_FALSE);

  do_extract(capkPath, cdst);

  (*env)->ReleaseStringUTFChars(env, apkPath, capkPath);
  (*env)->ReleaseStringUTFChars(env, dst, cdst);
}*/

/*JNIEXPORT void JNICALL Java_ru_redspell_lightning_LightView_00024ExtractAssetsTask_assetsExtracted(JNIEnv *env, jobject this, jint jcbptr) {
  value* cbptr = (value*)jcbptr;
  value cb = *((value*)cbptr);

  caml_callback(cb, Val_unit);
  caml_remove_generational_global_root(cbptr);  
}*/

/*void ml_extractAssets(value cb) {
  value *cbptr = malloc(sizeof(value));
  *cbptr = cb;
  caml_register_generational_global_root(cbptr);

  JNIEnv *env;
  (*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

  jmethodID mid = (*env)->GetMethodID(env, jViewCls, "extractAssets", "(I)V");
  (*env)->CallVoidMethod(env, jView, mid, (jint)cbptr);
}*/

/*void ml_extractAssets(value callback) {
  JNIEnv *env;
  (*gJavaVM)->GetEnv(gJavaVM, (void**) &env, JNI_VERSION_1_4);

  jmethodID mid = (*env)->GetMethodID(env, jViewCls, "getContext", "()Landroid/content/Context;");
  jobject context = (*env)->CallObjectMethod(env, jView, mid);
  
  jclass contextCls = (*env)->GetObjectClass(env, context);
  mid = (*env)->GetMethodID(env, contextCls, "getPackageCodePath", "()Ljava/lang/String;");
  jstring japkPath = (*env)->CallObjectMethod(env, context, mid);

  const char* capkPath = (*env)->GetStringUTFChars(env, japkPath, JNI_FALSE);

  mid = (*env)->GetMethodID(env, jViewCls, "getAssetsDir", "()Ljava/lang/String;");
  jstring jexternalStoragePath = (*env)->CallObjectMethod(env, jView, mid);
  const char* cexternalStoragePath = (*env)->GetStringUTFChars(env, jexternalStoragePath, JNI_FALSE);

  int retval = do_extract(capkPath, cexternalStoragePath);

  (*env)->ReleaseStringUTFChars(env, jexternalStoragePath, cexternalStoragePath);
  (*env)->DeleteLocalRef(env, jexternalStoragePath);
}*/