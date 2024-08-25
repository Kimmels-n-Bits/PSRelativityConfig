enum TaskStatus
{
    Failed = 0
    Completed = 1
    CompletedWithErrors = 10
    Running = 20
    Idle = 30
}

enum EventAction
{
    Failed = 0
    Completed = 1
    Started = 2
    Cancelled = 3
}