{{ define "pyrus.postgrsql-upgrade.migration" }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ $.statefulset.metadata.name }}-migration
  annotations:
    helm.sh/hook: pre-upgrade
    helm.sh/hook-weight: "-20"
    #helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
  labels:
    app: postgresql-upgrade
spec:
  completions: 1
  backoffLimit: 0
  activeDeadlineSeconds: 7200
  template:
    metadata:
      labels:
        app: postgresql-upgrade
    spec:
      restartPolicy: Never
      {{- with $.statefulset.spec.template.spec.affinity }}
      affinity: 
        {{- . | toYaml | nindent 8 }}
      {{- end }}
      {{- with $.statefulset.spec.template.spec.imagePullSecrets }}
      imagePullSecrets: 
        {{- . | toYaml | nindent 6 }}
      {{- end }}
      {{- with (index .statefulset.spec.template.spec.containers 0) }}
      containers:
      - name: postgresql-upgrade-{{ $.Values.postgresql.upgrade.fromVersion }}-to-{{ $.Values.postgresql.upgrade.toVersion }}
        image: {{ $.Values.containersRepo.default }}/pyrus-pgsql-migrator:{{ $.Values.postgresql.upgrade.fromVersion }}-to-{{ $.Values.postgresql.upgrade.toVersion }}
        env:
          {{- if .env }}
          {{-   .env | toYaml | nindent 8 }}
          {{- end }}
        volumeMounts:
        - name: postgres-data-{{ $.Values.postgresql.upgrade.fromVersion }}
          mountPath: /var/lib/postgresql/data
        - name: postgres-data-{{ $.Values.postgresql.upgrade.toVersion }}
          mountPath: /var/lib/postgresql/data-new
      {{- end }}
      volumes:
      - name: postgres-data-{{ $.Values.postgresql.upgrade.fromVersion }}
        persistentVolumeClaim:
          claimName: {{ include "pyrus.postgresql-upgrade.pvc-old" . }}
      - name: postgres-data-{{ $.Values.postgresql.upgrade.toVersion }}
        persistentVolumeClaim:
          claimName: {{ include "pyrus.postgresql-upgrade.pvc-new" . }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: &name patch-pvc-labels
  annotations:
    helm.sh/hook: pre-upgrade
    helm.sh/hook-weight: "-10"
    #helm.sh/hook-delete-policy: before-hook-creation,hook-succeeded
  labels: &selector
    app: *name
spec:
  backoffLimit: 1
  activeDeadlineSeconds: 300
  template:
    metadata:
      labels: *selector
    spec:
      restartPolicy: Never
      serviceAccountName: delete-postgres-statefulset
      containers:
        - name: path-pvc
          image: cr.yandex/crpjh07630tmeovd2eqb/bitnami/kubectl:1.28.6
          command:
            - /bin/sh
            - -c
            - |
              kubectl -n {{ $.statefulset.metadata.namespace }} label pvc {{ include "pyrus.postgresql-upgrade.pvc-new" . }} "app={{ $.statefulset.metadata.name }}"
              kubectl -n {{ $.statefulset.metadata.namespace }} label pvc {{ include "pyrus.postgresql-upgrade.pvc-old" . }} "app"-
{{ end }}
