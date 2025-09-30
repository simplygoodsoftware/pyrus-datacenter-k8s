{{ define "pyrus.postgrsql-upgrade.delete-postgres-statefulset" }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: delete-postgres-statefulset
  annotations:
    helm.sh/hook: pre-upgrade
    helm.sh/hook-weight: "-70"
    #helm.sh/hook-delete-policy: before-hook-creation,all
rules:
  - apiGroups: ["apps"]
    resources:
      - statefulsets
    verbs:
      - delete
      - list
  - apiGroups: ["*"]
    resources:
      - persistentvolumeclaims
    verbs:
      - get
      - list
      - patch

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: delete-postgres-statefulset
  annotations:
    helm.sh/hook: pre-upgrade
    helm.sh/hook-weight: "-70"
    #helm.sh/hook-delete-policy: before-hook-creation,all
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: delete-postgres-statefulset
  annotations:
    helm.sh/hook: pre-upgrade
    helm.sh/hook-weight: "-70"
    #helm.sh/hook-delete-policy: before-hook-creation,all
subjects:
  - kind: ServiceAccount
    name: delete-postgres-statefulset
roleRef:
  kind: Role
  name: delete-postgres-statefulset
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: batch/v1
kind: Job
metadata:
  name: &name delete-postgres-statefulset
  annotations:
    helm.sh/hook: pre-upgrade
    helm.sh/hook-weight: "-20"
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
        - name: delete-postgres-statefulset
          image: cr.yandex/crpjh07630tmeovd2eqb/bitnami/kubectl:1.28.6
          command:
            - /bin/sh
            - -c
            - |
              kubectl -n {{ .metadata.namespace }} delete statefulset {{ .metadata.name }}
              {{- $labelName := "app" }}
              kubectl -n {{ .metadata.namespace }} wait --for=delete statefulset -l "app={{ index .spec.template.metadata.labels $labelName }}"
{{ end  }}
