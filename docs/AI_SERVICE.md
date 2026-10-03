# Optional AI recommendation service

Status: client adapter implemented; backend and live AI integration **not available or verified**. Leave the Parent Settings service URL empty for offline operation.

## Request contract

Enter a trusted HTTPS URL for the recommendation route. URLs containing credentials, query strings or fragments are rejected; API keys do not belong in this setting. On an explicit recommendation request, the client POSTs JSON:

```json
{
  "ageGroup": "4–5",
  "interests": ["Movement"],
  "minutes": 3,
  "adultRequired": true,
  "allowedActivityIds": ["penguin"]
}
```

Supported IDs are `penguin`, `sounds`, and `butterfly`. Only IDs whose interest matches parent settings are offered. For age 6–8, use that exact string instead. Duration must be 3, 5 or 10 minutes.

## Accepted response

The backend must return HTTP 200 with JSON:

```json
{
  "source": "ai",
  "activityId": "penguin",
  "ageGroup": "4–5",
  "minutes": 3,
  "adultRequired": true
}
```

This is a contract example, not a captured real AI result. The client requires the current age, selected duration, adult flag, a recognized catalog ID and matching interest. It uses only the returned activity ID; all displayed steps remain locally curated. The service must label a response `ai` only when it actually used AI. Client-side validation cannot independently establish server provenance.

## Failure and privacy policy

Connection timeout is five seconds, read timeout is ten seconds, and a ten-second total timeout bounds the request. Responses are capped at 8 KiB. Missing configuration, transport failure, bad status, timeout and invalid content return an explicitly labelled offline recommendation. Loading always clears; offline cards remain usable during the request. HTTP requests are destroyed and timeout handles cleared after use.

No child name, camera image, location, completion history or provider key is sent. Age band and interests are still information about the family; parents should configure only a trusted service. There is no authentication/key-entry workflow in the app. A production backend needs its own authentication, abuse controls and privacy review. Any provider credentials must be loaded from backend environment variables and never committed or embedded in the HAP.

No live server is configured by this development run. Mock-service checks verify fallback/validation code only. Backend deployment and live AI validation remain future work and do not block the offline MVP.
