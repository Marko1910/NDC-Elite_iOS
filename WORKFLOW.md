# NDC Elite — Flujo de Trabajo (staging → producción)

## Entornos

| Entorno | Supabase | Rama git | Uso |
|---|---|---|---|
| **Staging** | proyecto `NDC-Elite-staging` (free) | `staging` | Probar TODOS los cambios primero |
| **Producción** | proyecto `rdbibgwnmrifscisicgv` | `main` | Solo cambios ya probados en staging |

> Supabase Branching nativo requiere plan Pro; usamos dos proyectos free,
> que logra el mismo aislamiento sin costo.

## Flujo por cada cambio

```
1. Crear rama desde main, nombrada por el cambio:
     git checkout main && git pull
     git checkout -b feature/<nombre-del-cambio>     # ej. feature/dashboard-atleta

2. Desarrollar. Si hay cambios de BD → escribir SIEMPRE un archivo nuevo en
   supabase/migrations/ (nunca editar migraciones ya aplicadas).

3. Integrar a staging y probar:
     git checkout staging && git merge feature/<nombre-del-cambio>
     git push origin staging
   → aplicar las migraciones nuevas en la BD de STAGING (MCP supabase-staging)
   → probar la app apuntando a staging

4. Si todo OK, elevar a producción:
     git checkout main && git merge staging
     git push origin main
   → aplicar las mismas migraciones en la BD de PRODUCCIÓN (MCP supabase)

5. Borrar la rama feature:
     git branch -d feature/<nombre-del-cambio>
```

## Reglas

- **Nunca** aplicar una migración directamente en producción sin haberla probado en staging.
- Las migraciones son **inmutables**: para corregir una, se crea otra nueva.
- Las migraciones de datos semilla usan `on conflict do nothing` (idempotentes).
- La app iOS apunta a **producción** por defecto; para probar staging se cambia
  `SupabaseManager` (TODO: hacer esto configurable por scheme de Xcode).

## Releases

- Repo de releases: **`NDC-Elite-Releases`** (lo crea y administra Marco).
- Ahí se publican los builds/actualizaciones de la app con sus notas de versión.
- El versionado sigue `MARKETING_VERSION` del proyecto Xcode (semver: 1.0.0, 1.1.0...).

## MCP de Supabase en Claude Code

- `supabase` → producción (project_ref `rdbibgwnmrifscisicgv`)
- `supabase-staging` → staging (registrar cuando exista el proyecto):
  ```
  claude mcp add --transport http supabase-staging "https://mcp.supabase.com/mcp?project_ref=<REF_STAGING>"
  ```
  (reiniciar Claude Code después de registrarlo)
