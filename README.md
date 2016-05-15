# TTTNotificationHub

![image](https://github.com/an-ttt/TTTNotificationHub/blob/master/TTTNotificationHub.gif)

TTTNotificationHub combine and improve with QQButton and XXYBang.
two steps：
```object-c
1. 
#import "TTTNotificationHub.h"

- (TTTNotificationHub *)notificationHub
{
    if (!_notificationHub) {
  
        _notificationHub = [[TTTNotificationHub alloc] initWithView:self.myLabel scale:0.7 offset:CGPointMake(-20, 20) maxInstance:50.0];
        
        __weak typeof(self) weak_self = self;
        _notificationHub.destoryBlock = ^() {
        };
    }
    
    return _notificationHub;
}

2.
[self.notificationHub setCountAndCheckZero:self.notificationHub.count + 1];
```

you must take care of importing Swift into Objective-C by yourself.

see more in demo.
