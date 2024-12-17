{{- define "pyrus.postgresql-upgrade.clean-name" -}}
{{- regexReplaceAll "-\\d+$" . "" | trim -}}
{{- end -}}


{{- define "pyrus.postgresql-upgrade.pvc-new" -}}
{{- $pvcTemplateName := "" }}
{{- range .statefulset.spec.template.spec.containers -}}
  {{- $mountPath := "/var/lib/postgresql/data" -}}
  {{- range .volumeMounts -}}
    {{- if eq .mountPath $mountPath -}}
      {{- $volumeName := .name -}}
      {{- range $.statefulset.spec.volumeClaimTemplates -}}
        {{- if eq .metadata.name $volumeName -}}
          {{- $pvcTemplateName = regexReplaceAll "-\\d\\d$" .metadata.name "" -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $pvcTemplateName }}-{{ $.Values.postgresql.upgrade.toVersion }}-{{ include "pyrus.postgresql-upgrade.clean-name" $.statefulset.metadata.name }}-0
{{- end  -}}


{{- define "pyrus.postgresql-upgrade.pvc-old" -}}
{{- $pvcTemplateName := "" }}
{{- range .statefulset.spec.template.spec.containers -}}
  {{- $mountPath := "/var/lib/postgresql/data" -}}
  {{- range .volumeMounts -}}
    {{- if eq .mountPath $mountPath -}}
      {{- $volumeName := .name -}}
      {{- range $.statefulset.spec.volumeClaimTemplates -}}
        {{- if eq .metadata.name $volumeName -}}
          {{- $pvcTemplateName = .metadata.name -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $pvcTemplateName }}-{{ include "pyrus.postgresql-upgrade.clean-name" $.statefulset.metadata.name }}-0
{{- end  -}}
