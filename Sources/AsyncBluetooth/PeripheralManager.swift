import CoreBluetooth

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, visionOS 1.0, *)
final public class PeripheralManager: NSObject, CBPeripheralManagerDelegate {
  public var manager: CBPeripheralManager!
  private var updateStateStreamContinuation: AsyncStream<CBPeripheralManager>.Continuation!
  public var updateStateStream: AsyncStream<CBPeripheralManager>!
  private var addContinuation: CheckedContinuation<CBService, any Error>?
  private var startAdvertisingContinuation: CheckedContinuation<Void, any Error>?
  
  public init(
    queue: dispatch_queue_t? = nil,
    options: [String: Any]? = nil
  ) {
    super.init()
    self.manager = .init(
      delegate: self,
      queue: queue,
      options: options
    )
    self.updateStateStream = AsyncStream { continuation in
      updateStateStreamContinuation = continuation
    }
  }
  
  public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    self.updateStateStreamContinuation.yield(peripheral)
  }
  
  @discardableResult
  public func add(_ service: CBMutableService) async throws -> CBService {
    manager.add(service)
    return try await withCheckedThrowingContinuation { coninuation in
      self.addContinuation = coninuation
    }
  }
  
  public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: (any Error)?) {
    if let error {
      self.addContinuation?.resume(throwing: error)
    } else {
      self.addContinuation?.resume(returning: service)
    }
  }
  
  public func remove(_ service: CBMutableService) {
    manager.remove(service)
  }
  
  public func removeAllServices() {
    manager.removeAllServices()
  }
  
  public func startAdvertising(_ advertisementData: [String : Any]?) async throws {
    manager.startAdvertising(advertisementData)
    return try await withCheckedThrowingContinuation { continuation in
      self.startAdvertisingContinuation = continuation
    }
  }
  
  public func stopAdvertising() {
    manager.stopAdvertising()
  }
  
  public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
    if let error {
      self.startAdvertisingContinuation?.resume(throwing: error)
    } else {
      self.startAdvertisingContinuation?.resume(returning: ())
    }
  }
}
