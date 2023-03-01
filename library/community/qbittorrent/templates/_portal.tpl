{{- define "qbittorrent.portal" -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: portal
data:
  path: "/"
  port: {{ .Values.qbittorrent.network.webPort | quote }}
  protocol: http
  host: $node_ip
{{- end -}}
