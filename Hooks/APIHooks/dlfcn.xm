#import "../SharedDefine.pch"
#import <dlfcn.h>
int (*old_dladdr)(const void *, Dl_info *);
void * (*old_dlopen)(const char * __path, int __mode);
void * (*old_dlsym)(void * __handle, const char * __symbol);

void * new_dlsym(void * handle, const char* symbol) {
	if ([CallStackInspector wasDirectlyCalledByApp] && symbol != NULL) {
		CallTracer *tracer = [[CallTracer alloc] initWithClass:@"dlfcn" andMethod:@"dlsym"];
        [tracer addArgFromPlistObject:[NSString stringWithUTF8String:symbol] withKey:@"Symbol"];
        [traceStorage saveTracedCall: tracer];
        [tracer release];
	}
	return old_dlsym(handle,symbol);

}
void * new_dlopen(const char * __path, int __mode) {
	if ([CallStackInspector wasDirectlyCalledByApp] && __path != NULL) {
		CallTracer *tracer = [[CallTracer alloc] initWithClass:@"dlfcn" andMethod:@"dlopen"];
        [tracer addArgFromPlistObject:[NSString stringWithUTF8String: __path] withKey:@"Path"];
        [tracer addArgFromPlistObject:[NSNumber numberWithInt:__mode] withKey:@"Mode"];
        [traceStorage saveTracedCall: tracer];
        [tracer release];
	}
	return old_dlopen(__path,__mode);

}
int new_dladdr(const void * addr, Dl_info * info){
    int ret = old_dladdr(addr, info);
    if ([CallStackInspector wasDirectlyCalledByApp] && info->dli_fname != nil && info->dli_sname != nil) {
    	CallTracer *tracer = [[CallTracer alloc] initWithClass:@"dlfcn" andMethod:@"dladdr"];
        [tracer addArgFromPlistObject:[NSString stringWithUTF8String:info->dli_fname] withKey:@"PathOfObject"];
        [tracer addArgFromPlistObject:[NSString stringWithUTF8String:info->dli_sname] withKey:@"NameOfNearestSymbol"];
        [traceStorage saveTracedCall: tracer];
        [tracer release];
    }
    return ret;
}

extern void init_dlfcn_hook() {
    MSHookFunction((void*)dladdr,(void*)new_dladdr, (void**)&old_dladdr);
    MSHookFunction((void*)dlsym,(void*)new_dlsym, (void**)&old_dlsym);
    MSHookFunction((void*)dlopen,(void*)new_dlopen, (void**)&old_dlopen);
}
