package com.chamelalaboratory.demo.flutter_event_channel;

/// A simple, testable class that encapsulates the state, validation, 
/// and progress calculation logic for the EventChannel progress stream.
public class ProgressGenerator {
    private final int updateIntervalMs;
    private final int totalCount;
    private final boolean shouldSimulateError;
    private int count = 1;

    public ProgressGenerator(int updateIntervalMs, int totalCount, boolean shouldSimulateError) {
        if (updateIntervalMs < 50 || updateIntervalMs > 10000) {
            throw new IllegalArgumentException("updateIntervalMs must be between 50 and 10000 ms");
        }
        if (totalCount < 1 || totalCount > 1000) {
            throw new IllegalArgumentException("totalCount must be between 1 and 1000");
        }
        this.updateIntervalMs = updateIntervalMs;
        this.totalCount = totalCount;
        this.shouldSimulateError = shouldSimulateError;
    }

    public int getUpdateIntervalMs() {
        return updateIntervalMs;
    }

    public int getTotalCount() {
        return totalCount;
    }

    public boolean isShouldSimulateError() {
        return shouldSimulateError;
    }

    public int getCount() {
        return count;
    }

    public boolean isComplete() {
        return count > totalCount;
    }

    public boolean shouldSimulateErrorNow() {
        return shouldSimulateError && count == 50;
    }

    public double getProgressPercentage() {
        return (double) count / totalCount;
    }

    public void increment() {
        count++;
    }

    public void reset() {
        count = 1;
    }
}
