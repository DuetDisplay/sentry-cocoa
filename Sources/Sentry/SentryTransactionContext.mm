#import "SentryTransactionContext.h"
#import "SentryLog.h"
#include "SentryProfilingConditionals.h"
#import "SentrySpanContext+Private.h"
#import "SentryThread.h"
#include "SentryThreadHandle.hpp"
#import "SentryTraceOrigins.h"
#import "SentryTransactionContext+Private.h"

NS_ASSUME_NONNULL_BEGIN

static const auto kSentryDefaultSamplingDecision = kSentrySampleDecisionUndecided;

@implementation SentryTransactionContext

#pragma mark - Public

- (instancetype)initWithName:(NSString *)name operation:(NSString *)operation
{
    return [self initWithName:name operation:operation sampled:kSentrySampleDecisionUndecided];
}

- (instancetype)initWithName:(NSString *)name
                   operation:(NSString *)operation
                     sampled:(SentrySampleDecision)sampled
{
    return [self initWithName:name
                   nameSource:kSentryTransactionNameSourceCustom
                    operation:operation
                       origin:SentryTraceOriginManual
                      sampled:sampled];
}

- (instancetype)initWithName:(NSString *)name
                   operation:(NSString *)operation
                     traceId:(SentryId *)traceId
                      spanId:(SentrySpanId *)spanId
                parentSpanId:(nullable SentrySpanId *)parentSpanId
               parentSampled:(SentrySampleDecision)parentSampled
{
    return [self initWithName:name
                   nameSource:kSentryTransactionNameSourceCustom
                    operation:operation
                       origin:SentryTraceOriginManual
                      traceId:traceId
                       spanId:spanId
                 parentSpanId:parentSpanId
                parentSampled:parentSampled];
}

#pragma mark - Private

- (instancetype)initWithName:(NSString *)name
                  nameSource:(SentryTransactionNameSource)source
                   operation:(NSString *)operation
                      origin:(NSString *)origin
{
    if (self = [super initWithOperation:operation
                                 origin:origin
                                sampled:kSentryDefaultSamplingDecision]) {
        [self commonInitWithName:name source:source parentSampled:kSentryDefaultSamplingDecision];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                  nameSource:(SentryTransactionNameSource)source
                   operation:(NSString *)operation
                      origin:(NSString *)origin
                     sampled:(SentrySampleDecision)sampled
{
    if (self = [super initWithOperation:operation origin:origin sampled:sampled]) {
        [self commonInitWithName:name source:source parentSampled:kSentryDefaultSamplingDecision];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                  nameSource:(SentryTransactionNameSource)source
                   operation:(nonnull NSString *)operation
                      origin:(NSString *)origin
                     traceId:(SentryId *)traceId
                      spanId:(SentrySpanId *)spanId
                parentSpanId:(nullable SentrySpanId *)parentSpanId
               parentSampled:(SentrySampleDecision)parentSampled
{
    if (self = [super initWithTraceId:traceId
                               spanId:spanId
                             parentId:parentSpanId
                            operation:operation
                      spanDescription:nil
                               origin:origin
                              sampled:kSentryDefaultSamplingDecision]) {
        [self commonInitWithName:name source:source parentSampled:parentSampled];
    }
    return self;
}

- (instancetype)initWithName:(NSString *)name
                  nameSource:(SentryTransactionNameSource)source
                   operation:(NSString *)operation
                      origin:(NSString *)origin
                     traceId:(SentryId *)traceId
                      spanId:(SentrySpanId *)spanId
                parentSpanId:(nullable SentrySpanId *)parentSpanId
                     sampled:(SentrySampleDecision)sampled
               parentSampled:(SentrySampleDecision)parentSampled
{
    if (self = [super initWithTraceId:traceId
                               spanId:spanId
                             parentId:parentSpanId
                            operation:operation
                      spanDescription:nil
                               origin:origin
                              sampled:sampled]) {
        _name = [NSString stringWithString:name];
        _nameSource = source;
        self.parentSampled = parentSampled;
        [self getThreadInfo];
    }
    return self;
}

- (void)getThreadInfo
{
    // This method crashes currently with macOS 11
#if TARGET_OS_MAC && !TARGET_OS_IOS && !TARGET_OS_WATCH && !TARGET_OS_TV
    // Check the operating system version first
    NSOperatingSystemVersion osVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSInteger majorVersion = osVersion.majorVersion;

    // Return without doing anything if the OS is macOS 11
    if (majorVersion == 11) {
        return;
    }
#endif
#if SENTRY_TARGET_PROFILING_SUPPORTED
    const auto threadID = sentry::profiling::ThreadHandle::current()->tid();
    self.threadInfo = [[SentryThread alloc] initWithThreadId:@(threadID)];
#endif
}

#if SENTRY_TARGET_PROFILING_SUPPORTED
- (SentryThread *)sentry_threadInfo
{
    return self.threadInfo;
}
#endif

- (void)commonInitWithName:(NSString *)name
                    source:(SentryTransactionNameSource)source
             parentSampled:(SentrySampleDecision)parentSampled
{
    _name = [NSString stringWithString:name];
    _nameSource = source;
    self.parentSampled = parentSampled;
    [self getThreadInfo];
    SENTRY_LOG_DEBUG(@"Created transaction context with name %@", name);
}

@end

NS_ASSUME_NONNULL_END
