# EasyLogin Agent for Mac

This agent is in charge of sync with server. All the work related to change management should be done here.

A web socket is opened by the agent to allow change notifications (and not content) to be pushed by the server.

When the agent start and on each change notification, the agent should recover its updated record from `/db/devices` and work with `SyncSet` to select which records from `/db/users` and `/db/groups` should be stored as local object.

The notification itself does not contain any data. Local cache is readonly for all other consumer app, sync process can just replace everything without expecting any issue.
