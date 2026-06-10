# NDC Elite — Arquitectura Multiplataforma (iOS nativo + Web/PWA)

## Por qué una versión web

En el círculo cerrado de atletas hay miembros **sin iPhone**. Para ellos la
solución es una **PWA (Progressive Web App)**: una web que se "instala" desde
el navegador (Añadir a pantalla de inicio en Android/desktop) y se comporta
como app nativa — ícono propio, pantalla completa, funciona igual.

## Arquitectura

```
                    ┌──────────────────────────────┐
                    │   SUPABASE (backend único)    │
                    │  Auth · Postgres+RLS · Storage│
                    │  Realtime · Edge Functions    │
                    └──────────┬───────────┬───────┘
                               │           │
                 supabase-swift│           │supabase-js
                               │           │
                    ┌──────────┴───┐   ┌───┴──────────────┐
                    │  App iOS     │   │  PWA Web          │
                    │  (SwiftUI)   │   │  (React/Next.js)  │
                    │  App Store / │   │  instalable desde │
                    │  TestFlight  │   │  el navegador     │
                    └──────────────┘   └──────────────────┘
```

**Un solo backend, dos clientes.** Nada se duplica en el servidor.

## Por qué el backend YA está listo para web

| Capa | Estado | Detalle |
|---|---|---|
| **Auth** | ✅ listo | El mismo email+password funciona con `supabase-js` en el navegador. Sesiones y refresh tokens son manejados por el SDK. |
| **RLS** | ✅ listo | Las políticas viven en la BD, no en el cliente. iOS y web obtienen exactamente los mismos permisos (atleta ve lo suyo, coach todo). |
| **API** | ✅ listo | PostgREST acepta peticiones del navegador (CORS abierto por defecto en Supabase). |
| **Claves** | ✅ listo | La misma clave publishable (`sb_publishable_...`) sirve para ambos clientes; es pública por diseño. |
| **Realtime** | ✅ listo | Websockets funcionan igual en navegador (validaciones en vivo, ranking). |
| **Push** | ✅ preparado | Migración 11: tabla `device_tokens` con enum `platform (ios|web)` — APNs para iOS, Web Push para PWA. El envío se hará con una Edge Function (fase posterior). |

## Diferencias por plataforma (capa cliente)

| Función | iOS (SwiftUI) | Web (PWA) |
|---|---|---|
| Contactar atleta | `wa.me` deep link | `wa.me` link (idéntico) |
| Compartir logro | ShareLink | Web Share API |
| Escáner QR | AVFoundation | `getUserMedia` + lib de QR |
| Pase QR | CoreImage QR | lib QR en canvas |
| Push | APNs | Web Push (VAPID) |
| Instalación | App Store / TestFlight | "Añadir a pantalla de inicio" |

## Stack recomendado para la PWA (fase posterior)

- **Next.js (React) + supabase-js + Tailwind CSS** — Tailwind permite reusar
  los valores exactos del design system de Stitch (los HTML generados por
  Stitch ya son Tailwind, se pueden portar casi directo).
- `manifest.json` + service worker → instalable y con caché offline básica.
- Hosting gratuito: Vercel (o Netlify). Dominio del proyecto apuntando ahí.
- La página de inicio pública sirve de "descarga": detecta el dispositivo y
  ofrece instalar la PWA o el enlace a TestFlight/App Store según corresponda.

## Decisiones registradas

1. La lógica de negocio crítica vive en la BD (RLS + triggers) o en Edge
   Functions — **nunca duplicada en los clientes**.
2. Los dos clientes consumen los mismos contratos (tablas/vistas); cualquier
   cambio de esquema pasa por `supabase/migrations/` y el flujo de WORKFLOW.md.
3. La PWA se construirá en un repo separado (`NDC-Elite-Web`) cuando la app
   iOS tenga su MVP funcional.
