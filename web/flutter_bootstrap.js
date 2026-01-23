// Custom bootstrap to force HTML renderer and avoid CanvasKit font downloads.
window.flutterWebRenderer = "html";

// This file follows Flutter's web bootstrap template with placeholders.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorker: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
});
