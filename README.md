#CCVideoPlayer
##说明：<br/>
基于CC视频的的二次开发，自定义view用xib减少代码量，实现大小屏手动/自动切换、AirPlay投屏、
##使用：<br/>
CourseContentMainController *vc = [[CourseContentMainController alloc] init];<br/>
vc.player = [[DWMoviePlayerController alloc] initWithUserId:DWACCOUNT_USERID andVideoId:CCVIDEOID key:DWACCOUNT_APIKEY];<br/>

