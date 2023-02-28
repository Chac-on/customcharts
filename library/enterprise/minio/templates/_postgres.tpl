{{- define "postgres.workload" -}}
workload:
  postgres:
    enabled: true
    type: Deployment
    podSpec:
      containers:
        postgres:
          enabled: true
          primary: true
          imageSelector: imagePostgres
          securityContext:
            runAsUser: 999
            runAsGroup: 999
            readOnlyRootFilesystem: false
          resources:
            limits:
              cpu: {{ .Values.resources.limits.cpu }}
              memory: {{ .Values.resources.limits.memory }}
          envFrom:
            - secretRef:
                name: postgres-creds
            - configMapRef:
                name: postgres-config
          probes:
            liveness:
              enabled: true
              type: exec
              command:
                - sh
                - -c
                - "until pg_isready -U ${POSTGRES_USER} -h localhost; do sleep 2; done"
            readiness:
              enabled: true
              type: exec
              command:
                - sh
                - -c
                - "until pg_isready -U ${POSTGRES_USER} -h localhost; do sleep 2; done"
            startup:
              enabled: true
              type: exec
              command:
                - sh
                - -c
                - "until pg_isready -U ${POSTGRES_USER} -h localhost; do sleep 2; done"
      initContainers:
      {{- include "ix.v1.common.app.permissions" (dict "UID" 999 "GID" 999) | nindent 8 }}
  postgresbackup:
    enabled: true
    type: Job
    annotations:
      "helm.sh/hook": pre-upgrade
      "helm.sh/hook-weight": "1"
      "helm.sh/hook-delete-policy": hook-succeeded
    podSpec:
      restartPolicy: Never
      containers:
        postgresbackup:
          enabled: true
          primary: true
          imageSelector: imagePostgres
          securityContext:
            runAsUser: 999
            runAsGroup: 999
            readOnlyRootFilesystem: false
          probes:
            liveness:
              enabled: false
            readiness:
              enabled: false
            startup:
              enabled: false
          resources:
            limits:
              cpu: 2000m
              memory: 2Gi
          envFrom:
            - secretRef:
                name: postgres-creds
            - configMapRef:
                name: postgres-config
          command:
            - sh
            - -c
            - |
              until pg_isready -U ${POSTGRES_USER} -h ${POSTGRES_HOST}; do sleep 2; done
              echo "Creating backup of ${POSTGRES_DB} database"
              pg_dump --dbname=${POSTGRES_URL} --file /postgres_backup/${POSTGRES_DB}_$(date +%Y-%m-%d_%H-%M-%S).sql || echo "Failed to create backup"
              echo "Backup finished"
      initContainers:
      {{- include "ix.v1.common.app.permissions" (dict "UID" 999 "GID" 999 "type" "init") | nindent 8 }}

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
