import InlineSnapshotTesting
import TestCases
import XCTest

@MainActor
final class iOS16_17_OldContainsNewTests: BaseIntegrationTests {
  override func setUp() {
    super.setUp()
    self.app.buttons["iOS 16 + 17"].tap()
    self.app.buttons["Old containing new"].tap()
    self.clearLogs()
    //SnapshotTesting.isRecording = true
  }

  func testIncrementDecrement() {
    self.app.buttons.matching(identifier: "Increment").element(boundBy: 0).tap()
    XCTAssertEqual(self.app.staticTexts["1"].exists, true)
    self.assertLogs {
      """
      BasicsView.body
      NewContainsOldTestCase.body
      StoreOf<BasicsView.Feature>.deinit
      StoreOf<BasicsView.Feature>.init
      StoreOf<BasicsView.Feature>.init
      StoreOf<BasicsView.Feature>.scope
      StoreOf<NewContainsOldTestCase.Feature>.scope
      """
    }

    self.app.buttons.matching(identifier: "Decrement").element(boundBy: 0).tap()
    XCTAssertEqual(self.app.staticTexts["-1"].exists, true)
    self.assertLogs {
      """
      BasicsView.body
      NewContainsOldTestCase.body
      StoreOf<BasicsView.Feature>.deinit
      StoreOf<BasicsView.Feature>.deinit
      StoreOf<BasicsView.Feature>.init
      StoreOf<BasicsView.Feature>.init
      StoreOf<BasicsView.Feature>.scope
      StoreOf<NewContainsOldTestCase.Feature>.scope
      """
    }
  }

  func testObserveChildCount() {
    self.app.buttons["Toggle observe child count"].tap()
    XCTAssertEqual(self.app.staticTexts["Child count: 0"].exists, true)
    self.assertLogs {
      """
      BasicsView.body
      NewContainsOldTestCase.body
      StoreOf<BasicsView.Feature>.deinit
      StoreOf<BasicsView.Feature>.init
      StoreOf<BasicsView.Feature>.init
      StoreOf<BasicsView.Feature>.scope
      StoreOf<NewContainsOldTestCase.Feature>.scope
      """
    }
  }

  func testIncrementChild_ObservingChildCount() {
    self.app.buttons["Toggle observe child count"].tap()
    self.clearLogs()
    self.app.buttons.matching(identifier: "Increment").element(boundBy: 1).tap()
    XCTAssertEqual(self.app.staticTexts["1"].exists, true)
    XCTAssertEqual(self.app.staticTexts["Child count: 1"].exists, true)
    self.assertLogs {
      """
      BasicsView.body
      BasicsView.body
      NewContainsOldTestCase.body
      StoreOf<BasicsView.Feature>.deinit
      StoreOf<BasicsView.Feature>.deinit
      StoreOf<BasicsView.Feature>.init
      StoreOf<BasicsView.Feature>.init
      StoreOf<BasicsView.Feature>.scope
      StoreOf<NewContainsOldTestCase.Feature>.scope
      """
    }
  }

  func testDeinit() {
    self.app.buttons["Toggle observe child count"].tap()
    self.app.buttons.matching(identifier: "Increment").element(boundBy: 1).tap()
    self.clearLogs()
    self.app.buttons["iOS 16 + 17"].tap()
    self.assertLogs {
      """
      StoreOf<BasicsView.Feature>.deinit
      StoreOf<BasicsView.Feature>.deinit
      StoreOf<BasicsView.Feature>.deinit
      """
    }
  }
}