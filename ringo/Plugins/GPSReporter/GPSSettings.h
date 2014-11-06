



#define SECONDS_TO_SEND_POS_PERIODICALY 20*60  // Maximum time to wait before sending position to JS. default: 20*60, every 20 minutes
#define DISTANCE_FILTER 20  // do not fire position update if not moved more than DISTANCE_FILTER meters (default: 30)
#define MAX_TIME_FOR_POSITION_UPDATES 15  //give that seconds max to determine position. default: 5
#define MAX_TIME_FOR_FORCED_POSITION_UPDATES 15  //give more seconds max to determine position when we force it. default: 8


#define SECONDS_TO_SLEEP_IN_BACKGROUND_TASK 240 // default: 240

#define SECONDS_BEFORE_TERMINATION_TO_ACTIVATE_GPS SECONDS_TO_SLEEP_IN_BACKGROUND_TASK + 60 // default: SECONDS_TO_SLEEP_IN_BACKGROUND_TASK + 10

#define MAXIMAL_ACCEPTABLE_ACCURACY_TO_REPORT_RIGHT_AWAY 80 // report location right away if accuracy is better than this. default: 70meters
#define ACCURACY_TO_STOP_GETTING_BETTER_READING 35 // default: 80 - if we get result better than this - we stop trying to get even better accuracy

#define USER_SETTINGS_DICT_NAME @"LOKKI_LOW_BATTERY_MODE"
#define USER_SETTINGS_DICT_LOW_BATTERY_MODE_ENABLED @"LOW_BATTERY_MODE_ENABLED"
#define CRITICAL_BATTERY_LEVEL_TO_ENABLE_LOW_BATTERY_MODE 0.2 // default: 0.2. At which battery level (0..1) to enable low battery mode where we dont run in background

