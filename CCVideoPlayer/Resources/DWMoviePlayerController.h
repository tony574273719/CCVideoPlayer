#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>


typedef void (^DWErrorBlock)(NSError *error);
typedef void(^DWMoivePlayerGetPlayUrlsBlock)(NSDictionary *playUrls);

@interface DWMoviePlayerController : MPMoviePlayerController

@property (copy, nonatomic)NSString *userId;
@property (copy, nonatomic)NSString *videoId;
@property (copy, nonatomic)NSString *key;
@property (assign, nonatomic)NSTimeInterval timeoutSeconds;

@property (copy, nonatomic)DWMoivePlayerGetPlayUrlsBlock getPlayUrlsBlock;


/**
 *  @brief 获取视频播放信息或播放过程中发生错误或失败时，回调该block。可以在该block内更新UI，如更改视频播放状态。
 */
@property (copy, nonatomic)DWErrorBlock failBlock;

/**
 *  @brief drmServer 绑定的端口。
 *
 *  若你使用了DRM视频加密播放服务，则必须先启动 DWDrmServer，并在调用 prepareToPlay 之前，设置 drmServerPort 设置为 DWDrmServer 绑定的端口。
 */
@property (assign, nonatomic)UInt16 drmServerPort;

/**
 *  @brief 正在使用的 contentURL。
 *
 *  若播放url的扩展名为pcm，则 originalContentURL为： http://127.0.0.1:xxx/pcm?url=urlEncode(currentContentURl)， 否则 originalContentURL 同 contentURL。
 */
@property (strong, nonatomic, readonly)NSURL *originalContentURL;

/**
 *  @brief 初始化播放对象
 *
 *  @param userId      用户ID，不能为nil
 *  @param videoId     即将播放的视频ID，不能为nill
 *  @param key         用户秘钥，不能为nil
 *
 *  @return 播放对象
 */
- (id)initWithUserId:(NSString *)userId andVideoId:(NSString *)videoId key:(NSString *)key;

/**
 *  @brief 初始化播放对象
 *
 *  @param userId      用户ID，不能为nil
 *  @param key         用户秘钥，不能为nil
 *
 *  @return 播放对象
 */
- (id)initWithUserId:(NSString *)userId key:(NSString *)key;

/**
 *  @brief 开始请求视频播放信息。
 */
- (void)startRequestPlayInfo;

/**
 *  @brief 取消请求视频播放信息
 */
- (void)cancelRequestPlayInfo;

@end