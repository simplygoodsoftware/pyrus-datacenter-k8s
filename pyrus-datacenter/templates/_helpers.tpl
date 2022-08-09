{{- define "pyrus-datacenter.docker-pyrus-cred" -}}
auths:
  https://index.docker.io/v1/:
    auth: {{ .Values.imagePullSecrets | b64enc }}
{{- end  }}

{{- define "pyrus-datacenter.part-generator" }}
  {{- $vl              := index . 0 -}}
  {{- $cname           := index . 1 -}}
  {{- $currentPartType := index . 2 -}}
  
  {{- if ne $vl.installationType "mock" }}
  
    {{- if hasKey (index $vl $currentPartType) $cname }}
      {{- $currentPartType | nindent 10 }}:
      {{- if kindIs "string" (index (index $vl $currentPartType) $cname) }}
        {{- if eq (index (index $vl $currentPartType) $cname) "default" }}
          {{- toYaml (index $vl.defaults $currentPartType) | nindent 12 }}
        {{- end }}
      {{- else  }}
        {{- toYaml (index (index $vl $currentPartType) $cname) | nindent 12 }}
      {{- end }}
    {{- end }}

  {{- end }}
{{- end }}

{{- define "pyrus-datacenter.countStrategy" }}
  {{- $vl          := index . 0 -}}
  {{- $cname       := index . 1 -}}
  {{- $targetValue := index . 2 -}}
  {{- $ifUndefined := index . 3 -}}
  {{- if hasKey $vl.countStrategy $cname }}
    {{- if kindIs "string" (index $vl.countStrategy $cname) }} 
      {{- if eq (index $vl.countStrategy $cname) "default" }}
        {{- if hasKey $vl.defaults.countStrategy $targetValue }}
          {{- index $vl.defaults.countStrategy $targetValue }}
        {{- else }}
          {{- $ifUndefined }}
        {{- end }}
      {{- end }}
    {{- else }}
      {{- index (index $vl.countStrategy $cname) $targetValue }}
    {{- end }}
    {{- else }}
      {{- $ifUndefined }}
  {{- end }}
{{- end }}

{{- define "pyrus-repo" }}
  {{- $vl          := index . 0 -}}
  {{- $cname       := index . 1 -}}
  {{- if hasKey $vl.containersRepo $cname }}
    {{- index $vl.containersRepo $cname }}
  {{- else }}
    {{- $vl.containersRepo.default }}
  {{- end }}
{{- end }}

{{- define "pyrus-image" }}
  {{- $vl          := index . 0 -}}
  {{- $cname       := index . 1 -}}
  {{- if or (eq $vl.installationType "prod") (eq $vl.installationType "dc") }}
    {{- if hasKey $vl.tagsContainers $cname }}
      {{- include "pyrus-repo" (list $vl $cname) }}/{{- $cname }}:{{ index $vl.tagsContainers $cname }}
    {{- else }}
      {{- include "pyrus-repo" (list $vl $cname) }}/{{- $cname }}:{{ $vl.tagsContainers.All }}
    {{- end }}
  {{- else if eq $vl.installationType "mock" }}
    {{- index $vl.mockImageContainersTags $cname | default $vl.mockImageContainersTags.All}}
  {{- end }}
{{- end }}

{{- define "nodeInternalAddresses" }}
{{- range $i, $v := (lookup "v1" "nodes" "" "").items }}
{{-   if eq (index $v.metadata.labels "node-role.kubernetes.io/ingress-nginx") "enabled" }}
{{-     range $i, $v := $v.status.addresses }}
{{-       if eq $v.type "InternalIP" }}
{{ $v.address }}
{{-       end }}
{{-     end }}
{{-   end }}
{{- end }}
{{- end }}

{{- define "selectIngressDc" }}
{{-  $vl := index . 0 -}}
{{-  $rl := index . 1 -}}
{{-  if $vl.forceIngressClass }}
{{-    $vl.forceIngressClass }}
{{-  else }}
{{-    if eq (mod $rl.Revision 2) 0 }}rs{{ else }}ph{{end }}
{{-  end }}
{{- end }}

{{- define "pyrus-prod.mergeAnnotationFromFile" }}
{{- $current  := index . 0 -}}
{{- $gladdone := index . 1 -}}
{{- $         := index . 2 -}}
{{- $cService := index . 3 -}}
{{- if hasKey $current "annotations" }}
{{-   range $name, $value := $current.annotations }}
{{      $name }}: {{ $value | toYaml }}
{{-     if and (hasKey $gladdone "addoneSnippetFromFile") (hasKey $gladdone.addoneSnippetFromFile $name) (not (hasKey $gladdone.addoneSnippetFromFileExclude $cService)) }}
{{-       $.Files.Get (index $gladdone.addoneSnippetFromFile $name) | nindent 2 }}
{{-     end }}
{{-   end }}
{{-   if and (hasKey $gladdone "addoneSnippetFromFile") (not (hasKey $gladdone.addoneSnippetFromFileExclude $cService)) }}
{{-     range $name, $value := $gladdone.addoneSnippetFromFile }}
{{-       if not (hasKey $current.annotations $name) }}
{{          $name }}: |
{{-         $.Files.Get (index $gladdone.addoneSnippetFromFile $name) | nindent 2 }}
{{-       end }}
{{-     end }}
{{-   end }}
{{- else }}
{{-    if and (hasKey $gladdone "addoneSnippetFromFile") (not (hasKey $gladdone.addoneSnippetFromFileExclude $cService)) }}
{{-     range $name, $value := $gladdone.addoneSnippetFromFile }}
{{        $name }}: |
{{-         $.Files.Get (index $gladdone.addoneSnippetFromFile $name) | nindent 2 }}
{{-     end }}
{{-   end }}
{{- end }}
{{- end }}

{{- define "pyrus-prod.getVlfEnv" }}
{{-   $values  := index . 0 -}}
{{-   $name    := index . 1 -}}
{{-   range $li0 := $values }}
{{-      if eq $li0.name $name }}
{{-        $li0.value}}
{{-      end }}
{{-   end }}
{{- end }}
