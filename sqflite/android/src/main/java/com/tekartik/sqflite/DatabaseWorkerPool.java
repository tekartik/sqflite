package com.tekartik.sqflite;

import java.util.LinkedList;
import java.util.ListIterator;

/**
 * Pool that assigns {@link DatabaseTask} to {@link DatabaseWorker}.
 */
public class DatabaseWorkerPool {

    final String name;
    final int numberOfWorkers;
    final int priority;

    final LinkedList<DatabaseTask> waitingList = new LinkedList<>();
    final LinkedList<DatabaseWorker> idleWorkers = new LinkedList<>();
    final LinkedList<DatabaseWorker> busyWorkers = new LinkedList<>();

    DatabaseWorkerPool(String name, int numberOfWorkers, int priority) {
        this.name = name;
        this.numberOfWorkers = numberOfWorkers;
        this.priority = priority;
    }

    synchronized void start() {
        for (int i = 0; i < numberOfWorkers; i++) {
            DatabaseWorker worker = new DatabaseWorker(name + i, priority);
            worker.start(
                    () -> {
                        onWorkerIdle(worker);
                    });
            idleWorkers.add(worker);
        }
    }

    synchronized void quit() {
        for (DatabaseWorker worker : idleWorkers) {
            worker.quit();
        }
        for (DatabaseWorker worker : busyWorkers) {
            worker.quit();
        }
    }

    // Posts a new task.
    //
    // Tasks of the same database are run in FIFO manner and they are not running simultaneously
    // for any given moment. Tasks of different databases could run simultaneously but not
    // necessarily in FIFO manner.
    synchronized void post(Database database, Runnable runnable) {
        DatabaseTask task = new DatabaseTask(database, runnable);

        // Try finding a worker that is already working for the database of the task.
        //
        // Only run this branch when no tasks are waiting. Otherwise waiting tasks could get
        // starved if following tasks keep cutting in the queue.
        if (waitingList.isEmpty()) {
            for (DatabaseWorker worker : busyWorkers) {
                if (worker.accept(task)) {
                    return;
                }
            }
        }

        // Wait in the list.
        waitingList.add(task);

        // Try finding a idle worker.
        for (DatabaseWorker worker : idleWorkers) {
            findTasksForIdleWorker(worker);
            if (worker.isBusy()) {
                busyWorkers.add(worker);
                idleWorkers.remove(worker);
                return;
            }
        }
    }

    private synchronized void onWorkerIdle(DatabaseWorker worker) {
        findTasksForIdleWorker(worker);
        if (worker.isIdle()) {
            busyWorkers.remove(worker);
            idleWorkers.add(worker);
        }
    }

    private synchronized void findTasksForIdleWorker(DatabaseWorker worker) {
        ListIterator<DatabaseTask> iter = waitingList.listIterator();

        // Find the first task that can be accepted by the worker.
        while (iter.hasNext()) {
            if (worker.accept(iter.next())) {
                iter.remove();
                break;
            }
        }

        // If a following task is accepted by the worker, keep moving it to the worker.
        while (iter.hasNext()) {
            if (worker.accept(iter.next())) {
                iter.remove();
            } else {
                break;
            }
        }
    }
}
