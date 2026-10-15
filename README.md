## Installation

Clone https://github.com/DuncanMC/RESTChallenge.git
open project in Xcode
Build and run


The credentials in Auth0.plist should enable the app to get to the test Auth0 identity providerI set up. You may need to be a member of my development team, “WareTo LLC” in order for the authentication to work, since that is one of the parameters used in validating the app with Auth0

I may have to add you as a developer under my Developer ID, or we may have to just walk through the app in Xcode on Zoom.

## Third party dependencies

The app uses Okta’s Auth0 service and their iOS framework, whiprovidemported as a Swift package. That brings along OKTA’s SimpleKeychain, another package that provide lightweight secure storage for authentication tokens.

## Usage:

I set up 3 test logins to the demo app:

| Email | Password | Username in users API |
| :--- | :---: | ---: |
| Sincere@april.biz | Crashes.receded.bond | Bret |
| Nathan@yesenia.net | Smoking.ruler.betrayed | Samantha |
| JoeBobFred@gmail.com | Comedic.heated.mongrel | none (not in users, but defined in Auth0) |

Once in the app, enter one of the above usernames and click “Log in”. You’ll have to click “Continue” to authorize the app to open an embedded browser for the PKCE authentication. Then enter the password and click “continue” to complete the login.

The Auth0 authentication manager passes the entered username (which is an email address) to the account screen, where it looks up that email address in the /users API. Once you are logged in, the app tries to match the username field from Auth0 and the email field from the /users payload it is able to make a match. If it finds a match it looks up your userID and allows you to look at the tasks that belong to you, the current user. If it is unable to match an email address, it will still work, but it won’t be able to filter tasks to those that belong to the current user.


Click “Manage Tasks” to go to the Task dashboard. By default, the list of tasks is filtered to just those created by the current user. Turn off the “My Tasks Only” switch to view all tasks. (That seemed like a nice enhancement.)

You can also view all tasks, only completed tasks, or only pending tasks.

Tap on any task in the Tasks dashboard to view the details for that task. Currently the only change you can make is to toggle tasks between Pending and Completed status. Future versions should allow editing other fields from the task record, and possible creating/deleting tasks (if desired)

## Automated tests:

There are a few automated UI tests to test “happy path”, malformed API responses, and network timeouts. To run them select the “Test Navigator”, (command-6 shortcut key) select the “RestChallengeUITests group, and click the small run diamond on the right to trigger the tests. It’s difficult or impossible to do UI tests that drive web interfaces, so the tests use a mocked Authentication Manager to simulate the responses of the Auth0 SDK, as well as mocked data for the /users and /todos endpoints. That test data is defined in a file called “TestFixtures.swift”.

## Misc considerations

There is no back end to POST changes to. For now, there is a “Post changes” button on the Task dashboard that is enabled once you have made changes. It displays an alert that posting changes is not yet implemented, and then clears the “changed” flag on the tasks list. Once there is an actual server to accept changes, the app will probably post changes to a task in the background as soon as you close a task and report problems (like timeouts, API failures, or conflicts) if they occur, and quitely clear the “changed” status on the tasks list once the POST succeeds.

The Log Out button should display a warning if you have pending changes, but that is not current implemented.

The state data is currently only held in memory, and is lost if you quit the app. It should really persist changes to a file or local database so that they are not lost in the event of a network error, app crash, or other abnormal condition.


## AI use:

I made **heavy** use of Claude to write the code. I prompted it to set up the separation of concerns (separating view, state, and business logic, and an Authentication Manager to manage the Auth0 authentication, and a NetworkingManager to manage the /users and /todos GETs.) and gave it specific guidance on how to architect the app, but most of the code was written by Claude in the interest of time. 

## Next steps:

The API endpoints are simple-minded, and lack any way to detect collisions, figure out change history, etc. The mocked JSON also lacks support for POSTing changes, so saving changes is completely missing. 

There is also no local storage of records. If the user terminates the app, the changes would be lost (even if there was a way to POST changes)

The iOS would need to support POST calls to the tasks API at a minimum. To resolve conflicts there needs to be some sort of marker on the task records (adding "record last changed" and "record posted" UNIX timestamps to the task records would work.) On a GET, the server would include the saved "record last changed" date for the task. On a POST, the server would make sure the record from it's database did not have a newer "record last changed" date. If that was ok, it would save "record posted" to "record last changed" and commit the changes. On a post, if the server found thatthe stored task's  "record last changed" was newer than the "record last changed" sent in the post, it would flag that somebody else had changed the record. I would probably also add a "record changed by" user ID, since right now, users can edit other user's tasks. ) The payload is small enough that I would probably post each task when the user goes back to the task list. I'd close the task detail view immediately, and re-display it with a status message if there was an error posting it. If a POST conflict is detected we should probably implement a conflict resolution screen where the server sends the updated record and it shows both versions to the user, asking them to resolve the conflict. Further, the server side should record conflicts and change history.

For production use, the /users and /tasks APIs should require some sort of authentication. The user's login through Auth0 is the only protection currently. There is no POST/PUT/DELETE, so the only risk is unauthorized access to confidential information. The risks would be higher if the endpoints supported destructive calls. (As mentioned in the prompt, the APIs could be protected with OAuth access tokens. That would require additional handshaking and token management, similar to the current login token management)

(The prompt mentions using OAuth 2. Access tokens, which would address security for the RESTful endpoints.)

## Architecture discussion

Using Microsoft Entra ID would require substantial rework/replacement of the current Auth0 based authentication, but would provide single signon (SSO) ability and a more integrated user experience without round trips to an in-app browser for authentication (assuming the use of SAML to pass credentials around.) It would also enable multi-factor authentication, offering improved security.  As mentioned above, OAuth 2.0 access tokens would provide protection to the RESTful services the app consumes, which are currently totally unprotected.

