enum TaskStatus
{
    Failed = 0
    Completed = 1
    CompletedWithErrors = 10
    Running = 20
    Idle = 30
}

#TODO rethink this naming
enum EventAction
{
    Failed = 0
    Completed = 1
    Started = 2
    Cancelled = 3
}

enum Action
{
    Stop = 0
    Start = 1
    Restart = 2
    Remove = 3
    Add = 4
    Copy = 5
    Read = 6
}