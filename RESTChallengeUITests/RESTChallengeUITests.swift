//
//  RESTChallengeUITests.swift
//  RESTChallengeUITests
//
//  End-to-end UI tests. The app is launched in UI-test mode (UITEST_MODE=1),
//  which substitutes a mock authentication manager for the Auth0 web flow and
//  serves captured JSONPlaceholder fixture data through a mock URL protocol.
//
//  Because the real password entry happens on Auth0's hosted web page, the
//  password the "user types" is supplied via the UITEST_PASSWORD launch
//  environment variable; the mock validates it against the test account
//  (Sincere@april.biz / Crashes.receded.bond).
//

import XCTest

final class RESTChallengeUITests: XCTestCase {

    private let validEmail = "Sincere@april.biz"
    private let validPassword = "Crashes.receded.bond"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func launchApp(password: String,
                           users: String = "ok",
                           todos: String = "ok") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "UITEST_MODE": "1",
            "UITEST_PASSWORD": password,
            "UITEST_USERS": users,
            "UITEST_TODOS": todos,
        ]
        app.launch()
        return app
    }

    private func logIn(_ app: XCUIApplication, email: String) {
        let usernameField = app.textFields["usernameField"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 10),
                      "Username field should be visible on launch")
        usernameField.tap()
        usernameField.typeText(email)
        app.buttons["loginButton"].tap()
    }

    private func waitForText(_ element: XCUIElement,
                             toContain text: String,
                             timeout: TimeInterval = 10) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let fulfilled = XCTWaiter.wait(
            for: [expectation(for: predicate, evaluatedWith: element)],
            timeout: timeout
        )
        XCTAssertEqual(fulfilled, .completed,
                       "Expected \"\(element.label)\" to contain \"\(text)\"")
    }

    // MARK: - Tests

    /// Logging in with valid credentials shows the account's name and email
    /// and enables Manage Tasks.
    func testSuccessfulLogin() throws {
        let app = launchApp(password: validPassword)
        logIn(app, email: validEmail)

        XCTAssertTrue(app.staticTexts["Leanne Graham"].waitForExistence(timeout: 10),
                      "Account name should be displayed after login")
        XCTAssertTrue(app.staticTexts["Sincere@april.biz"].exists,
                      "Account email should be displayed after login")
        XCTAssertEqual(app.buttons["loginButton"].label, "Log Out")
        XCTAssertTrue(app.buttons["manageTasksButton"].isEnabled)
    }

    /// Toggling the completed state of two tasks enables Post Changes;
    /// posting shows the not-implemented alert and dims the button again.
    func testToggleTwoTasksAndPostChanges() throws {
        let app = launchApp(password: validPassword)
        logIn(app, email: validEmail)

        let manageTasks = app.buttons["manageTasksButton"]
        XCTAssertTrue(manageTasks.waitForExistence(timeout: 10))
        XCTAssertTrue(manageTasks.isEnabled)
        manageTasks.tap()

        let postChanges = app.buttons["postChangesButton"]
        XCTAssertTrue(postChanges.waitForExistence(timeout: 10))
        XCTAssertFalse(postChanges.isEnabled, "Post Changes should start dimmed")

        // Fixture tasks 1 and 2 (both pending): flip each to Completed.
        for title in ["delectus aut autem", "quis ut nam facilis et officia qui"] {
            let row = app.staticTexts[title]
            XCTAssertTrue(row.waitForExistence(timeout: 10), "Task row \"\(title)\" should be listed")
            row.tap()

            let statusPicker = app.segmentedControls["taskStatusPicker"]
            XCTAssertTrue(statusPicker.waitForExistence(timeout: 10))
            statusPicker.buttons["Completed"].tap()

            app.navigationBars["Task Details"].buttons.element(boundBy: 0).tap()
        }

        XCTAssertTrue(postChanges.isEnabled, "Post Changes should enable after edits")
        postChanges.tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertTrue(alert.label.contains("Posting changes is not yet implemented"))
        alert.buttons["OK"].tap()

        XCTAssertFalse(postChanges.isEnabled, "Post Changes should dim after acknowledging")
    }

    /// Logging in with bogus credentials surfaces the authentication error
    /// in the login status message.
    func testBogusLoginShowsError() throws {
        let app = launchApp(password: "Watch.your.data")
        logIn(app, email: "hacker@gmail.com")

        waitForText(app.staticTexts["loginStatusMessage"],
                    toContain: "Wrong email or password")
        XCTAssertEqual(app.buttons["loginButton"].label, "Log In")
        XCTAssertFalse(app.buttons["manageTasksButton"].isEnabled)
    }

    /// A successful login followed by a /todos timeout shows the error in
    /// the dashboard's status area.
    func testTodosTimeoutShowsDashboardError() throws {
        let app = launchApp(password: validPassword, todos: "timeout")
        logIn(app, email: validEmail)

        let manageTasks = app.buttons["manageTasksButton"]
        XCTAssertTrue(manageTasks.waitForExistence(timeout: 10))
        manageTasks.tap()

        let errorMessage = app.staticTexts["dashboardErrorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 10))
        waitForText(errorMessage, toContain: "timed out")
    }

    /// A successful login with malformed /users and /todos payloads surfaces
    /// decode errors on both screens without crashing.
    func testMalformedPayloadsShowErrors() throws {
        let app = launchApp(password: validPassword, users: "malformed", todos: "malformed")
        logIn(app, email: validEmail)

        // Account lookup fails, so the status message reports it and the
        // username field stays visible.
        waitForText(app.staticTexts["loginStatusMessage"],
                    toContain: "Could not load account info")

        // Authentication itself succeeded, so the dashboard is reachable;
        // the todos decode failure lands in the dashboard's status area.
        let manageTasks = app.buttons["manageTasksButton"]
        XCTAssertTrue(manageTasks.isEnabled)
        manageTasks.tap()

        let errorMessage = app.staticTexts["dashboardErrorMessage"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 10))
        waitForText(errorMessage, toContain: "Could not decode the server response")
    }
}
