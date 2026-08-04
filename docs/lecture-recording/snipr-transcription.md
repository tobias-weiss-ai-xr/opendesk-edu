# SNIpR F13 Transcription Integration Guide

> **Version:** v1.2
> **Last Updated:** March 31, 2026
> **Status:** Production Ready

## Overview

SNIpR integrates with the F13 transcription service to provide automatic speech-to-text transcription of lecture recordings. This enables searchable video content, improved accessibility, and enhanced learning experiences.

### Transcription Architecture

```
┌──────────────┐     Upload      ┌──────────────┐
│   SNIpR      │ ──────────────► │    F13       │
│   (Rust)     │  (audio/video)  │   (API)      │
└──────┬───────┘                 └──────┬───────┘
       │                                 │
       │    Transcription Job            │
       │◄────────────────────────────────│
       │     (callback with JSON)        │
       ▼                                 ▼
┌──────────────┐                 ┌──────────────┐
│  Store       │                 │  Process     │
│  Transcript  │                 │  Audio       │
└──────────────┘                 └──────────────┘
```

## Prerequisites

- SNIpR deployed and configured (see [SNIpR Setup](./snipr-setup.md))
- F13 transcription service running (see [F13 Setup](../ai/f13-setup.md))
- API key generated for SNIpR

## F13 Service Configuration

### Step 1: Deploy F13 Service

Ensure F13 is deployed with transcription enabled:

```yaml
# helmfile/environments/default/ai.yaml.gotmpl
apps:
  f13:
    enabled: true
    services:
      transcription:
        enabled: true
```

### Step 2: Generate API Key

1. Log into F13 Admin Console
2. Navigate to **API Keys** → **Add Key**
3. Configure:
   - **Name:** `snipr-transcription`
   - **Permissions:** `transcribe:write`, `transcribe:read`
   - **Expiry:** (optional, e.g., 1 year)
4. Copy the generated API key

### Step 3: Configure SNIpR

Update `helmfile/environments/default/secrets.yaml.gotmpl`:

```yaml
secrets:
  snipr:
    f13ApiKey: "${F13_API_KEY}"
```

Update `helmfile/apps/snipr/values.yaml.gotmpl`:

```yaml
snipr:
  transcription:
    enabled: true
    f13:
      endpoint: https://f13.opendesk.example.com
      apiKey: ${SNIPR_F13_API_KEY}
      model: whisper-medium
      language: de
      callbackUrl: https://snipr.opendesk.example.com/api/transcription/callback
```

Apply changes:

```bash
helmfile -e default apply --until snipr
```

## Transcription Workflow

### Step 1: Recording Upload

1. Instructor uploads video file to SNIpR
2. SNIpR stores video in S3/MinIO
3. SNIpR extracts audio track (FFmpeg)

```bash
# Example: Audio extraction command
ffmpeg -i recording.mp4 -vn -acodec libmp3lame -ab 128k audio.mp3
```

### Step 2: Transcription Request

SNIpR sends transcription request to F13:

```bash
curl -X POST https://f13.opendesk.example.com/api/transcribe \
  -H "Authorization: Bearer $F13_API_KEY" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@audio.mp3" \
  -F "model=whisper-medium" \
  -F "language=de" \
  -F "callback_url=https://snipr.opendesk.example.com/api/transcription/callback" \
  -F "format=json" \
  -F "timestamp_format=srt"
```

### Step 3: F13 Processing

F13 processes the audio:

1. **Audio normalization** - adjusts volume, removes noise
2. **Language detection** - confirms German (or specified language)
3. **Whisper inference** - runs `whisper-medium` model
4. **Timestamp alignment** - maps text to audio timestamps
5. **Confidence scoring** - assigns confidence to each segment

### Step 4: Callback to SNIpR

F13 sends transcription result to SNIpR callback endpoint:

```json
POST https://snipr.opendesk.example.com/api/transcription/callback
Content-Type: application/json
Authorization: Bearer ${SNIPR_F13_WEBHOOK_SECRET}

{
  "job_id": "transcribe_abc123",
  "recording_id": "rec_xyz789",
  "status": "completed",
  "language": "de",
  "duration": 3542.5,
  "transcript": [
    {
      "start": 0.0,
      "end": 4.2,
      "text": "Guten Morgen, herzlich willkommen zur Vorlesung.",
      "confidence": 0.95
    },
    {
      "start": 4.2,
      "end": 8.7,
      "text": "Heute behandeln wir das Thema Künstliche Intelligenz.",
      "confidence": 0.92
    }
  ],
  "words": [
    {
      "start": 0.0,
      "end": 0.5,
      "word": "Guten",
      "confidence": 0.98
    }
  ],
  "summary": "Einführungsvorlesung zu Künstlicher Intelligenz mit Fokus auf Machine Learning Grundlagen.",
  "keywords": ["KI", "Machine Learning", "Neuronale Netze"]
}
```

### Step 5: Store and Index

SNIpR stores the transcription:

1. **Database** - stores transcript metadata
2. **S3** - stores SRT/VTT files
3. **Search Index** - indexes text for full-text search
4. **Web UI** - displays synchronized transcript

## Model Selection

### Whisper Model Options

| Model | Size | RAM | Accuracy | Speed | Use Case |
|-------|------|-----|----------|-------|----------|
| `tiny` | 75 MB | 1 GB | Low | Very Fast | Quick drafts, low resources |
| `base` | 142 MB | 2 GB | Medium | Fast | Mobile, edge devices |
| `small` | 466 MB | 4 GB | Good | Medium | Standard use, balanced |
| `medium` | 769 MB | 8 GB | Very Good | Slow | **Recommended for lectures** |
| `large-v3` | 3.1 GB | 16 GB | Excellent | Very Slow | High accuracy, archival |

### Configuration

```yaml
snipr:
  transcription:
    f13:
      model: whisper-medium  # Recommended
      language: de           # German first
```

### Language Support

F13 supports multiple languages. Configure per-recording or default:

```yaml
# Default language (global)
snipr:
  transcription:
    f13:
      language: de

# Per-recording override (via API)
curl -X POST https://snipr.opendesk.example.com/api/transcribe \
  -H "Authorization: Bearer $API_KEY" \
  -F "file=@audio.mp3" \
  -F "language=en"  # Override to English
```

Supported languages:

- `de` - German (recommended for German universities)
- `en` - English
- `fr` - French
- `es` - Spanish
- `it` - Italian
- `multi` - Automatic language detection

## Callback Configuration

### Webhook Security

SNIpR validates incoming F13 callbacks using a shared secret:

```yaml
snipr:
  transcription:
    f13:
      callbackSecret: ${SNIPR_F13_WEBHOOK_SECRET}
```

**Callback validation flow:**

1. F13 signs callback with HMAC-SHA256
2. SNIpR verifies signature using shared secret
3. Only valid callbacks are processed

### Retry Logic

If SNIpR doesn't respond with 200 OK, F13 will retry:

- **Retry 1:** 1 minute after failure
- **Retry 2:** 5 minutes after failure
- **Retry 3:** 15 minutes after failure
- **Retry 4:** 60 minutes after failure
- **Max retries:** 5

## Transcription Quality

### Accuracy Factors

| Factor | Impact | Recommendation |
|--------|--------|----------------|
| **Audio quality** | High | Use good microphones, minimize background noise |
| **Model size** | Medium | Use `whisper-medium` or larger |
| **Language match** | High | Specify correct language code |
| **Academic terminology** | Medium | F13 can be fine-tuned for domain-specific terms |

### Improving Accuracy

**1. Audio Preprocessing:**

```bash
# Normalize audio before transcription
ffmpeg -i input.mp4 -af "aresample=44100,acompressor=threshold=0.3:ratio=2:attack=10:release=250" output.mp3
```

**2. Custom Vocabulary:**

```yaml
snipr:
  transcription:
    f13:
      vocabulary:
        - "Künstliche Intelligenz"
        - "Machine Learning"
        - "Neuronale Netze"
        - "Deep Learning"
```

**3. Speaker Diarization:**

```yaml
snipr:
  transcription:
    f13:
      diarization:
        enabled: true
        max_speakers: 4
```

## Search and Playback

### Transcript Search

Users can search recordings by transcript content:

```bash
# Search API endpoint
curl -X GET "https://snipr.opendesk.example.com/api/search?q=künstliche+intelligenz" \
  -H "Authorization: Bearer $USER_TOKEN"

# Response
{
  "results": [
    {
      "recording_id": "rec_xyz789",
      "title": "Einführung in KI",
      "match_count": 12,
      "snippets": [
        {
          "timestamp": 4.2,
          "text": "...behandeln wir das Thema Künstliche Intelligenz...",
          "confidence": 0.92
        }
      ]
    }
  ]
}
```

### Synchronized Playback

Web UI displays transcript synchronized with video:

```
┌─────────────────────────────────────────────┐
│  [Video Player]                             │
│  ─────────────────────────────────────────  │
│  00:04:20  │  Heute behandeln wir das      │
│            │  Thema Künstliche Intelligenz │
│  00:08:70  │  Machine Learning ist ein     │
│            │  Teilbereich davon            │
│                                               │
│  [Seek to timestamp on click]              │
└─────────────────────────────────────────────┘
```

## Fallback Configuration

If F13 is unavailable, SNIpR can use local Whisper as fallback:

```yaml
snipr:
  transcription:
    enabled: true
    f13:
      endpoint: https://f13.opendesk.example.com
      apiKey: ${F13_API_KEY}
    fallback:
      enabled: true
      engine: local
      model: whisper-small
      gpu: true  # Requires GPU node
```

**Fallback behavior:**

1. Try F13 first
2. If F13 fails (timeout, error, unreachable), use local Whisper
3. Log fallback usage for monitoring
4. Notify admin if fallback used frequently

## Monitoring and Metrics

### Transcription Metrics

Monitor transcription performance:

```bash
# Count transcription jobs
kubectl logs -l component=snipr -c snipr-api | grep "transcription" | grep "completed" | wc -l

# Average transcription time
kubectl logs -l component=snipr -c snipr-api | grep "transcription" | grep "duration" | awk '{sum+=$NF; count++} END {print sum/count}'

# F13 API error rate
kubectl logs -l component=snipr -c snipr-api | grep "f13" | grep "error" | wc -l
```

### Alerts

Configure alerts for transcription issues:

```yaml
# Prometheus alerting rules
groups:
  - name: snipr-transcription
    rules:
      - alert: SniprTranscriptionHighErrorRate
        expr: rate(snipr_transcription_errors_total[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High transcription error rate"

      - alert: SniprF13Down
        expr: up{job="snipr-f13"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "F13 transcription service is down"
```

## Troubleshooting

### Transcription Fails

**Symptom:** Recording shows "transcription failed"

**Check:**

```bash
kubectl logs -l component=snipr -c snipr-api | grep -i "transcription"
kubectl logs -l component=f13 | grep -i "error"
```

**Common causes:**

- F13 API key invalid
- Audio file format unsupported
- F13 service unreachable
- Insufficient storage for transcript

**Solution:**

```bash
# Verify F13 connectivity
curl -k https://f13.opendesk.example.com/api/health

# Test transcription manually
curl -X POST https://f13.opendesk.example.com/api/transcribe \
  -H "Authorization: Bearer $F13_API_KEY" \
  -F "file=@test-audio.mp3" \
  -F "model=whisper-medium" \
  -F "language=de"
```

### Low Transcription Accuracy

**Symptom:** Transcript contains many errors

**Check:**

- Audio quality (background noise, volume)
- Language code matches actual language
- Model size appropriate for use case

**Solution:**

- Improve audio recording quality
- Use larger model (`whisper-large-v3`)
- Add custom vocabulary for technical terms

### Callback Not Received

**Symptom:** Transcription job completed but SNIpR doesn't update

**Check:**

```bash
kubectl logs -l component=snipr -c snipr-api | grep -i "callback"
```

**Solution:**

- Verify callback URL is accessible from F13
- Check webhook secret matches
- Review SNIpR firewall rules

## Next Steps

- [LTI 1.3 Integration](./snipr-lti-integration.md)
- [SNIpR Deployment Guide](./snipr-setup.md)
- [SNIpR API Reference](./snipr-api-reference.md)

---

**Related Documentation:**

- [F13 AI Service Setup](../ai/f13-setup.md)
- [S3 Storage Configuration](../storage/s3-setup.md)
- [Monitoring and Metrics](../operations/monitoring.md)
