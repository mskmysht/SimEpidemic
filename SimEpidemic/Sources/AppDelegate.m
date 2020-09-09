//
//  AppDelegate.m
//  SimEpidemic
//
//  Created by Tatsuo Unemi on 2020/04/28.
//  Copyright © 2020 Tatsuo Unemi. All rights reserved.
//

#import "AppDelegate.h"
#import "Document.h"
#ifdef NOGUI
#import "../../SimEpidemicSV/noGUI.h"
#else
#import "Preferences.h"
#endif
#import <sys/time.h>

NSInteger nCores = 1;
unsigned long current_time_us(void) {
	static long startTime = -1;
	struct timeval tv;
	gettimeofday(&tv, NULL);
	if (startTime < 0) startTime = tv.tv_sec;
	return (tv.tv_sec - startTime) * 1000000L + tv.tv_usec;
}
void error_msg(NSObject *obj, NSWindow *window, BOOL critical) {
	NSString *message = 
		[obj isKindOfClass:NSString.class]? (NSString *)obj :
		[obj isKindOfClass:NSError.class]? [NSString stringWithFormat:
			@"%@ (%ld)", ((NSError *)obj).localizedDescription, ((NSError *)obj).code] :
		[obj isKindOfClass:NSException.class]? ((NSException *)obj).reason :
		[NSString stringWithFormat:@"%@ (%@)", obj.description, obj.className];
#ifdef NOGUI
	fprintf(stderr, "%s\n", message.UTF8String);
	if (critical) [NSApp terminate:nil];
#else
	NSAlert *alt = NSAlert.new;
	alt.alertStyle = critical? NSAlertStyleCritical : NSAlertStyleWarning;
	alt.messageText = message;
	if (window != nil) [alt beginSheetModalForWindow:window
		completionHandler:^(NSModalResponse returnCode)
			{ if (critical) [NSApp terminate:nil]; }];
	else {
		[alt runModal];
		if (critical) [NSApp terminate:nil];
	}
#endif
}
void confirm_operation(NSString *text, NSWindow *window, void (^proc)(void)) {
#ifdef NOGUI
	proc();
#else
	NSAlert *alt = NSAlert.new;
	alt.alertStyle = NSAlertStyleWarning;
	alt.messageText = NSLocalizedString(@"This operation cannot be undone.", nil);
	alt.informativeText = NSLocalizedString(text, nil);
	[alt addButtonWithTitle:@"OK"];
	[alt addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
	[alt beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode) {
		if (returnCode == NSAlertFirstButtonReturn) proc();
	}];
#endif
}
void show_anime_steps(NSTextField *txtField, NSInteger steps) {
	txtField.stringValue = (steps == 1)?
		NSLocalizedString(@"Draw in each step.", nil) :
		[NSString stringWithFormat:NSLocalizedString(@"AnimeStepsFormat", nil), steps];
}
NSObject *get_propertyList_from_url(NSURL *url, Class class, NSWindow *window) {
	NSError *error;
	NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
	if (data == nil) { error_msg(error, window, NO); return nil; }
	NSObject *object = [url.pathExtension isEqualToString:@"json"]?
	[NSJSONSerialization JSONObjectWithData:data options:0 error:&error] :
	[NSPropertyListSerialization propertyListWithData:data
		options:NSPropertyListImmutable format:NULL error:&error];
	if (object == nil) { error_msg(error, window, NO); return nil; }
	if (class != NULL && ![object isKindOfClass:class])
		{ error_msg(@"Property is invalid class.", window, NO); return nil; }
	return object;
}
void load_property_data(NSArray<NSString *> *fileTypes, NSWindow *window,
	Class class, void (^block)(NSURL *url, NSObject *)) {
	NSOpenPanel *op = NSOpenPanel.openPanel;
	op.allowedFileTypes = fileTypes;
	[op beginSheetModalForWindow:window completionHandler:^(NSModalResponse result) {
		if (result != NSModalResponseOK) return;
		NSObject *object = get_propertyList_from_url(op.URL, class, window);
		if (object != nil) block(op.URL, object);
	}];
}
void save_property_data(NSString *fileType, NSWindow *window, NSObject *object) {
	NSSavePanel *sp = NSSavePanel.savePanel;
	sp.allowedFileTypes = @[fileType, @"json"];
	[sp beginSheetModalForWindow:window completionHandler:^(NSModalResponse result) {
		if (result != NSModalResponseOK) return;
		NSError *error;
		NSData *data = [sp.URL.pathExtension isEqualToString:@"json"]?
		[NSJSONSerialization dataWithJSONObject:object options:0 error:&error] :
		[NSPropertyListSerialization dataWithPropertyList:object
			format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
		if (data == nil) { error_msg(error, window, NO); return; }
		if (![data writeToURL:sp.URL options:0 error:&error])
			error_msg(error, window, NO);
	}];
}
NSString *keyAnimeSteps = @"animeSteps";
static ParamInfo paramInfo[] = {
	{ ParamTypeFloat, @"infectionProberbility", {.f = { 50., 0., 100.}}},
	{ ParamTypeFloat, @"infectionDistance", {.f = { 4., 1., 20.}}},
	{ ParamTypeFloat, @"distancingStrength", {.f = { 50., 0., 100.}}},
	{ ParamTypeFloat, @"distancingObedience", {.f = { 20., 0., 100.}}},
	{ ParamTypeFloat, @"mobilityFrequency", {.f = { 50., 0., 100.}}},
	{ ParamTypeFloat, @"contactTracing", {.f = { 20., 0., 100.}}},
	{ ParamTypeFloat, @"testDelay", {.f = { 1., 0., 10.}}},
	{ ParamTypeFloat, @"testProcess", {.f = { 1., 0., 10.}}},
	{ ParamTypeFloat, @"testInterval", {.f = { 2., 0., 10.}}},
	{ ParamTypeFloat, @"testSensitivity", {.f = { 70., 0., 100.}}},
	{ ParamTypeFloat, @"testSpecificity", {.f = { 99.8, 0., 100.}}},
	{ ParamTypeFloat, @"subjectAsymptomatic", {.f = { 1., 0., 100.}}},
	{ ParamTypeFloat, @"subjectSymptomatic", {.f = { 99., 0., 100.}}},

	{ ParamTypeDist, @"mobilityDistance", {.d = { 10., 30., 80.}}},
	{ ParamTypeDist, @"incubation", {.d = { 1., 5., 14.}}},
	{ ParamTypeDist, @"fatality", {.d = { 4., 16., 20.}}},
	{ ParamTypeDist, @"recovery", {.d = { 4., 10., 40.}}},
	{ ParamTypeDist, @"immunity", {.d = { 30, 180., 360.}}},

	{ ParamTypeInteger, @"populationSize", {.i = { 10000, 100, 999900}}},
	{ ParamTypeInteger, @"worldSize", {.i = { 360, 10, 999999}}},
	{ ParamTypeInteger, @"mesh", {.i = { 18, 1, 999}}},
	{ ParamTypeInteger, @"initialInfected", {.i = { 4, 1, 999}}},
	{ ParamTypeInteger, @"stepsPerDay", {.i = { 4, 1, 999}}},
	{ ParamTypeNone, nil }
};
NSInteger defaultAnimeSteps = 1;
RuntimeParams defaultRuntimeParams, userDefaultRuntimeParams;
WorldParams defaultWorldParams, userDefaultWorldParams;
NSArray<NSString *> *paramKeys, *paramNames;
NSArray<NSNumberFormatter *> *paramFormatters;
NSDictionary<NSString *, NSString *> *paramKeyFromName;
NSDictionary<NSString *, NSNumber *> *paramIndexFromKey;
NSDictionary *param_dict(RuntimeParams *rp, WorldParams *wp) {
	NSMutableDictionary *md = NSMutableDictionary.new;
	CGFloat *fp = (rp != NULL)? &rp->PARAM_F1 : NULL;
	DistInfo *dp = (rp != NULL)? &rp->PARAM_D1 : NULL;
	NSInteger *ip = (wp != NULL)? &wp->PARAM_I1 : NULL;
	for (ParamInfo *p = paramInfo; p->key != nil; p ++) switch (p->type) {
		case ParamTypeFloat: if (fp != NULL) md[p->key] = @(*(fp ++)); break;
		case ParamTypeDist: if (dp != NULL) {
			md[p->key] = @[@(dp[0].min), @(dp[0].max), @(dp[0].mode)];
			dp ++;
		} break;
		case ParamTypeInteger: if (ip != NULL) md[p->key] = @(*(ip ++));
		default: break;
	}
	return [NSDictionary dictionaryWithDictionary:md];
}
#define IDX_D 1000
#define IDX_I 2000
void set_params_from_dict(RuntimeParams *rp, WorldParams *wp, NSDictionary *dict) {
	CGFloat *fp = (rp != NULL)? &rp->PARAM_F1 : NULL;
	DistInfo *dp = (rp != NULL)? &rp->PARAM_D1 : NULL;
	NSInteger *ip = (wp != NULL)? &wp->PARAM_I1 : NULL;
	for (NSString *key in dict.keyEnumerator) {
		NSNumber *idxNum = paramIndexFromKey[key];
		if (idxNum == nil) continue;
		NSInteger index = idxNum.integerValue;
		if (index < IDX_D) { if (fp != NULL) fp[index] = [dict[key] doubleValue]; }
		else if (index < IDX_I) { if (dp != NULL) {
			NSArray<NSNumber *> *arr = dict[key];
			dp[index - IDX_D] = (DistInfo){
				arr[0].doubleValue, arr[1].doubleValue, arr[2].doubleValue};
		}} else if (ip != NULL) ip[index - IDX_I] = [dict[key] integerValue];
	}
}
#define RGB3(r,g,b) ((r<<16)|(g<<8)|b)
NSInteger defaultStateRGB[N_COLORS] = {
	RGB3(39,85,154), RGB3(246,214,0), RGB3(250,48,46), RGB3(32,120,100), RGB3(182,182,182),
	RGB3(0,0,0), RGB3(64,0,0), RGB3(51,51,51), RGB3(255,255,255)
}, stateRGB[N_COLORS];
NSColor *stateColors[N_COLORS] = {nil}, *warpColors[NHealthTypes];
NSString *colKeys[] = {
	@"colorSusceptible", @"colorAsymptomatic", @"colorSymptomatic",
	@"colorRecovered", @"colorDied",
	@"colorBackgournd", @"colorHospital", @"colorCemetery", @"colorText"
};
CGFloat warpOpacity = DEFAULT_WARP_OPACITY;
CGFloat panelsAlpha = DEFAULT_PANELS_ALPHA;
BOOL makePanelChildWindow = DEFAULT_CHILD_WIN;
NSString *keyWarpOpacity = @"warpOpacity", *keyPanelsAlpha = @"panelsAlpha",
	*keyChildWindow = @"makePanelChildWindow";
void setup_colors(void) {
	NSColorSpace *colSpc = NSColorSpace.genericRGBColorSpace;
	for (NSInteger i = 0; i < N_COLORS; i ++) {
		CGFloat cols[4];
		for (NSInteger j = 0; j < 3; j ++)
			cols[j] = ((stateRGB[i] >> (8 * (2 - j))) & 0xff) / 255.;
		cols[3] = 1.;
		stateColors[i] = [NSColor colorWithColorSpace:colSpc components:cols count:4];
		if (i < NHealthTypes) {
			cols[3] = warpOpacity;
			warpColors[i] = [NSColor colorWithColorSpace:colSpc components:cols count:4];
		}
	}
}
@implementation AppDelegate
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	nCores = NSProcessInfo.processInfo.processorCount;
	NSInteger nF = 0, nD = 0, nI = 0;
	for (ParamInfo *p = paramInfo; p->key != nil; p ++) switch (p->type) {
		case ParamTypeFloat: (&defaultRuntimeParams.PARAM_F1)[nF ++] = p->v.f.defaultValue; break;
		case ParamTypeDist: (&defaultRuntimeParams.PARAM_D1)[nD ++] = (DistInfo){
			p->v.d.defMin, p->v.d.defMax, p->v.d.defMode}; break;
		case ParamTypeInteger: (&defaultWorldParams.PARAM_I1)[nI ++] = p->v.i.defaultValue;
		default: break;
	}
	NSInteger nn = nF + nD + nI;
	NSString *keys[nn], *names[nF];
	NSNumber *indexes[nn];
	NSNumberFormatter *formatters[nF + nI], *fmt;
	for (NSInteger i = 0; i < nn; i ++) {
		ParamInfo *p = paramInfo + i;
		keys[i] = p->key;
		switch (p->type) {
			case ParamTypeFloat: indexes[i] = @(i);
			names[i] = NSLocalizedString(p->key, nil);
			fmt = NSNumberFormatter.new;
			fmt.allowsFloats = YES;
			fmt.minimum = @(p->v.f.minValue);
			fmt.maximum = @(p->v.f.maxValue);
			fmt.minimumFractionDigits = fmt.maximumFractionDigits =
			fmt.minimumIntegerDigits = 1;
			formatters[i] = fmt;
			break;
			case ParamTypeDist: indexes[i] = @(i - nF + IDX_D); break;
			case ParamTypeInteger: indexes[i] = @(i - nF - nD + IDX_I);
			fmt = NSNumberFormatter.new;
			fmt.allowsFloats = NO;
			fmt.minimum = @(p->v.i.minValue);
			fmt.maximum = @(p->v.i.maxValue);
			fmt.usesGroupingSeparator = YES;
			fmt.groupingSize = 3;
			formatters[i - nD] = fmt;
			default: break;
		}
	}
	paramKeys = [NSArray arrayWithObjects:keys count:nn];
	paramNames = [NSArray arrayWithObjects:names count:nF];
	paramFormatters = [NSArray arrayWithObjects:formatters count:nF + nI];
	paramKeyFromName = [NSDictionary dictionaryWithObjects:keys forKeys:names count:nF];
	paramIndexFromKey = [NSDictionary dictionaryWithObjects:indexes forKeys:keys count:nn];
	memcpy(&userDefaultRuntimeParams, &defaultRuntimeParams, sizeof(RuntimeParams));
	memcpy(&userDefaultWorldParams, &defaultWorldParams, sizeof(WorldParams));
	memcpy(stateRGB, defaultStateRGB, sizeof(stateRGB));
#ifdef NOGUI
	[theDocuments addObject:Document.new];
	[NSThread detachNewThreadWithBlock:^{ connection_thread(); }];
#else
	NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
	NSNumber *num;
	NSArray<NSNumber *> *arr;
	if ((num = [ud objectForKey:keyAnimeSteps])) defaultAnimeSteps = num.integerValue;
	for (NSInteger i = 0; i < N_COLORS; i ++)
		if ((num = [ud objectForKey:colKeys[i]])) stateRGB[i] = num.integerValue;
	for (NSInteger i = 0; i < nF; i ++)
		if ((num = [ud objectForKey:paramInfo[i].key]))
			(&userDefaultRuntimeParams.PARAM_F1)[i] = num.doubleValue;
	for (NSInteger i = 0; i < nD; i ++)
		if ((arr = [ud objectForKey:paramInfo[i + nF].key]))
			(&userDefaultRuntimeParams.PARAM_D1)[i] = (DistInfo){
				arr[0].doubleValue, arr[1].doubleValue, arr[2].doubleValue};
	for (NSInteger i = 0; i < nI; i ++)
		if ((num = [ud objectForKey:paramInfo[i + nF + nD].key]))
			(&userDefaultWorldParams.PARAM_I1)[i] = num.integerValue;
	if ((num = [ud objectForKey:keyWarpOpacity])) warpOpacity = num.doubleValue;
	if ((num = [ud objectForKey:keyPanelsAlpha])) panelsAlpha = num.doubleValue;
	if ((num = [ud objectForKey:keyChildWindow])) makePanelChildWindow = num.boolValue;
	setup_colors();
	NSBezierPath.defaultLineJoinStyle = NSLineJoinStyleBevel;
#endif
}
#ifndef NOGUI
- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls {
	NSArray<Document *> *docs = NSDocumentController.sharedDocumentController.documents;
	if (docs.count == 0) return;
	Document *doc = docs[0];
	BOOL scen = YES, params = YES;
	for (NSURL *url in urls) {
		NSString *ext = url.pathExtension;
		if (scen && [ext isEqualToString:@"sEpS"])
			{ [doc openScenarioFromURL:url]; scen = NO; }
		else if (params && [ext isEqualToString:@"sEpP"])
			{ [doc openParamsFromURL:url]; params = NO; }
	}
}
- (void)applicationWillTerminate:(NSNotification *)notification {
	NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
	if (defaultAnimeSteps == 1) [ud removeObjectForKey:keyAnimeSteps];
	else [ud setInteger:defaultAnimeSteps forKey:keyAnimeSteps];
	for (NSInteger i = 0; i < N_COLORS; i ++) {
		if (stateRGB[i] == defaultStateRGB[i]) [ud removeObjectForKey:colKeys[i]];
		else [ud setInteger:stateRGB[i] forKey:colKeys[i]];
	}
	if (warpOpacity == DEFAULT_WARP_OPACITY)
		[ud removeObjectForKey:keyWarpOpacity];
	else [ud setDouble:warpOpacity forKey:keyWarpOpacity];
	if (panelsAlpha == DEFAULT_WARP_OPACITY)
		[ud removeObjectForKey:keyPanelsAlpha];
	else [ud setDouble:panelsAlpha forKey:keyPanelsAlpha];
	if (makePanelChildWindow == DEFAULT_CHILD_WIN)
		[ud removeObjectForKey:keyChildWindow];
	else [ud setBool:makePanelChildWindow forKey:keyChildWindow];
}
- (IBAction)openPreferencePanel:(id)sender {
	static Preferences *pref = nil;
	if (pref == nil) pref = Preferences.new;
	[pref showWindow:sender];
}
#endif
@end
