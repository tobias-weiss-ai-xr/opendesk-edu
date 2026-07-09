{{/*
nubus-common.names.fullnameWithRevision will render a full name like "common.names.fullname"
and append the revision number.

The intended usage is for "Job" objects which do not allow that the template
section is updated. The consequence is that the "Job" object will need a new name
on every call to "helm upgrade", so that a new object will be created instead of
the existing one being patched.
*/}}

{{- define "nubus-common.names.fullnameWithRevision" }}
  {{- $fullname := include "common.names.fullname" . | trunc 55 | trimSuffix "-" }}
  {{- printf "%s-%d" $fullname .Release.Revision | trunc 63 | trimSuffix "-" }}
{{- end }}
