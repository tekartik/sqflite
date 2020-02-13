package com.tekartik.sqflite;

import androidx.test.rule.ActivityTestRule;

import com.tekartik.sqfliteexample.EmbeddingV1Activity;

import org.junit.Rule;
import org.junit.runner.RunWith;

import dev.flutter.plugins.e2e.FlutterRunner;

@RunWith(FlutterRunner.class)
public class EmbeddingV1ActivityTest {
    @Rule
    public ActivityTestRule<EmbeddingV1Activity> rule = new ActivityTestRule<>(EmbeddingV1Activity.class);
}