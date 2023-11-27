import SwiftUI

public protocol ViewAction<ViewAction> {
  associatedtype ViewAction
  static func view(_ action: ViewAction) -> Self
}

@dynamicMemberLookup
public struct _StoreBinding<State, Action> {
  fileprivate let wrappedValue: Store<State, Action>

  public subscript<Member>(
    dynamicMember keyPath: KeyPath<State, Member>
  ) -> _StoreBinding<Member, Action> {
    _StoreBinding<Member, Action>(
      wrappedValue: self.wrappedValue.scope(state: keyPath, action: \.self)
    )
  }

  public func sending(_ action: CaseKeyPath<Action, State>) -> Binding<State> {
    Binding(
      get: { self.wrappedValue.withState { $0 } },
      set: { newValue, transaction in
        BindingLocal.$isActive.withValue(true) {
          _ = self.wrappedValue.send(action(newValue), transaction: transaction)
        }
      }
    )
  }
}

extension Binding {
  @_disfavoredOverload
  public subscript<State: ObservableState, Action, Member>(
    dynamicMember keyPath: KeyPath<State, Member>
  ) -> _StoreBinding<Member, Action>
  where Value == Store<State, Action> {
    _StoreBinding(wrappedValue: self.wrappedValue.scope(state: keyPath, action: \.self))
  }
}

@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
extension Bindable {
  @_disfavoredOverload
  public subscript<State: ObservableState, Action, Member>(
    dynamicMember keyPath: KeyPath<State, Member>
  ) -> _StoreBinding<Member, Action>
  where Value == Store<State, Action> {
    _StoreBinding(wrappedValue: self.wrappedValue.scope(state: keyPath, action: \.self))
  }
}

extension BindingAction {
  public static func set<Value: Equatable & Sendable>(
    _ keyPath: WritableKeyPath<Root, Value>,
    _ value: Value
  ) -> Self where Root: ObservableState {
    .init(
      keyPath: keyPath,
      set: { $0[keyPath: keyPath] = value },
      value: AnySendable(value),
      valueIsEqualTo: { ($0 as? AnySendable)?.base as? Value == value }
    )
  }

  public static func ~= <Value>(
    keyPath: WritableKeyPath<Root, Value>,
    bindingAction: Self
  ) -> Bool where Root: ObservableState {
    keyPath == bindingAction.keyPath
  }
}

extension BindableAction where State: ObservableState {
  public static func set<Value: Equatable & Sendable>(
    _ keyPath: WritableKeyPath<State, Value>,
    _ value: Value
  ) -> Self {
    self.binding(.set(keyPath, value))
  }
}

extension Store where State: ObservableState, Action: BindableAction, Action.State == State {
  public subscript<Value: Equatable>(
    dynamicMember keyPath: WritableKeyPath<State, Value>
  ) -> Value {
    get { self.observableState[keyPath: keyPath] }
    set { self.send(.binding(.set(keyPath, newValue))) }
  }
}

extension Store
where
  State: ObservableState,
  Action: ViewAction,
  Action.ViewAction: BindableAction,
  Action.ViewAction.State == State
{
  public subscript<Value: Equatable>(
    dynamicMember keyPath: WritableKeyPath<State, Value>
  ) -> Value {
    get { self.observableState[keyPath: keyPath] }
    set { self.send(.view(.binding(.set(keyPath, newValue)))) }
  }
}

// TODO: Incorporate these checks into the properties above, instead.
extension Binding {
  @_disfavoredOverload
  public subscript<State: ObservableState, Action: BindableAction, Member: Equatable>(
    dynamicMember keyPath: WritableKeyPath<State, Member>
  ) -> Binding<Member>
  where Value == Store<State, Action>, Action.State == State {
    Binding<Member>(
      // TODO: Should this use `state/observableState`? It warns but could wrap with task local.
      get: { self.wrappedValue.stateSubject.value[keyPath: keyPath] },
      set: { newValue, transaction in
        BindingLocal.$isActive.withValue(true) {
          _ = self.transaction(transaction).wrappedValue.send(.binding(.set(keyPath, newValue)))
        }
      }
    )
  }

  @_disfavoredOverload
  public subscript<State: ObservableState, Action: ViewAction, Member: Equatable>(
    dynamicMember keyPath: WritableKeyPath<State, Member>
  ) -> Binding<Member>
  where
    Value == Store<State, Action>,
    Action.ViewAction: BindableAction,
    Action.ViewAction.State == State
  {
    Binding<Member>(
      get: { self.wrappedValue.state[keyPath: keyPath] },
      set: { newValue, transaction in
        BindingLocal.$isActive.withValue(true) {
          _ = self.transaction(transaction).wrappedValue.send(
            .view(.binding(.set(keyPath, newValue)))
          )
        }
      }
    )
  }
}