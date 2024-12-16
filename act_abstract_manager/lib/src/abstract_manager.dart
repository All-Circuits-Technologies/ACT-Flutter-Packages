// Copyright (c) 2020. BMS Circuits

/// Typedef for a manager factory
typedef S ClassFactory<S>();

/// Builder for creating managers
abstract class ManagerBuilder<T extends AbstractManager> {
  /// A factory to create a manager instance
  final ClassFactory<T> factory;

  /// Class constructor
  ManagerBuilder(this.factory) : assert(factory != null);

  /// Asynchronous factory which build and initialize a manager
  Future<T> asyncFactory() async {
    T manager = factory();

    await manager.initManager();

    return manager;
  }

  /// Abstract method which list the manager dependence on others managers
  Iterable<Type> dependsOn();
}

/// Abstract class for all the application managers
abstract class AbstractManager {
  /// Default constructor
  AbstractManager();

  /// Asynchronous initialization of the manager
  Future<void> initManager();

  /// Default dispose for manager
  Future<void> dispose() => null;
}
