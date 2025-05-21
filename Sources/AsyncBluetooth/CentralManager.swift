import CoreBluetooth

public typealias PeripheralDevice = (peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber)

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, visionOS 1.0, *)
final public class CentralManager: NSObject, CBCentralManagerDelegate {
  public var manager: CBCentralManager!
  private var scanStreamContinuation: AsyncThrowingStream<PeripheralDevice, any Error>.Continuation?
  private var updateStateStreamContinuation: AsyncStream<CBCentralManager>.Continuation!
  public var updateStateStream: AsyncStream<CBCentralManager>!
  private var disconnectStreamContinuation:  AsyncStream<Result<CBPeripheral, any Error>>.Continuation!
  public var disconnectStream: AsyncStream<Result<CBPeripheral, any Error>>!
  private var connectContinuation: [UUID: CheckedContinuation<CBPeripheral, any Error>] = [:]
  
  deinit {
    self.stopScan()
  }
  
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
    self.disconnectStream = AsyncStream { continuation in
      disconnectStreamContinuation = continuation
    }
  }
  
  public func centralManagerDidUpdateState(_ central: CBCentralManager) {
    self.updateStateStreamContinuation.yield(central)
  }
  
  public func scanForPeripherals(
    withServices serviceUUIDs: [CBUUID]? = nil,
    options: [String: Any]? = nil
  ) -> AsyncThrowingStream<PeripheralDevice, any Error> {
    self.manager.scanForPeripherals(withServices: serviceUUIDs, options: options)
    return AsyncThrowingStream { continuation in
      self.scanStreamContinuation = continuation
    }
  }
  
  public func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String : Any],
    rssi RSSI: NSNumber
  ) {
    self.scanStreamContinuation?.yield((peripheral, advertisementData, RSSI))
  }
  
  public func stopScan() {
    self.manager.stopScan()
    self.scanStreamContinuation?.finish()
  }
  
  @discardableResult
  public func connect(for peripheral: CBPeripheral, options: [String: Any]? = nil) async throws -> CBPeripheral {
    self.manager.connect(peripheral, options: options)
    return try await withCheckedThrowingContinuation { continuation in
      self.connectContinuation[peripheral.identifier] = continuation
    }
  }
  
  public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    self.connectContinuation[peripheral.identifier]?.resume(returning: peripheral)
  }
  
  public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
    if let error {
      self.connectContinuation[peripheral.identifier]?.resume(throwing: error)
    }
  }
  
  public func centralManager(
    _ central: CBCentralManager,
    didDisconnectPeripheral peripheral: CBPeripheral,
    error: (any Error)?
  ) {
    if let error {
      disconnectStreamContinuation.yield(.failure(error))
    } else {
      disconnectStreamContinuation.yield(.success(peripheral))
    }
  }
  
    }
  }
}
