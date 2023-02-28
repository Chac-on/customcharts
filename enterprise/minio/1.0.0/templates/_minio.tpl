{{- define "minio.workload" -}}
workload:
  minio:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: {{ .Values.minio.network.host_network }}
      containers:
        minio:
          enabled: true
          primary: true
          imageSelector: image
          resources:
            limits:
              cpu: {{ .Values.resources.limits.cpu }}
              memory: {{ .Values.resources.limits.memory }}
          envFrom:
            - secretRef:
                name: minio-creds
            - configMapRef:
                name: minio-config
          args:
            - server
            - "--address"
            - {{ printf ":%v" .Values.minio.network.api_port | quote }}
            - "--console-address"
            - {{ printf ":%v" .Values.minio.network.web_port | quote }}
            {{- if .Values.minio.network.certificate_id }}
            - "--certs-dir"
            - "/.minio/certs"
            {{- end -}}
            {{- if .Values.minio.logging.anonymous }}
            - "--anonymous"
            {{- end -}}
            {{- if .Values.minio.logging.quiet }}
            - "--quiet"
            {{- end }}
          probes:
            liveness:
              enabled: true
              type: {{ include "minio.scheme" $ }}
              port: "{{ .Values.minio.network.api_port }}"
              path: /minio/health/live
            readiness:
              enabled: true
              type: {{ include "minio.scheme" $ }}
              port: "{{ .Values.minio.network.api_port }}"
              path: /minio/health/live
            startup:
              enabled: true
              type: {{ include "minio.scheme" $ }}
              port: "{{ .Values.minio.network.api_port }}"
              path: /minio/health/live
      initContainers:
      {{- include "ix.v1.common.app.permissions" (dict "UID" 568 "GID" 568) | nindent 8 -}}
      {{- if .Values.logsearch.enabled }}
        logsearch-wait:
          enabled: true
          type: init
          imageSelector: imageBash
          resources:
            limits:
              cpu: 500m
              memory: 256Mi
          envFrom:
            - secretRef:
                name: minio-creds
          command: bash
          args:
            - -c
            - |
              echo "Pinging Logsearch API for readiness..."
              until wget --spider --quiet --timeout=3 --tries=1 ${MINIO_LOG_QUERY_URL}/status; do
                echo "Waiting for Logsearch API (${MINIO_LOG_QUERY_URL}/status) to be ready..."
                sleep 2
              done
              echo "Logsearch API is ready"
      {{- end }}

{{/* Service */}}
service:
  minio:
    enabled: true
    primary: true
    type: NodePort
    targetSelector: minio
    ports:
      api:
        enabled: true
        primary: true
        port: {{ .Values.minio.network.api_port }}
        nodePort: {{ .Values.minio.network.api_port }}
        targetSelector: minio
      webui:
        enabled: true
        port: {{ .Values.minio.network.web_port }}
        nodePort: {{ .Values.minio.network.web_port }}
        targetSelector: minio

{{/* Persistence */}}
persistence:
  {{- range $idx, $storage := .Values.minio.storage }}
  {{ printf "data%v" (int $idx) }}:
    enabled: true
    type: {{ $storage.type }}
    datasetName: {{ $storage.datasetName | default "" }}
    hostPath: {{ $storage.hostPath | default "" }}
    targetSelector:
      minio:
        minio:
          mountPath: {{ $storage.mountPath }}
        permissions:
          mountPath: /mnt/directories{{ $storage.mountPath }}
  {{- end }}
  # Minio writes temporary files to this directory. Adding this as an emptyDir,
  # So we don't have to set readOnlyRootFilesystem to false
  tempdir:
    enabled: true
    type: emptyDir
    targetSelector:
      minio:
        minio:
          mountPath: /.minio
  {{- if .Values.minio.network.certificate_id }}
  cert:
    enabled: true
    type: secret
    objectName: minio-cert
    defaultMode: "0600"
    items:
      - key: tls.key
        path: private.key
      - key: tls.crt
        path: public.crt
      - key: tls.crt
        path: CAs/public.crt
    targetSelector:
      minio:
        minio:
          mountPath: /.minio/certs
          readOnly: true
    {{- end -}}
{{- end -}}
