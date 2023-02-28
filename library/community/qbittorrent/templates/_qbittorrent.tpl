{{- define "qbittorrent.workload" -}}
workload:
  qbittorrent:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: {{ .Values.qbittorrent.network.host_network }}
      containers:
        qbittorrent:
          enabled: true
          primary: true
          imageSelector: image
          securityContext:
            runAsUser: {{ .Values.qbittorrent.run_as.user }}
            runAsGroup: {{ .Values.qbittorrent.run_as.group }}
          resources:
            limits:
              cpu: {{ .Values.resources.limits.cpu }}
              memory: {{ .Values.resources.limits.memory }}
          envFrom:
            - configMapRef:
                name: qbit-config
          probes:
            liveness:
              enabled: true
              type: http
              port: "{{ .Values.qbittorrent.network.web_port }}"
              path: /
            readiness:
              enabled: true
              type: http
              port: "{{ .Values.qbittorrent.network.web_port }}"
              path: /
            startup:
              enabled: true
              type: http
              port: "{{ .Values.qbittorrent.network.web_port }}"
              path: /
      initContainers:
      {{- include "ix.v1.common.app.permissions" (dict "UID" .Values.qbittorrent.run_as.user "GID" .Values.qbittorrent.run_as.group "type" "init") | nindent 8 -}}

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
        port: {{ .Values.qbittorrent.network.web_port }}
        nodePort: {{ .Values.qbittorrent.network.web_port }}
        targetSelector: qbittorrent
  qbittorrent-bt:
    enabled: true
    type: NodePort
    targetSelector: qbittorrent
    ports:
      bt-tcp:
        enabled: true
        primary: true
        port: {{ .Values.qbittorrent.network.bt_port }}
        nodePort: {{ .Values.qbittorrent.network.bt_port }}
        targetSelector: qbittorrent
      bt-upd:
        enabled: true
        primary: true
        port: {{ .Values.qbittorrent.network.bt_port }}
        nodePort: {{ .Values.qbittorrent.network.bt_port }}
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
