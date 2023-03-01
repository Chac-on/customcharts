{{- define "minio.portal" -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: portal
data:
  {{- $host := .Values.minio.network.consoleUrl | default "$node_ip" -}}
  {{- $host = $host | replace "https://" "" -}}
  {{- $host = $host | replace "http://" "" }}
  path: "/"
  port: {{ .Values.minio.network.webPort | quote }}
  protocol: {{ include "minio.scheme" $ }}
  host: {{ $host }}
{{- end -}}
