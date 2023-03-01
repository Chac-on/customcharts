{{- define "postgres.workload" -}}
workload:
{{- include "ix.v1.common.app.postgres" (dict "secretName" "postgres-creds" "resources" .Values.resources) | nindent 2 }}

{{/* Service */}}
service:
  postgres:
    enabled: true
    type: ClusterIP
    targetSelector: postgres
    ports:
      postgres:
        enabled: true
        primary: true
        port: 5432
        targetSelector: postgres

{{/* Persistence */}}
persistence:
  postgresdata:
    enabled: true
    type: {{ .Values.logsearch.storage.postgres_data.type }}
    datasetName: {{ .Values.logsearch.storage.postgres_data.datasetName | default "" }}
    hostPath: {{ .Values.logsearch.storage.postgres_data.hostPath | default "" }}
    targetSelector:
      postgres:
        postgres:
          mountPath: /var/lib/postgresql/data
        permissions:
          mountPath: /mnt/directories/posgres_data
  postgresbackup:
    enabled: true
    type: {{ .Values.logsearch.storage.postgres_backup.type }}
    datasetName: {{ .Values.logsearch.storage.postgres_backup.datasetName | default "" }}
    hostPath: {{ .Values.logsearch.storage.postgres_backup.hostPath | default "" }}
    targetSelector:
      postgresbackup:
        postgresbackup:
          mountPath: /postgres_backup
        permissions:
          mountPath: /mnt/directories/posgres_backup
{{- end -}}
