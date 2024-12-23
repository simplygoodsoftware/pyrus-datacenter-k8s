{{ define "pyrus.postgrsql-upgrade.init-volume" }}
{{- $cleanedName := include "pyrus.postgresql-upgrade.clean-name" .statefulset.metadata.name }}
{{- $pvcName := include "pyrus.postgresql-upgrade.pvc-new" . }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ $pvcName }}
  annotations:
    helm.sh/hook: pre-upgrade
    helm.sh/hook-weight: "-300"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ index $.Values.volumeSize .statefulset.metadata.name }}

---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $.statefulset.metadata.name }}-init-volume
  namespace: {{ $.statefulset.metadata.namespace }}
  annotations:
    helm.sh/hook: pre-upgrade
    helm.sh/hook-weight: "-300"
    helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
  labels:
    app: postgresql-init-volume
spec:
  completions: 1
  backoffLimit: 0
  activeDeadlineSeconds: 300
  template:
    metadata:
      labels:
        app: postgresql-init-volume
    spec:
      restartPolicy: Never
      {{- $labelName := "app" }}
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: {{ $labelName }}
                operator: In
                values:
                - {{ index $.statefulset.spec.template.metadata.labels $labelName }} 
            topologyKey: "kubernetes.io/hostname"
      imagePullSecrets: 
        - name: docker-pyrus-cred
      containers:
      - name: init-volume
        image: {{ $.Values.containersRepo.default }}/{{ .Values.devPrefix }}pyrus-pgsql-{{ $.Values.postgresql.upgrade.toVersion }}:{{ .Values.tagsContainers.All }}
        env:
        - name: DISABLE_SCHEMA_INIT
          value: "1"
          {{- if .env }}
          {{-   .env | toYaml | nindent 8 }}
          {{- end }}
        volumeMounts:
        - name: postgres-data-{{ $.Values.postgresql.upgrade.toVersion }}
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-data-16
        persistentVolumeClaim:
          claimName: {{ $pvcName }}
{{ end  }}
