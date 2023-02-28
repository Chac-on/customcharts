{{- define "minio.portal" -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: portal
data:
  {{- $host := .Values.minio.network.console_url | default "$node_ip" -}}
  {{- $host = $host | replace "https://" "" -}}
  {{- $host = $host | replace "http://" "" }}
  path: "/"
  port: {{ .Values.minio.network.web_port | quote }}
  protocol: {{ include "minio.scheme" $ }}
  host: {{ $host }}
{{- end -}}
