package com.chamelalaboratory.demo.flutter_event_channel;

import org.junit.Test;
import static org.junit.Assert.*;

public class ProgressGeneratorTest {

    @Test
    public void testValidInitialization() {
        ProgressGenerator generator = new ProgressGenerator(200, 100, false);
        assertEquals(200, generator.getUpdateIntervalMs());
        assertEquals(100, generator.getTotalCount());
        assertFalse(generator.isShouldSimulateError());
        assertEquals(1, generator.getCount());
        assertFalse(generator.isComplete());
    }

    @Test(expected = IllegalArgumentException.class)
    public void testInvalidIntervalTooSmall() {
        new ProgressGenerator(49, 100, false);
    }

    @Test(expected = IllegalArgumentException.class)
    public void testInvalidIntervalTooLarge() {
        new ProgressGenerator(10001, 100, false);
    }

    @Test(expected = IllegalArgumentException.class)
    public void testInvalidCountTooSmall() {
        new ProgressGenerator(200, 0, false);
    }

    @Test(expected = IllegalArgumentException.class)
    public void testInvalidCountTooLarge() {
        new ProgressGenerator(200, 1001, false);
    }

    @Test
    public void testProgressCalculationsAndIncrement() {
        ProgressGenerator generator = new ProgressGenerator(200, 10, false);
        assertEquals(0.1, generator.getProgressPercentage(), 0.0001);
        
        generator.increment();
        assertEquals(2, generator.getCount());
        assertEquals(0.2, generator.getProgressPercentage(), 0.0001);
    }

    @Test
    public void testCompletionBehavior() {
        ProgressGenerator generator = new ProgressGenerator(200, 2, false);
        assertFalse(generator.isComplete());

        generator.increment(); // count is 2
        assertFalse(generator.isComplete());

        generator.increment(); // count is 3 (exceeds totalCount)
        assertTrue(generator.isComplete());
    }

    @Test
    public void testSimulateErrorBehavior() {
        ProgressGenerator generatorWithError = new ProgressGenerator(200, 100, true);
        ProgressGenerator generatorWithoutError = new ProgressGenerator(200, 100, false);

        // Advance both to count 50
        for (int i = 1; i < 50; i++) {
            assertFalse(generatorWithError.shouldSimulateErrorNow());
            assertFalse(generatorWithoutError.shouldSimulateErrorNow());
            generatorWithError.increment();
            generatorWithoutError.increment();
        }

        assertEquals(50, generatorWithError.getCount());
        assertEquals(50, generatorWithoutError.getCount());

        assertTrue(generatorWithError.shouldSimulateErrorNow());
        assertFalse(generatorWithoutError.shouldSimulateErrorNow());
    }
}
