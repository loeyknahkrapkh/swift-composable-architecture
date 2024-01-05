import ComposableArchitecture
import SwiftUI

@Reducer
struct App {
  // ...
}

struct AppView: View {
  @Bindable var store: StoreOf<App>

  var body: some View {
    NavigationStack(
      path: $store.scope(state: \.path, action: \.path)
    ) {
      SyncUpsListView(
        store: store.scope(state: \.syncUpsList, action: \.syncUpsList)
      )
    } destination: { store in
      switch store.state {
      case .detail:
        if let store = store.scope(state: \.detail, action: \.detail) {
          SyncUpDetail(store: store)
        }
      }
    }
  }
}