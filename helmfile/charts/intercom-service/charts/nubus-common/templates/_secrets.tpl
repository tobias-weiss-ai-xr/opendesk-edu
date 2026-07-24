{{/*
Generate the name of a Secret.

The implementation follows the API from the common chart of Bitnami to some extend.
It does intendionally only support "existingSecret.name" and has no support for
"existingSecret" to be a string.

Usage:

{{ include "nubus-common.secrets.name" (dict "existingSecret" .Values.path.to.the.existingSecret "defaultNameSuffix" "my-suffix" "context" .) }}

Params:

- existingSecret - ExistingSecret - Optional. The generated name will be based on this
  value if a configuration for an existing Secret is provided.

- defaultNameSuffix - String - Optional. This value will be appended as a suffix
  if the default name is used. This value is ignored if "existingSecret" does
  configure a different name.

- context - Dict - Required. The context for the template evaluation.

*/}}

{{- define "nubus-common.secrets.name" -}}
{{- $name := printf "%s-%s" (include "common.names.fullname" .context) (default "" .defaultNameSuffix) | trunc 63 | trimSuffix "-" }}

{{- if (.existingSecret).name -}}
{{- $name = tpl .existingSecret.name .context -}}
{{- end -}}

{{- printf "%s" $name -}}
{{- end -}}


{{/*
Generate the secret key.

The generated key will take into account the configuration from the
parameter "existingSecret". It will fall back to the value of "key"
if there is no mapping configured for the key.

The implementation follows the API from the common chart of Bitnami to some extend.
It does allow and encouraged the usage of "null" vales or empty strings in the
object "keyMapping" and will use the default key name if the value is "null"
or the empty string.

Usage:

{{ include "nubus-common.secrets.key" (dict "existingSecret" .Values.path.to.the.existingSecret "key" "keyName") }}

Params:

- existingSecret - ExistingSecret - Optional. The path to the existing
  secrets in the values.yaml given by the user to be used instead of the default one.

- key - String - Required. Name of the key in the secret.

*/}}

{{- define "nubus-common.secrets.key" -}}
{{- $_ := required "Variable .key is required" .key -}}
{{- default .key (get (.existingSecret).keyMapping .key) -}}
{{- end -}}



{{/*
Manage a password.

The interface is kept similar to the one provided by
"common.secrets.passwords.manage". This template adds support for deriving secrets
from a master password instead of using random values.

Params:

- secret - String - Required - Name of the "Secret" where the password is stored. This
  "Secret" is used to find out if an existing value has already been set.

- key - String - Optional - Name of the key in the "Secret". Defaults to "password".

- providedValues - List<String> - Required - Paths to the values, e.g. "udm.auth.password".
  The first one with a defined value will be used.

- username - String - Required - The username or identity name. Used to derive the password from
  the master password.

- site - String - Optional - Value for the site. Defaults to "nubus". Only used when the
  password is derived from a master password.

- outputTemplate - String - Optional - The output template to use when deriving the password
  from the master password. Defaults to "long".

- context - Context - Required - Parent context.

- length - int - Optional - Length of the password to generate. Defaults to 16. Only used
  when no master password is supplied.

Values which configure this template:

- global.secrets.masterPassword - String - Optional - If this value is configured,
  then the secret will be derived via "deriveSecret" from this master password.
  Otherwise it will be a random value.

*/}}

{{- define "nubus-common.secrets.passwords.manage" }}
{{- $passwordValue := "" }}
{{- $username := required "Username must be provided" .username }}

{{- if (.context.Values.global.secrets).masterPassword }}

  {{- $providedPasswordKey := include "common.utils.getKeyFromList" (dict "keys" .providedValues "context" .context) }}
  {{- $passwordValue = include "common.utils.getValueFromKey" (dict "key" $providedPasswordKey "context" .context) }}
  {{- if not $passwordValue }}
    {{- $site := default "nubus" .site }}
    {{- $outputTemplate := default "long" .outputTemplate }}
    {{- $masterPassword := .context.Values.global.secrets.masterPassword }}
    {{- $passwordValue = derivePassword 1 $outputTemplate $masterPassword $username $site | sha1sum }}
  {{- end }}

{{- else }}

  {{- $passwordValue = include "common.secrets.passwords.manage"
  (dict
    "secret" .secret
    "key" (default "password" .key)
    "providedValues" .providedValues
    "context" .context
    "length" (default 16 .length)
    "skipB64enc" true
    "skipQuote" true
  ) }}

{{- end }}

{{- printf "%s" $passwordValue }}
{{- end }}
