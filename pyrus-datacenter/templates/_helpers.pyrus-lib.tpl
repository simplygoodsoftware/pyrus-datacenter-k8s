{{- define "pyrus-lib.secretRefvolumeMounts" }}
{{-   $           := index . 0 -}}
{{-   $cname      := index . 1 -}}
{{-   $TARGET     := "secretRef" }}
{{-   $Defaults                := index $.Values  "defaults"    | default dict }}
{{-   $DefaultsTARGET          := index $Defaults $TARGET       | default dict }}
{{-   if $DefaultsTARGET }}
{{-     range $mountPoint, $mountValues := $DefaultsTARGET }}
{{-       range $keyPath, $FileValue := $mountValues }}
- name: defaults-{{ $mountPoint | replace "/" "-" | replace "." "-" | replace "_" "-" }}
  mountPath: {{ $mountPoint }}/{{ $keyPath }}
  subPath: {{ $keyPath }}
{{-       end }}
{{-     end }}
{{-   end }}
{{- end }}

{{- define "pyrus-lib.secretRefvolumeMounts.nindent" }}
{{-   $        := index . 0 -}}
{{-   $cname   := index . 1 -}}
{{-   $nindent := index . 2 -}}
{{-   $rs      := include "pyrus-lib.secretRefvolumeMounts" (list $ $cname) }}
{{-  if $rs }}
{{-    $rs | indent $nindent }}
{{-  end }}
{{- end }}

{{- define "pyrus-lib.secretRef.volumes" }}
{{-   $           := index . 0 -}}
{{-   $cname      := index . 1 -}}
{{-   $TARGET     := "secretRef"}}
{{-   $Defaults                := index $.Values  "defaults"    | default dict }}
{{-   $DefaultsTARGET          := index $Defaults $TARGET       | default dict }}
{{-   if $DefaultsTARGET }}
{{-     range $mountPoint, $mountValues := $DefaultsTARGET }}
- name: defaults-{{ $mountPoint | replace "/" "-" | replace "." "-" | replace "_" "-" }}
  secret:
    secretName: defaults-{{ $mountPoint | replace "/" "-" | replace "." "-" | replace "_" "-" }}
    items:
{{-       range $keyPath, $FileValue := $mountValues }}
      - key: {{ $keyPath }}
        path: {{ $keyPath }}
{{-       end }}
{{-   end }}
{{-   end }}
{{- end }}
