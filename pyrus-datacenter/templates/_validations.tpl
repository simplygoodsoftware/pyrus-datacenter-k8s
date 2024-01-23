{{- /* 
2.0.14 nats statefulset without pvc must be removed 
*/ -}} 
{{- define "pyrus-datacenter.validations.nats" }}
    {{- if and .Values.nats.enabled .Values.nats.nats.jetstream.enabled -}}
        {{ $nats := lookup "apps/v1" "StatefulSet" .Release.Namespace (include "nats.fullname" .Subcharts.nats) }}
        {{- with $nats -}}
            {{- if empty $nats.spec.volumeClaimTemplates }}
                {{- fail (cat "\n\nLegacy nats statefulset detected. Remove it and try again: \n\nkubectl --namespace" 
                    $.Release.Namespace "delete statefulsets.apps" (include "nats.fullname" $.Subcharts.nats)) -}}
            {{ end -}}
        {{- end -}}
    {{- end -}}
{{ end -}}