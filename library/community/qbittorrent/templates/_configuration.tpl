{{- define "qbittorrent.configuration" -}}

{{/* Configmaps */}}
configmap:
  qbit-config:
    enabled: true
    data:
      QBITTORRENT__BT_PORT: {{ .Values.qbittorrent.network.btPort | quote }}
      QBITTORRENT__PORT: {{ .Values.qbittorrent.network.webPort | quote }}

{{- end -}}
