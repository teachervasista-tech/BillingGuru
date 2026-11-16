#include "flutter_window.h"

#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Must match lib/app/auto_backup_on_exit.dart.
constexpr char kLifecycleChannel[] = "billing_guru/lifecycle";
constexpr char kBeforeCloseMethod[] = "beforeClose";

// Close anyway if Dart has not answered by then (Dart gives up after 60 s).
constexpr UINT_PTR kCloseTimerId = 0xB6;
constexpr UINT kCloseTimeoutMs = 90 * 1000;

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  lifecycle_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), kLifecycleChannel,
          &flutter::StandardMethodCodec::GetInstance());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  lifecycle_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::ConfirmClose(HWND hwnd) {
  if (close_confirmed_) {
    return;
  }
  close_confirmed_ = true;
  KillTimer(hwnd, kCloseTimerId);
  PostMessage(hwnd, WM_CLOSE, 0, 0);
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Hold the first close until Dart has made its backup.
  if (message == WM_CLOSE && !close_confirmed_ && lifecycle_channel_) {
    if (!close_requested_) {
      close_requested_ = true;
      SetTimer(hwnd, kCloseTimerId, kCloseTimeoutMs, nullptr);
      auto done = [this, hwnd]() { ConfirmClose(hwnd); };
      lifecycle_channel_->InvokeMethod(
          kBeforeCloseMethod, nullptr,
          std::make_unique<flutter::MethodResultFunctions<>>(
              [done](const flutter::EncodableValue*) { done(); },
              [done](const std::string&, const std::string&,
                     const flutter::EncodableValue*) { done(); },
              [done]() { done(); }));
    }
    return 0;
  }
  if (message == WM_TIMER && wparam == kCloseTimerId) {
    ConfirmClose(hwnd);
    return 0;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
