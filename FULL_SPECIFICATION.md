* App Name : Live team activities 
* App Platform : macOS 26

* App Technologies : Swift, SwiftUI, UserNotifications, Braze


* Description : Live Team Activities is a macOS application that allows users to monitor and manage team activities in real-time. It provides a centralized platform for tracking tasks, deadlines, and visibility of tasks progress among team members.

* Features : The application consists of a manager app (valtaManager.app) and a team member app (valtaTeam.app). The manager app allows team leaders to create teams and assign activities to members in those teams, set deadlines, and monitor progress. The team member app enables members to trigger a activity completion event for their assigned activities and see a dashboard of all team activities, a log tab and notifications about the activities in the team they are a member of.

Manager Onboarding: When launching the manager app for the first time, users are guided through a setup process where they can create a new team by providing a team name and adding team members from a predefined list. This ensures that the team structure is established correctly from the outset.


Team Member Onboarding: On launching the app for the first time, users are prompted to  select their name from a predefined list of team members. This ensures that each user is correctly identified and associated with their respective team activities.

Activity definition and requirements :

* Logic Flows : 

The manager creates a new activity by specifying the activity name, description, assigned team member, and deadline. Once created, the activity is added to the team's dashboard and notifications are sent to the assigned members. The activity status is "team member pending" until the team member acknowledges the activity start, at which point the status changes to "running" and the activity start is sent to all team members

Both the manager and team members can view the activity dashboard, which displays all ongoing activities, their statuses, and deadlines. Team members can update the status of their assigned activities, which automatically reflects on the manager's dashboard.

The manager can trigger a activity completion event for a team member's assigned activity. 

The deadlines for each activity are monitored each minute, once a activity has passed the deadline without a manager completion it gets automatically transitioned to status being updated to completed, outcome to overrun and color code to red unless there is a pending completion event from the team member in which case the activity status is updated to pending.

If a activity reaches deadline and it has the "team member pending" status set the status to canceled and outcome to empty

Activity status:
running
completed
canceled
manager pending
team member pending

Activity priority (p) list follows :
p0 - Critical
p1 - High
p2 - Medium
p3 - Low

Activity outcomes list follows :
ahead - green
jit - yellow
overrun - red

Exceptions : 

For p0 activities if the activity outcome is on-time the activity color code is red.


Activity notifications are as follows :

[Manager name] has assigned p[0/1/2/3] activity on [date, time] with deadline [date, time] to you, please start the activity: [Activity name].

The notification text above gets sent when a manager assigns a new activity to a team member.

[Team member name]’s p[0/1/2/3] activity has started on [date, time] with deadline [date, time] for [Activity name].

The notification text above gets sent a specific notification to all team members. team member can trigger a activity completion event for their assigned activity which gets sent to the manager for approval.e manager can chose to approve or reject the completion event. Upon approval, the activity status is updated to completed on both the manager's and team member's dashboards.The format is as folowing :

[Team member name]’s p[0/1/2/3] activity has completed [ahead/jit/overrun] with status [red/green/amber]

The notification text above gets sent to all team members once the manager has completed an activity.

Team Member Onboarding Requirements:

* Once a team member has logged in and has their FCM token saved in Firebase, that member should no longer be selectable in the OnboardingView. The member card should be visually greyed out/disabled to indicate they are already logged in on another device.

* After the first successful member selection, the selected member's identity should be persisted in UserDefaults so that subsequent app launches do not require re-selection.
