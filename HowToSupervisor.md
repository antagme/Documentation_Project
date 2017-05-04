# Supervisor Process Control System

## Why i choose Supervisor

According to how Docker Containers works , we should start only with 1 process. If you only need a _Service_ inside the Container , the best way to configure , is to configure to start with _Service_ Binary the Container so then have the PID 1 this _Service_ to control with _Docker Commands_.
But in my case , i will run more than 1 process in a Container.So i decided to use a process Manager for this work.
According _Docker_ Official Documentation , _Supervisor_ is one of the posibilities for this purpose
