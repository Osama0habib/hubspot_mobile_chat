import Flutter
import HubspotMobileSDK
import SwiftUI
import UIKit

/// Error code shared with the Dart facade for the uniform error contract (FR-013).
private let configErrorCode = "hubspot_config_error"

/// iOS implementation of `HubspotHostApi`. Forwards every call to
/// `HubspotManager`; presents `HubspotChatView` for open-chat. No business
/// logic beyond marshalling and presentation.
///
/// Note: the generated `HubspotHostApi` protocol and its types (`PushData`,
/// etc.) are internal to this module, so the conformance methods are internal —
/// only `register(with:)` needs to be public for the plugin registrant.
public class HubspotMobileChatPlugin: NSObject, FlutterPlugin, HubspotHostApi {

  private var flutterApi: HubspotFlutterApi?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = HubspotMobileChatPlugin()
    HubspotHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    instance.flutterApi = HubspotFlutterApi(binaryMessenger: registrar.messenger())
    PushBridge.shared.flutterApi = instance.flutterApi
  }

  func configure(completion: @escaping (Result<Void, Error>) -> Void) {
    DispatchQueue.main.async {
      do {
        try HubspotManager.configure()
        completion(.success(()))
      } catch {
        completion(.failure(
          PigeonError(code: configErrorCode, message: error.localizedDescription, details: nil)))
      }
    }
  }

  func setUserIdentity(
    email: String, identityToken: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    DispatchQueue.main.async {
      HubspotManager.shared.setUserIdentity(identityToken: identityToken, email: email)
      completion(.success(()))
    }
  }

  func setChatProperties(
    properties: [String: String],
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    DispatchQueue.main.async {
      HubspotManager.shared.setChatProperties(data: properties)
      completion(.success(()))
    }
  }

  func openChat(
    chatFlow: String?, pushData: PushData?,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    DispatchQueue.main.async {
      guard let top = Self.topViewController() else {
        completion(.failure(
          PigeonError(code: configErrorCode, message: "No view controller to present chat",
            details: nil)))
        return
      }
      let chatView = HubspotChatView(manager: HubspotManager.shared, chatFlow: chatFlow)
      let host = UIHostingController(rootView: chatView)
      top.present(host, animated: true) { completion(.success(())) }
    }
  }

  func registerPushToken(
    token: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    // App owns APNs registration (FR-007); forward the token to the SDK. The SDK
    // expects raw APNs token bytes, so decode the hex string the app provides.
    DispatchQueue.main.async {
      HubspotManager.shared.setPushToken(apnsPushToken: Self.dataFromHex(token))
      completion(.success(()))
    }
  }

  func logout(completion: @escaping (Result<Void, Error>) -> Void) {
    DispatchQueue.main.async {
      HubspotManager.shared.clearUserData()
      completion(.success(()))
    }
  }

  /// Decode an APNs device-token hex string ("a1b2…") into raw bytes.
  private static func dataFromHex(_ hex: String) -> Data {
    var data = Data(capacity: hex.count / 2)
    var index = hex.startIndex
    while index < hex.endIndex {
      let next = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
      if let byte = UInt8(hex[index..<next], radix: 16) {
        data.append(byte)
      }
      index = next
    }
    return data
  }

  @MainActor
  private static func topViewController(
    _ base: UIViewController? = UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }
      .first?.rootViewController
  ) -> UIViewController? {
    if let nav = base as? UINavigationController {
      return topViewController(nav.visibleViewController)
    }
    if let tab = base as? UITabBarController {
      return topViewController(tab.selectedViewController)
    }
    if let presented = base?.presentedViewController {
      return topViewController(presented)
    }
    return base
  }
}

/// Bridges incoming APNs payloads (forwarded by the app) to Dart (FR-007).
public class PushBridge: NSObject {
  public static let shared = PushBridge()
  var flutterApi: HubspotFlutterApi?

  /// Call from the app's `didReceiveRemoteNotification` for HubSpot chat pushes.
  public func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
    var raw = [String?: String?]()
    for (key, value) in userInfo {
      if let key = key as? String { raw[key] = "\(value)" }
    }
    let pushData = PushData(
      messageId: userInfo["messageId"] as? String,
      threadId: userInfo["threadId"] as? String,
      raw: raw)
    flutterApi?.onNewMessagePush(data: pushData) { _ in }
  }
}
