import CoreBluetooth

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, visionOS 1.0, *)
final public class Peripheral: NSObject, CBPeripheralDelegate {
  var peripheral: CBPeripheral!
  
  private var discoverServicesStreamContinuation: CheckedContinuation<[CBService]?, any Error>?
  private var discoverCharacteristicsStreamContinuation: [CBUUID: CheckedContinuation<[CBCharacteristic]?, any Error>] = [:]
  private var discoverDescriptorsStreamContinuation: [CBUUID: CheckedContinuation<[CBDescriptor]?, any Error>] = [:]
  private var discoverIncludedServicesStreamContinuation: [CBUUID: CheckedContinuation<[CBService]?, any Error>] = [:]
  private var readCharacteristicStreamContinuation: [CBUUID: CheckedContinuation<CBCharacteristicProperties, any Error>] = [:]
  private var writeForCharacteristicStreamContinuation: [CBUUID: CheckedContinuation<Void, any Error>] = [:]
  private var writeForDiscriptorStreamContinuation: [CBUUID: CheckedContinuation<Void, any Error>] = [:]
  public var newNameStream: AsyncStream<CBPeripheral>!
  private var newNameStreamContinuation: AsyncStream<CBPeripheral>.Continuation!
  
  public init(peripheral: CBPeripheral) {
    super.init()
    self.peripheral = peripheral
    self.peripheral.delegate = self
    self.newNameStream = AsyncStream { continuation in
      self.newNameStreamContinuation = continuation
    }
  }
  
  public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
    self.newNameStreamContinuation.yield(peripheral)
  }

  public func discoverServices(serviceIDs: [CBUUID]? = nil) async throws -> [CBService]? {
    peripheral.discoverServices(serviceIDs)
    return try await withCheckedThrowingContinuation { continuation in
      self.discoverServicesStreamContinuation = continuation
    }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
    if let error {
      self.discoverServicesStreamContinuation?.resume(throwing: error)
    } else {
      self.discoverServicesStreamContinuation?.resume(returning: peripheral.services)
    }
  }

  public func discoverCharacteristics(characteristicIDs: [CBUUID]?, for service: CBService) async throws -> [CBCharacteristic]? {
    peripheral.discoverCharacteristics(characteristicIDs, for: service)
    return try await withCheckedThrowingContinuation { continuation in
      self.discoverCharacteristicsStreamContinuation[service.uuid] = continuation
    }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
    if let error {
      self.discoverCharacteristicsStreamContinuation[service.uuid]?.resume(throwing: error)
    } else {
      self.discoverCharacteristicsStreamContinuation[service.uuid]?.resume(returning: service.characteristics)
    }
  }
  
  public func discoverDescriptors(for characteristic: CBCharacteristic) async throws -> [CBDescriptor]? {
    peripheral.discoverDescriptors(for: characteristic)
    return try await withCheckedThrowingContinuation { continuation in
      self.discoverDescriptorsStreamContinuation[characteristic.uuid] = continuation
    }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
    if let error {
      self.discoverDescriptorsStreamContinuation[characteristic.uuid]?.resume(throwing: error)
    } else {
      self.discoverDescriptorsStreamContinuation[characteristic.uuid]?.resume(returning: characteristic.descriptors)
    }
  }
  
  public func discoverIncludedServices(service: CBService, includedServiceIDs: [CBUUID]? = nil) async throws -> [CBService]? {
    peripheral.discoverIncludedServices(includedServiceIDs, for: service)
    return try await withCheckedThrowingContinuation { continuation in
      self.discoverIncludedServicesStreamContinuation[service.uuid] = continuation
    }
  }

  public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: (any Error)?) {
    if let error {
      self.discoverIncludedServicesStreamContinuation[service.uuid]?.resume(throwing: error)
    } else {
      self.discoverIncludedServicesStreamContinuation[service.uuid]?.resume(returning: service.includedServices)
    }
  }
  
  public func read(characteristic: CBCharacteristic) async throws -> CBCharacteristicProperties {
    peripheral.readValue(for: characteristic)
    return try await withCheckedThrowingContinuation { continuation in
      self.readCharacteristicStreamContinuation[characteristic.uuid] = continuation
    }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
    if let error {
      self.readCharacteristicStreamContinuation[characteristic.uuid]?.resume(throwing: error)
    } else {
      self.readCharacteristicStreamContinuation[characteristic.uuid]?.resume(returning: characteristic.properties)
    }
  }
  
  public func write(data: Data, characteristic: CBCharacteristic, type: CBCharacteristicWriteType) async throws {
    peripheral.writeValue(data, for: characteristic, type: type)
    return try await withCheckedThrowingContinuation { continuation in
      self.writeForCharacteristicStreamContinuation[characteristic.uuid] = continuation
    }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
    if let error {
      self.writeForCharacteristicStreamContinuation[characteristic.uuid]?.resume(throwing: error)
    } else {
      self.writeForCharacteristicStreamContinuation[characteristic.uuid]?.resume(returning: ())
    }
  }
  
  public func write(data: Data, descriptor: CBDescriptor) async throws {
    peripheral.writeValue(data, for: descriptor)
    return try await withCheckedThrowingContinuation { continuation in
      self.writeForDiscriptorStreamContinuation[descriptor.uuid] = continuation
    }
  }
  
  public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
    if let error {
      self.writeForDiscriptorStreamContinuation[descriptor.uuid]?.resume(throwing: error)
    } else {
      self.writeForDiscriptorStreamContinuation[descriptor.uuid]?.resume(returning: ())
    }
  }
}
