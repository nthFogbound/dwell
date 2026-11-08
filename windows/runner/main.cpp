#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  // Center the window in the primary monitor's work area (the screen minus
  // the taskbar). Flutter's Create() scales origin and size by the monitor's
  // DPI, so we compute in logical pixels by dividing the physical work area
  // by the same scale.
  const int kWidth = 1280;
  const int kHeight = 720;
  const double scale = GetDpiForSystem() / 96.0;
  RECT work_area;
  SystemParametersInfo(SPI_GETWORKAREA, 0, &work_area, 0);
  const double x = work_area.left / scale +
                   ((work_area.right - work_area.left) / scale - kWidth) / 2;
  const double y = work_area.top / scale +
                   ((work_area.bottom - work_area.top) / scale - kHeight) / 2;
  Win32Window::Point origin(static_cast<unsigned int>(std::max(0.0, x)),
                            static_cast<unsigned int>(std::max(0.0, y)));
  Win32Window::Size size(kWidth, kHeight);
  if (!window.Create(L"Dwell", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
