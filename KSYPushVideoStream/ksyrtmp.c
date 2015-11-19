#include "ksyrtmp.h"
#include <stdlib.h>
#include <unistd.h>

#define NAL_SLICE       0x01
#define NAL_IDR_SLICE   0x05
#define NAL_SPS         0x07
#define NAL_PPS         0x08

#define FLV_AUDIO       0x08
#define FLV_VIDEO       0x09
#define FLV_DATA        0x12

#define FLV_KEYFRAME    0x01
#define FLV_NONKEYFRAME 0x02

#define FLV_SPSPPS      0x00
#define FLV_NALU        0x01

#define FLV_AVC         0x07
#define FLV_AAC         0xA0
#define FLV_SND_TYPE    0x01
#define FLV_SAMPLE_16B  0x02

#define MALLOC_PENDDING 8

#if defined(__ANDROID__)
#include <android/log.h>
#endif

int rtmp_init(LibRTMPContext **ctx)
{
    *ctx = (LibRTMPContext*)malloc(sizeof(LibRTMPContext));
    memset(*ctx,0,sizeof(LibRTMPContext));
    (*ctx)->client_buffer_time = strdup("3000");
    (*ctx)->first_pts = -1;
#ifdef _KSY_DEBUG
    (*ctx)->fd = -1;
#endif // _KSY_DEBUG
    return 0;
}

int rtmp_unit(LibRTMPContext **ctxp)
{
    LibRTMPContext * ctx = *ctxp;
    if(ctx==NULL)
        return 0;
    if(ctx->app)                                                        free(ctx->app);
    if(ctx->conn)                                                     free(ctx->conn);
    if(ctx->subscribe)                                        free(ctx->subscribe);
    if(ctx->playpath)                                           free(ctx->playpath);
    if(ctx->tcurl)                                                   free(ctx->tcurl);
    if(ctx->flashver)                                           free(ctx->flashver);
    if(ctx->swfurl)                                                free(ctx->swfurl);
    if(ctx->swfverify)                                        free(ctx->swfverify);
    if(ctx->pageurl)                                             free(ctx->pageurl);
    if(ctx->client_buffer_time)                free(ctx->client_buffer_time);
    if(ctx->filename)                                          free(ctx->filename);
    if(ctx->temp_filename)                             free(ctx->temp_filename);
    free(ctx);
    *ctxp = NULL;
    return 0;
}

static void rtmp_log(int level, const char *fmt, va_list args)
{
    if(RTMP_LOGINFO < level)
        return ;
#if defined(__ANDROID__)
    __android_log_vprint(level,"KSYRTMP",fmt,args);
#else
    switch (level) {
    case RTMP_LOGCRIT:    
    case RTMP_LOGERROR:  
    case RTMP_LOGWARNING:
    case RTMP_LOGINFO:   
		printf(fmt,args);
		break;
    case RTMP_LOGDEBUG:    
		break;
    case RTMP_LOGDEBUG2: 
		break;
    default:
		printf(fmt,args);
		break;
    }   
#endif // defined
    return ;
}

int rtmp_close(LibRTMPContext *ctx)
{
    RTMP *r = &ctx->rtmp;
    RTMP_Close(r);
    free(ctx->temp_filename);
    ctx->temp_filename = NULL;
    ctx->first_pts = -1;
    return 0;
}

int rtmp_seturl(LibRTMPContext *ctx,  const char* url)
{
    if(ctx->filename!=NULL)
        free(ctx->filename);
    ctx->filename = strdup(url);
    return 0;
}

int rtmp_open(LibRTMPContext *ctx , int flags)
{
    RTMP *r = &ctx->rtmp;
    int rc = 0;
    char *filename = NULL;
    if(ctx->filename==NULL)
        return -1;
    int len = strlen(ctx->filename) + 1;

    RTMP_LogSetLevel(RTMP_LOGWARNING);
    RTMP_LogSetCallback(rtmp_log);

    if (ctx->app)      len += strlen(ctx->app)      + sizeof(" app=");
    if (ctx->tcurl)    len += strlen(ctx->tcurl)    + sizeof(" tcUrl=");
    if (ctx->pageurl)  len += strlen(ctx->pageurl)  + sizeof(" pageUrl=");
    if (ctx->flashver) len += strlen(ctx->flashver) + sizeof(" flashver=");

    if (ctx->conn) {
        char *sep, *p = ctx->conn;
        int options = 0;

        while (p) {
            options++;
            p += strspn(p, " ");
            if (!*p)
                break;
            sep = strchr(p, ' ');
            if (sep)
                p = sep + 1;
            else
                break;
        }
        len += options * sizeof(" conn=");
        len += strlen(ctx->conn);
    }

    if (ctx->playpath)
        len += strlen(ctx->playpath) + sizeof(" playpath=");
    if (ctx->live)
        len += sizeof(" live=1");
    if (ctx->subscribe)
        len += strlen(ctx->subscribe) + sizeof(" subscribe=");

    if (ctx->client_buffer_time)
        len += strlen(ctx->client_buffer_time) + sizeof(" buffer=");

    if (ctx->swfurl || ctx->swfverify) {
        len += sizeof(" swfUrl=");

        if (ctx->swfverify)
            len += strlen(ctx->swfverify) + sizeof(" swfVfy=1");
        else
            len += strlen(ctx->swfurl);
    }

    if (!(ctx->temp_filename = filename = malloc(len)))
        return ERROR_MEM;

    strlcpy(filename, ctx->filename, len);
    if (ctx->app) {
        strlcat(filename, " app=", len);
        strlcat(filename, ctx->app, len);
    }
    if (ctx->tcurl) {
        strlcat(filename, " tcUrl=", len);
        strlcat(filename, ctx->tcurl, len);
    }
    if (ctx->pageurl) {
        strlcat(filename, " pageUrl=", len);
        strlcat(filename, ctx->pageurl, len);
    }
    if (ctx->swfurl) {
        strlcat(filename, " swfUrl=", len);
        strlcat(filename, ctx->swfurl, len);
    }
    if (ctx->flashver) {
        strlcat(filename, " flashVer=", len);
        strlcat(filename, ctx->flashver, len);
    }
    if (ctx->conn) {
        char *sep, *p = ctx->conn;
        while (p) {
            strlcat(filename, " conn=", len);
            p += strspn(p, " ");
            if (!*p)
                break;
            sep = strchr(p, ' ');
            if (sep)
                *sep = '\0';
            strlcat(filename, p, len);

            if (sep)
                p = sep + 1;
        }
    }
    if (ctx->playpath) {
        strlcat(filename, " playpath=", len);
        strlcat(filename, ctx->playpath, len);
    }
    if (ctx->live)
        strlcat(filename, " live=1", len);
    if (ctx->subscribe) {
        strlcat(filename, " subscribe=", len);
        strlcat(filename, ctx->subscribe, len);
    }
    if (ctx->client_buffer_time) {
        strlcat(filename, " buffer=", len);
        strlcat(filename, ctx->client_buffer_time, len);
    }
    if (ctx->swfurl || ctx->swfverify) {
        strlcat(filename, " swfUrl=", len);

        if (ctx->swfverify) {
            strlcat(filename, ctx->swfverify, len);
            strlcat(filename, " swfVfy=1", len);
        } else {
            strlcat(filename, ctx->swfurl, len);
        }
    }

    RTMP_Init(r);
    if (!RTMP_SetupURL(r, filename)) {
        rc = ERROR_SETUP;
        goto fail;
    }

   // if (flags & WRITE_FLAGS)
        RTMP_EnableWrite(r);

    rc = RTMP_Connect(r, NULL);
    if(!rc) {
        rc = ERROR_CONNECT;
        goto fail;
    }

    rc = RTMP_ConnectStream(r,0);
    if(!rc) {
        rc = RTMP_ReconnectStream(r,0);
        if(!rc) {
            rc = ERROR_CONNECT_STREAM;
            goto fail;
        }
    }
/*
    if (ctx->buffer_size >= 0 && (flags & WRITE_FLAGS)) {
        int tmp = ctx->buffer_size;
        setsockopt(r->m_sb.sb_socket, SOL_SOCKET, SO_SNDBUF, &tmp, sizeof(tmp));
    }
*/
    return 0;
fail:
    //free(ctx->temp_filename);
    if (rc)
        RTMP_Close(r);

    return rc;
}

int rtmp_write(LibRTMPContext *ctx , const char *buf, int size)
{
#ifdef _KSY_DEBUG
    if(ctx->fd!=-1)
        return write(ctx->fd, buf,size);
#endif // _KSY_DEBUG
    RTMP *r = &ctx->rtmp;
    long nRet =  RTMP_Write(r, buf, size);
	rtmp_log(RTMP_LOGINFO,"need to write size = %d\n",size);
    rtmp_log(RTMP_LOGINFO,"realy write size = %d \n",nRet);
    return nRet;
}

int rtmp_read(LibRTMPContext *ctx , char *buf, int size)
{
    RTMP *r = &ctx->rtmp;
    return RTMP_Read(r, buf, size);
}

int rtmp_read_pause(LibRTMPContext *ctx, int pause)
{
    RTMP *r = &ctx->rtmp;

    if (!RTMP_Pause(r, pause))
        return ERROR_UNKNOWN;
    return 0;
}

int64_t rtmp_read_seek(LibRTMPContext *ctx, int64_t timestamp)
{
    RTMP *r = &ctx->rtmp;

    if (!RTMP_SendSeek(r, timestamp))
        return ERROR_UNKNOWN;
    return timestamp;
}

void write_w8(char* buf, int b)
{
    buf[0] = b;
}

void write_w16(char* buf, int val)
{
    buf[0] = (uint8_t)(val>>8);
    buf[1] = (uint8_t) val;
}

void write_w24(char* buf, int val)
{
    buf[0] = (uint8_t)(val>>16);
    buf[1] = (uint8_t)(val>>8);
    buf[2] = (uint8_t) val;
}

void write_w32(char* buf, int val)
{
    buf[0] = (uint8_t)(val>>24);
    buf[1] = (uint8_t)(val>>16);
    buf[2] = (uint8_t)(val>>8);
    buf[3] = (uint8_t) val;
}

int find_start_code_h264(const char* buf, int size)
{
    int i, code = 0;
    for(i=0;i<size;i++)
    {
            code = (code << 8) + buf[i];
            if ((code & 0xffffff00) == 0x100)
                return i;
    }
    return -1;
}

int find_start_code_adts(const char* buf, int size)
{
    int i, code = 0;
    for(i=0;i<size;i++)
    {
            code = (code << 8) | (buf[i] & 0xFF);
            if ((code & 0x0000FFF0) == 0xFFF0)
                return i;
    }
    return -1;
}

int pack_flv(char* outbuf, const char* inbuf, int insize, int  pts, int iskeyframe, int packtype)
{
    char* ptr = outbuf;
    //tag type
    if(packtype==FLV_VIDEO)
    {
        write_w8(ptr,FLV_VIDEO);
    }
    else if(packtype==FLV_AUDIO)
    {
        write_w8(ptr,FLV_AUDIO);
    }
    else
    {
        return -1;
    }
    ptr++;

    //datasize
    if(packtype==FLV_VIDEO)
    {
        write_w24(ptr,insize+5+4);
    }
    else
    {
        write_w24(ptr,insize+2);
    }
    ptr+=3;

    //timestamp
    write_w24(ptr, (pts & 0xFFFFFF));
    ptr += 3;

    //timestamp extended
    write_w8(ptr, ((pts >> 24) & 0x7F));
    ptr++;

    //stream id
    write_w24(ptr,0);
    ptr+=3;

    if(packtype==FLV_VIDEO)
    {
        //FrameType & CodecID
        write_w8(ptr,  iskeyframe?0x17:0x27);
        ptr++;
        //AVCPacketType
        write_w8(ptr,  1);
        ptr++;
        //composition time
        write_w24(ptr,  0);
        ptr+=3;
    }
    else
    {
        write_w8(ptr,  iskeyframe&0xFF );
        ptr++;
        write_w8(ptr,  1);
        ptr++;
    }

    memcpy(ptr,inbuf,insize);
    ptr+=insize;

    //tag size
    write_w32(ptr,ptr-outbuf);
    ptr+=4;

    return ptr - outbuf;
}

int video_send_sps_pps(LibRTMPContext *ctx)
{
    int ret;
    int datasize = 5 + 5 + 3 + ctx->sps_pps.sps_size + 3 + ctx->sps_pps.pps_size;
    int size = 11 + datasize + 4;
   char* outbuf = malloc(size+MALLOC_PENDDING);
   char* ptr = outbuf;
    //tag type
    write_w8(ptr,FLV_VIDEO);
    ptr++;
    //data size
    write_w24(ptr, datasize);
    ptr += 3;
    //timestamp
    write_w24(ptr, 0);
    ptr += 3;
    //timestamp extended
    write_w8(ptr, 0);
    ptr++;
    //stream id
    write_w24(ptr,0);
    ptr+=3;

    //FrameType & CodecID
    write_w8(ptr,  0x17);// (FLV_AVC << 4 )| FLV_AVC
    ptr++;
    //AVCPacketType
    write_w8(ptr,  0);
    ptr++;
    //composition time
    write_w24(ptr,  0);
    ptr+=3;
//spspps
    write_w8(ptr,0x01);
    ptr++;
    write_w8(ptr,0x42);
    ptr++;
    write_w8(ptr,0x80);
    ptr++;
    write_w8(ptr,0x0B);
    ptr++;
    write_w8(ptr,0xFF);
    ptr++;
    write_w8(ptr,0xE1);
    ptr++;

//sps
    write_w16(ptr,  ctx->sps_pps.sps_size);
    ptr+=2;
    memcpy(ptr,ctx->sps_pps.sps,ctx->sps_pps.sps_size);
    ptr+=ctx->sps_pps.sps_size;
//pps
    write_w8(ptr,0x01);
    ptr++;
    write_w16(ptr,  ctx->sps_pps.pps_size);
    ptr+=2;
    memcpy(ptr,ctx->sps_pps.pps,ctx->sps_pps.pps_size);
    ptr+=ctx->sps_pps.pps_size;

//tag size
    write_w32(ptr,ptr-outbuf);
    ptr+=4;

    ret =  rtmp_write(ctx,outbuf,ptr-outbuf);
    if(ret>0)
        ctx->sps_pps.sended = 1;
    free(outbuf);
    return ret;
}

int video_pack_flv_and_send(LibRTMPContext *ctx, const char *buf, int size, int iskey, int64_t pts)
{
    int ret = -1;
    int outbufsize = 0;
    char* outbuf = NULL;
    //send sps & pps first
    if(!ctx->sps_pps.sended)
    {
        if(ctx->sps_pps.sps==NULL || ctx->sps_pps.pps==NULL)
            return ret;
        if( (ret=video_send_sps_pps(ctx)) < 0)
            return ret;
    }
    if(outbuf==NULL)
        outbuf = malloc(size + 24  + MALLOC_PENDDING);
    if(ctx->first_pts==-1)
        ctx->first_pts = pts;
    outbufsize = pack_flv(outbuf, buf, size, pts - ctx->first_pts, iskey, FLV_VIDEO);
    if(outbufsize>0)
        ret =  rtmp_write(ctx,outbuf,outbufsize);
    else
        ret = outbufsize;
    free(outbuf);
    return ret;
}

int paser_adts(LibRTMPContext *ctx, const char* buf, int size)
{
    const char* ptr = buf;
    char profile =  ((ptr[1] & 0xC0) >> 6) + 1;
    char sample_index = ((ptr[1] & 0x3C) >> 2);
    char channel = ((ptr[1] & 0x01) << 2) | ((ptr[2] & 0xC0) >> 6);
    ctx->aac.ph_len = (ptr[0] & 0x01) ? 7 : 9;

    ctx->aac.header[0] =  ((profile & 0x1F) << 3) | ((sample_index & 0x0F) >> 1);
    ctx->aac.header[1] =  ((sample_index & 0x01) << 7) | ((channel & 0x0F) << 3);

    ctx->aac.type =  (FLV_AAC | ( (sample_index - 1) << 2) | FLV_SAMPLE_16B | channel);
    ctx->aac.pb_len = (((ptr[2] & 0x03) << 11) | ((ptr[3] << 3)) | ((ptr[4] & 0xE0) >> 5 ))  - ctx->aac.ph_len;
    return ctx->aac.pb_len;
}

int audio_send_aac_header(LibRTMPContext *ctx)
{
    int ret, datasize = 4;
    int size = 11 + datasize + 4;
    char* outbuf = malloc(size+MALLOC_PENDDING);
    char* ptr = outbuf;

    //tag type
    write_w8(ptr,FLV_AUDIO);
    ptr++;
    //data size
    write_w24(ptr, datasize);
    ptr += 3;
    //timestamp
    write_w24(ptr, 0);
    ptr += 3;
    //timestamp extended
    write_w8(ptr, 0);
    ptr++;
    //stream id
    write_w24(ptr,0);
    ptr+=3;

    //data
    //FLV_CODECID_AAC | FLV_SAMPLERATE_44100HZ | FLV_SAMPLESSIZE_16BIT | FLV_STEREO
    write_w8(ptr, ctx->aac.type & 0xFF);
    ptr++;
    //AVCPacketType
    write_w8(ptr,  0);
    ptr++;

    write_w8(ptr,ctx->aac.header[0]);
    ptr++;
    write_w8(ptr,ctx->aac.header[1]);
    ptr++;

//tag size
    write_w32(ptr,ptr-outbuf);
    ptr+=4;

    ret =  rtmp_write(ctx,outbuf,ptr-outbuf);
    if(ret>0)
        ctx->aac.sended = 1;
    free(outbuf);
    return ret;
}

int audio_pack_flv_and_send(LibRTMPContext *ctx, const char *buf, int size, int64_t pts)
{
    int ret = -1;
    int outbufsize = 0;
    char* outbuf = NULL;
    //send sps & pps first
    if(!ctx->aac.sended)
    {
        audio_send_aac_header(ctx);
    }
    if(outbuf==NULL)
        outbuf = malloc(11 + 2 + size + 4  + MALLOC_PENDDING);
    if(ctx->first_pts==-1)
        ctx->first_pts = pts;
    outbufsize = pack_flv(outbuf, buf, size, pts - ctx->first_pts, ctx->aac.type, FLV_AUDIO);
    if(outbufsize>0)
        ret =  rtmp_write(ctx,outbuf,outbufsize);
    else
        ret = outbufsize;
    free(outbuf);
    return ret;
}

int rtmp_write_audio(LibRTMPContext *ctx, const char *buf, int size, int64_t pts)
{
    int ret, start, next = 0;
    start = find_start_code_adts(buf,size);
    if(start==-1)
    {
        //?? not adts byte stream ...
        return -1;
    }
    do
    {
        start += next;
        paser_adts(ctx, buf+start, size- start);
        start += (ctx->aac.ph_len - 1);
        ret = audio_pack_flv_and_send(ctx, buf + start , ctx->aac.pb_len, pts);
        start += ctx->aac.pb_len;
        next = find_start_code_adts(buf + start,size - start);
    } while(next>0);
    return ret;
}

int rtmp_write_video(LibRTMPContext *ctx, const char *buf, int size, int64_t pts)
{
    int type, nalu_size, next = 0, ret = 0;
    int start = find_start_code_h264(buf,size);
    if(start==-1)
    {
        //???what happen? it is not h264 bitstream?
        // what should i DO ?
        return -1;
    }
    do
    {
        start += next;
        next = find_start_code_h264(buf + start ,size - start) ;
        if(next<0)
            nalu_size = size - start;
        else {
            if(buf[ start + next - 4] == 0)
                nalu_size = next -  4;
            else
                nalu_size = next -  3;
        }
        type = buf[start] & 0x1F;
        if(type==NAL_SPS)
        {
            ctx->sps_pps.sps_size = nalu_size;
            if(ctx->sps_pps.sps!=NULL)
                free(ctx->sps_pps.sps);
            ctx->sps_pps.sps = malloc(nalu_size + MALLOC_PENDDING);
            memcpy(ctx->sps_pps.sps,buf+start,nalu_size);
        }
        else if(type==NAL_PPS)
        {
            ctx->sps_pps.pps_size = nalu_size;
            if(ctx->sps_pps.pps!=NULL)
                free(ctx->sps_pps.pps);
            ctx->sps_pps.pps = malloc(nalu_size + MALLOC_PENDDING);
            memcpy(ctx->sps_pps.pps,buf+start,nalu_size);
        }
        else if(type==NAL_SLICE || type==NAL_IDR_SLICE)
        {
            ret = video_pack_flv_and_send(ctx,buf+start,nalu_size, type==NAL_IDR_SLICE?FLV_KEYFRAME:FLV_NONKEYFRAME, pts);
        }
    }while(next > 0);
    return ret;
}
