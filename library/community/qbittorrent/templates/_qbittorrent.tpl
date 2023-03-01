{{- define "qbittorrent.workload" -}}
workload:
  qbittorrent:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: {{ .Values.qbittorrent.network.hostNetwork }}
      containers:
        qbittorrent:
          enabled: true
          primary: true
          imageSelector: image
          securityContext:
            runAsUser: {{ .Values.qbittorrent.runAs.user }}
            runAsGroup: {{ .Values.qbittorrent.runAs.group }}
          envFrom:
            - configMapRef:
                name: qbit-config
          probes:
            liveness:
              enabled: true
              type: http
              port: "{{ .Values.qbittorrent.network.webPort }}"
              path: /
            readiness:
              enabled: true
              type: http
              port: "{{ .Values.qbittorrent.network.webPort }}"
              path: /
            startup:
              enabled: true
              type: http
              port: "{{ .Values.qbittorrent.network.webPort }}"
              path: /
      initContainers:
      {{- include "ix.v1.common.app.permissions" (dict "UID" .Values.qbittorrent.runAs.user "GID" .Values.qbittorrent.runAs.group "type" "init") | nindent 8 -}}

{{/* Service */}}
service:
  qbittorrent:
    enabled: true
    primary: true
    type: NodePort
    targetSelector: qbittorrent
    ports:
      webui:
        enabled: true
        primary: true
        port: {{ .Values.qbittorrent.network.webPort }}
        nodePort: {{ .Values.qbittorrent.network.webPort }}
        targetSelector: qbittorrent
  qbittorrent-bt:
    enabled: true
    type: NodePort
    targetSelector: qbittorrent
    ports:
      bt-tcp:
        enabled: true
        primary: true
        port: {{ .Values.qbittorrent.network.btPort }}
        nodePort: {{ .Values.qbittorrent.network.btPort }}
        targetSelector: qbittorrent
      bt-upd:
        enabled: true
        primary: true
        port: {{ .Values.qbittorrent.network.btPort }}
        nodePort: {{ .Values.qbittorrent.network.btPort }}
        protocol: udp
        targetSelector: qbittorrent

{{/* Persistence */}}
persistence:
  config:
    enabled: true
    type: {{ .Values.qbittorrent.storage.config.type }}
    datasetName: {{ .Values.qbittorrent.storage.config.datasetName | default "" }}
    hostPath: {{ .Values.qbittorrent.storage.config.hostPath | default "" }}
    targetSelector:
      qbittorrent:
        qbittorrent:
          mountPath: /config
        permissions:
          mountPath: /mnt/directories/config
  downloads:
    enabled: true
    type: {{ .Values.qbittorrent.storage.downloads.type }}
    datasetName: {{ .Values.qbittorrent.storage.downloads.datasetName | default "" }}
    hostPath: {{ .Values.qbittorrent.storage.downloads.hostPath | default "" }}
    targetSelector:
      qbittorrent:
        qbittorrent:
          mountPath: /downloads
        permissions:
          mountPath: /mnt/directories/downloads
{{- end -}}
