exctl
=====

Project-specific command dispatcher using DRY and convention-over-configuration principles as much as possible.

So for a given project you will be able to create a command heirarchy (think `git *` or `gem *`- now you can make
`my-project *`) with the ability to detect and document (for command-line help as well as manpages) new tasks etc.

This allows you to have development-related tasks, packaging/installing/deployment-related tasks, and of course
runtime tasks (such as running the application).

Why? Because I've reimplemented this so many times for specific projects that I'm finally abstracting it.
