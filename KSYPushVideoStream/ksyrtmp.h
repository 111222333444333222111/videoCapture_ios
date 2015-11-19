#ifndef _KSY_RTMP_H_
#define _KSY_RTMP_H_

#include "./include/librtmp/rtmp.h"
#include "./include/librtmp/log.h"
#include <pthread.h>

#define READ_FLAGS 1
#define WRITE_FLAGS 2

#define ERROR_UNKNOWN (-1)
#define ERROR_CONNECT (-2)
#define ERROR_CONNECT_STREAM (-3)
#define ERROR_SETUP   (-4)
#define ERROR_MEM     (-5)

#define KSY_RTMP_LOG_TAG "RTMP"
#define _KSY_DEBUG
typedef struct H264SPSPPS
{
    int sended;
    char* sps;
    int sps_size;
    char* pps;
    int pps_size;
} H264SPSPPS;

typedef struct AACHEADER
{
    char sended;
    char header[2];
    char type;
    int ph_len;
    int pb_len;
} AACHEADER;

typedef struct LibRTMPContext {
    RTMP rtmp;
    char *app;
    char *conn;
    char *subscribe;
    char *playpath;
    char *tcurl;
    char *flashver;
    char *swfurl;
    char *swfverify;
    char *pageurl;
    char *client_buffer_time;
    int live;
    char *filename;
    char* temp_filename;
    int buffer_size;
    int64_t first_pts;
#ifdef _KSY_DEBUG
    int fd;
#endif // _KSY_DEBUG
    H264SPSPPS sps_pps;
    AACHEADER aac;
} LibRTMPContext;

int rtmp_init(LibRTMPContext **ctx);
int rtmp_unit(LibRTMPContext **ctx);
int rtmp_seturl(LibRTMPContext *ctx,  const char* url);
int rtmp_open(LibRTMPContext *ctx,  int flags);
int rtmp_write_video(LibRTMPContext *ctx, const char *buf, int size, int64_t pts);
int rtmp_write_audio(LibRTMPContext *ctx, const char *buf, int size, int64_t pts);
int rtmp_write(LibRTMPContext *ctx, const char *buf, int size);
int rtmp_read(LibRTMPContext *ctx, char *buf, int size);
int rtmp_close(LibRTMPContext *ctx);
int rtmp_read_pause(LibRTMPContext *ctx, int pause);
int64_t rtmp_read_seek(LibRTMPContext *ctx, int64_t timestamp);

#endif // _KSY_RTMP_H_
