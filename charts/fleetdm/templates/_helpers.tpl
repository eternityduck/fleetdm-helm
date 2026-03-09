{{/*
Expand the name of the chart.
*/}}
{{- define "fleetdm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "fleetdm.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "fleetdm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fleetdm.labels" -}}
helm.sh/chart: {{ include "fleetdm.chart" . }}
{{ include "fleetdm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fleetdm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fleetdm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "fleetdm.serviceAccountName" -}}
{{- if .Values.fleet.serviceAccount.create }}
{{- default (include "fleetdm.fullname" .) .Values.fleet.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.fleet.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
MySQL host
*/}}
{{- define "fleetdm.mysql.host" -}}
{{- printf "%s-mysql" (include "fleetdm.fullname" .) }}
{{- end }}

{{/*
MySQL port
*/}}
{{- define "fleetdm.mysql.port" -}}
{{- 3306 }}
{{- end }}

{{/*
MySQL database
*/}}
{{- define "fleetdm.mysql.database" -}}
{{- .Values.mysql.auth.database }}
{{- end }}

{{/*
MySQL username
*/}}
{{- define "fleetdm.mysql.username" -}}
{{- .Values.mysql.auth.username }}
{{- end }}

{{/*
MySQL secret name
*/}}
{{- define "fleetdm.mysql.secretName" -}}
{{- printf "%s-mysql" (include "fleetdm.fullname" .) }}
{{- end }}

{{/*
Redis host
*/}}
{{- define "fleetdm.redis.host" -}}
{{- printf "%s-redis" (include "fleetdm.fullname" .) }}
{{- end }}

{{/*
Redis port
*/}}
{{- define "fleetdm.redis.port" -}}
{{- 6379 }}
{{- end }}
