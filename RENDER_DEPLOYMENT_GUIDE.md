# 🚀 Render Deployment Configuration Guide

## 📋 Overview

Este proyecto usa **GitHub Actions** para deployar automáticamente a **Render** con validación completa mediante smoke tests.

---

## 🔧 Setup: Configurar Deploy Hooks de Render

### Paso 1: Obtener Deploy Hooks

#### Para el Backend:

1. Ve a: https://dashboard.render.com
2. Selecciona tu servicio **backend** (`devops-crud-app-backend`)
3. Click en **"Settings"** (en la barra lateral)
4. Scroll hasta **"Deploy Hook"**
5. Click **"Create Deploy Hook"**
6. **Copia la URL** que se genera (se ve así):
   ```
   https://api.render.com/deploy/srv-xxxxxxxxxxxxx?key=yyyyyyyyyyyyyyyy
   ```

#### Para el Frontend:

1. Ve a tu servicio **frontend** (`devops-crud-app-frontend`) en Render
2. Click en **"Settings"**
3. Scroll hasta **"Deploy Hook"**
4. Click **"Create Deploy Hook"**
5. **Copia la URL**

---

### Paso 2: Agregar Secrets en GitHub

1. Ve a tu repo: https://github.com/Joseligos/devops
2. Click **"Settings"** → **"Secrets and variables"** → **"Actions"**
3. Click **"New repository secret"**

**Agrega estos 2 secrets:**

| Name | Value |
|------|-------|
| `RENDER_DEPLOY_HOOK_BACKEND` | La URL del deploy hook del backend |
| `RENDER_DEPLOY_HOOK_FRONTEND` | La URL del deploy hook del frontend |

**Ejemplo:**
```
Name: RENDER_DEPLOY_HOOK_BACKEND
Value: https://api.render.com/deploy/srv-xxxxxxxxxxxxx?key=yyyyyyyyyyyyyyyy
```

---

## 🚀 Cómo Funciona el Deployment

### Workflow: `render-deploy.yml`

Cada push a `main` ejecuta:

```
┌─────────────────────────────────┐
│ 1. Pre-Deploy Health Check      │
│    ✓ Verifica backend actual    │
│    ✓ Verifica frontend actual   │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ 2. Deploy Backend & Frontend    │
│    ✓ Trigger via Deploy Hooks   │
│    ✓ Wait for deployment start  │
│    ✓ Monitor progress (5 min)   │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ 3. Post-Deploy Smoke Tests      │
│    ✓ Health checks (12 tests)   │
│    ✓ API functionality tests    │
│    ✓ Performance tests           │
│    ✓ Integration tests           │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ 4. Deployment Report             │
│    ✓ Summary of all checks      │
│    ✓ Links and next steps       │
│    ✓ Failure notifications       │
└─────────────────────────────────┘
```

---

## 🧪 Smoke Tests Ejecutados

El script `scripts/smoke-tests` ejecuta **12 tests reales** contra tu backend en Render:

### Health & Availability (3 tests)
- ✅ Health endpoint responds
- ✅ Health returns 200 status
- ✅ Response time < 2s

### API Functionality (5 tests)
- ✅ GET /users endpoint accessible
- ✅ GET /users returns valid JSON
- ✅ GET /users returns array
- ✅ POST /users creates resource
- ✅ POST /users returns 200 or 201

### Security (2 tests)
- ✅ HTTPS enabled
- ✅ CORS headers present

### Performance (2 tests)
- ✅ Can handle 10 concurrent requests
- ✅ Average response time < 2s

---

## 📊 Monitoring del Deployment

### Durante el Deployment

Ve el progreso en tiempo real:
- **GitHub Actions**: https://github.com/Joseligos/devops/actions
- **Render Dashboard**: https://dashboard.render.com

### Después del Deployment

Monitorea tu aplicación:
- **Grafana Cloud**: Métricas en tiempo real
- **Prometheus**: http://localhost:9090 (local)
- **Backend Metrics**: https://devops-crud-app-backend.onrender.com/metrics

---

## 🔙 Rollback en Caso de Problemas

### Opción 1: Rollback Manual en Render

1. Ve a: https://dashboard.render.com
2. Selecciona el servicio con problemas
3. Click en **"Events"** (barra lateral)
4. Encuentra el deployment anterior exitoso
5. Click **"Rollback"**

### Opción 2: Rollback con Git

```bash
# Revertir el último commit
git revert HEAD
git push origin main

# O resetear a un commit específico
git reset --hard <commit-hash>
git push --force origin main
```

---

## ⚙️ Configuración Avanzada

### Auto-Deploy en Render

Si prefieres que Render haga auto-deploy sin deploy hooks:

1. Ve a tu servicio en Render
2. **Settings** → **Build & Deploy**
3. Habilita **"Auto-Deploy"**
4. Branch: `main`

**Nota**: Con esta opción, el workflow de GitHub no triggerea el deploy, solo valida después.

### Modificar Timeouts

En `render-deploy.yml`, puedes ajustar:

```yaml
# Línea 52: Tiempo de espera inicial
sleep 30  # Cambiar a 60 si deployments son lentos

# Línea 58: Número de intentos de health check
MAX_ATTEMPTS=30  # 30 * 10s = 5 minutos total
```

### Deshabilitar Frontend Tests

Si no tienes frontend en Render, comenta el job `deploy-frontend`:

```yaml
# deploy-frontend:
#   name: 🚀 Deploy Frontend to Render
#   needs: pre-deploy-tests
#   runs-on: ubuntu-latest
#   steps:
#     ...
```

---

## 🐛 Troubleshooting

### "RENDER_DEPLOY_HOOK_BACKEND secret not found"

**Causa**: El secret no está configurado en GitHub.

**Solución**:
1. Ve a Settings → Secrets → Actions
2. Agrega el secret con el deploy hook de Render

### "Deployment timeout reached"

**Causa**: El deployment en Render está tardando más de 5 minutos.

**Solución**:
1. Aumenta `MAX_ATTEMPTS` en el workflow
2. Verifica logs en Render dashboard
3. Revisa si hay errores de build

### "Smoke tests failed"

**Causa**: Tu backend no está respondiendo correctamente después del deploy.

**Solución**:
1. Revisa logs en Render: `Logs` tab
2. Verifica variables de entorno
3. Chequea que la base de datos esté conectada

### "Backend API issue: {error message}"

**Causa**: El endpoint tiene un problema específico.

**Solución**:
1. Reproduce el error localmente
2. Revisa el código del endpoint
3. Verifica que las dependencias estén instaladas

---

## 📈 Mejoras Futuras

- [ ] Agregar tests de carga (k6, Artillery)
- [ ] Implementar blue-green deployment real en Render
- [ ] Notificaciones en Slack/Discord
- [ ] Screenshot tests para frontend
- [ ] Database migration checks
- [ ] Rollback automático si smoke tests fallan

---

## 📚 Referencias

- [Render Deploy Hooks](https://render.com/docs/deploy-hooks)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Smoke Testing Best Practices](https://martinfowler.com/bliki/SmokeTest.html)

---

**Autor**: Jose Ligos  
**Última actualización**: 20 Nov 2025
