{{- define "qbittorrent.configuration" -}}

{{/* Configmaps */}}
configmap:
  qbit-config:
    enabled: true
    data:
      QBITTORRENT__BT_PORT: {{ .Values.qbittorrent.network.bt_port | quote }}
      QBITTORRENT__PORT: {{ .Values.qbittorrent.network.web_port | quote }}

{{- end -}}
