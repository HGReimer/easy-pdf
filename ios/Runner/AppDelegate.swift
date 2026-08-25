import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var printChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "de.easyschmiede.easypdf/print",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "printPdf" else {
        result(FlutterMethodNotImplemented)
        return
      }

      self?.handlePrint(call: call, result: result)
    }

    printChannel = channel
  }

  private func handlePrint(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let arguments = call.arguments as? [String: Any],
      let typedData = arguments["bytes"] as? FlutterStandardTypedData
    else {
      result(
        FlutterError(
          code: "INVALID_PDF",
          message: "Die PDF-Daten fehlen.",
          details: nil
        )
      )
      return
    }

    let pdfData = typedData.data
    let documentName = arguments["name"] as? String ?? "Easy PDF.pdf"

    guard UIPrintInteractionController.canPrint(pdfData) else {
      result(
        FlutterError(
          code: "INVALID_PDF",
          message: "Die PDF-Datei kann nicht gedruckt werden.",
          details: nil
        )
      )
      return
    }

    let printController = UIPrintInteractionController.shared
    let printInfo = UIPrintInfo(dictionary: nil)
    printInfo.outputType = .general
    printInfo.jobName = documentName

    printController.printInfo = printInfo
    printController.showsPageRange = true
    printController.printingItem = pdfData

    let completion: UIPrintInteractionController.CompletionHandler = {
      _, completed, error in

      if let error {
        result(
          FlutterError(
            code: "PRINT_ERROR",
            message: error.localizedDescription,
            details: nil
          )
        )
      } else {
        result(completed)
      }
    }

    if UIDevice.current.userInterfaceIdiom == .pad {
      guard
        let windowScene = UIApplication.shared.connectedScenes
          .compactMap({ $0 as? UIWindowScene })
          .first(where: { $0.activationState == .foregroundActive }),
        let window = windowScene.windows.first(where: { $0.isKeyWindow }),
        let view = window.rootViewController?.view
      else {
        result(
          FlutterError(
            code: "NO_WINDOW",
            message: "Der Druckdialog konnte nicht geöffnet werden.",
            details: nil
          )
        )
        return
      }

      let sourceRect = CGRect(
        x: view.bounds.midX,
        y: view.bounds.midY,
        width: 1,
        height: 1
      )

      let presented = printController.present(
        from: sourceRect,
        in: view,
        animated: true,
        completionHandler: completion
      )

      if !presented {
        result(
          FlutterError(
            code: "PRINT_DIALOG_ERROR",
            message: "Der Druckdialog konnte nicht geöffnet werden.",
            details: nil
          )
        )
      }
    } else {
      let presented = printController.present(
        animated: true,
        completionHandler: completion
      )

      if !presented {
        result(
          FlutterError(
            code: "PRINT_DIALOG_ERROR",
            message: "Der Druckdialog konnte nicht geöffnet werden.",
            details: nil
          )
        )
      }
    }
  }
}
