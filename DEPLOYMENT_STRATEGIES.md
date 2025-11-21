# 🚀 Deployment Strategies - Canary & Blue-Green

Este proyecto implementa dos estrategias avanzadas de deployment para minimizar riesgos y downtime durante despliegues en producción.

## 📋 Tabla de Contenidos

- [Estrategias Disponibles](#estrategias-disponibles)
- [Canary Deployment](#-canary-deployment)
- [Blue-Green Deployment](#-blue-green-deployment)
- [Estructura de Archivos](#-estructura-de-archivos)
- [Cómo Usar](#-cómo-usar)
- [Scripts Disponibles](#-scripts-disponibles)
- [Configuración](#-configuración)

---

## Estrategias Disponibles

### 🐤 Canary Deployment

**Cuándo usar:**
- Deployments de alto riesgo
- Necesitas validación gradual con métricas en tiempo real
- Quieres minimizar el blast radius de un bug
- Tienes monitoreo robusto (Prometheus, Grafana)

**Ventajas:**
- ✅ Riesgo minimizado (solo 5% de tráfico inicialmente)
- ✅ Rollback instantáneo
- ✅ Decisiones basadas en datos reales
- ✅ Testing en producción con tráfico real

**Desventajas:**
- ⚠️ Requiere Istio o similar para traffic splitting
- ⚠️ Más complejo de configurar
- ⚠️ Necesita métricas y análisis automatizado

### 🔵🟢 Blue-Green Deployment

**Cuándo usar:**
- Deployments con cambios de schema o breaking changes
- Necesitas rollback instantáneo completo
- Smoke tests exhaustivos antes de producción
- No tienes service mesh

**Ventajas:**
- ✅ Rollback instantáneo (cambiar selector)
- ✅ Testing completo en producción antes de switch
- ✅ Zero downtime
- ✅ Más simple que canary

**Desventajas:**
- ⚠️ Requiere doble capacidad de recursos
- ⚠️ Switching es todo o nada (no gradual)
- ⚠️ Puede requerir migración de estado

---

## 🐤 Canary Deployment

### Flujo de Trabajo

```
┌─────────────┐
│  Git Push   │
│   to main   │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│ 1. Build & Push Docker Image    │
│    ghcr.io/joseligos/devops/app │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ 2. Deploy Canary (v2)           │
│    • 1 replica with new image   │
│    • Labeled as version=v2      │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ 3. Shift 5% Traffic to Canary   │
│    • v1 (stable): 95%           │
│    • v2 (canary): 5%            │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ 4. Run Canary Analysis (10 min) │
│    ✓ Error rate < 5%            │
│    ✓ P95 latency < 1s           │
│    ✓ Success rate > 99%         │
│    ✓ CPU/Memory healthy         │
└──────────┬──────────────────────┘
           │
           ├─── ✅ Analysis PASSED ──────┐
           │                             │
           │                             ▼
           │              ┌─────────────────────────────┐
           │              │ 5. Promote Canary           │
           │              │    • 10% → 25% → 50% → 100% │
           │              │    • Gradual traffic shift  │
           │              └─────────────────────────────┘
           │
           └─── ❌ Analysis FAILED ──────┐
                                         │
                                         ▼
                          ┌─────────────────────────────┐
                          │ 6. Rollback                 │
                          │    • Revert to v1 (100%)    │
                          │    • Scale down canary to 0 │
                          └─────────────────────────────┘
```

### Manifiestos Kubernetes

**deployment-canary.yaml** incluye:

1. **Canary Deployment** (`my-app-canary`):
   - 1 replica
   - Label: `version=v2`, `subset=v2`
   - Nueva imagen

2. **Stable Deployment** (`my-app-stable`):
   - 3 replicas
   - Label: `version=v1`, `subset=v1`
   - Imagen estable actual

3. **Service**:
   - Selector: `app=my-app` (ambas versiones)
   - LoadBalancer tipo

4. **Istio VirtualService**:
   - Traffic split configurable
   - Header-based routing para testing

### Scripts

#### `scripts/canary-analysis`

Analiza métricas del canary con **DATOS REALES** del backend en producción.

**Implementación Real:**
- ✅ Genera tráfico HTTP real contra el backend (https://devops-crud-app-backend.onrender.com)
- ✅ Mide latencia real de cada request (ms)
- ✅ Calcula P95, promedio, mín y máx de latencias
- ✅ Cuenta errores reales (HTTP codes != 200)
- ✅ Prueba endpoints: `/healthz` y `/users`
- ✅ Validación funcional con POST/GET real
- ✅ Integración opcional con Grafana Cloud (set GRAFANA_TOKEN)

**Métricas evaluadas (REALES):**
- Error rate (threshold: <5%) - calculado de requests reales
- P95 latency (threshold: <1000ms) - medido en producción
- Success rate (threshold: >99%) - de requests HTTP reales
- API functionality - POST/GET a `/users` verificados

**Uso:**
```bash
# Genera 6 requests reales durante 30 segundos
./scripts/canary-analysis --baseline v1 --canary v2 --duration 30s

# Genera 12 requests durante 1 minuto
./scripts/canary-analysis --baseline v1 --canary v2 --duration 1m

# Con métricas de Grafana Cloud
GRAFANA_TOKEN=your_token ./scripts/canary-analysis --baseline v1 --canary v2 --duration 5m
```

**Exit codes:**
- `0`: Análisis pasó, canary es saludable
- `1`: Análisis falló, NO promover

**Ejemplo de Output Real:**
```
🔍 Starting REAL Canary Analysis

📊 Analyzing Real Metrics...

1️⃣  Error Rate Analysis (REAL DATA)
   Total Requests: 6
   Successful: 6
   Failed: 0
   Error Rate: 0.00%
   ✅ PASS: Error rate within acceptable range

2️⃣  Latency Analysis (REAL DATA)
   Average Latency: 415ms
   P95 Latency: 534ms
   Min: 350ms
   Max: 534ms
   ✅ PASS: Latency within acceptable range

3️⃣  Request Success Rate (REAL DATA)
   Success Rate: 100.00%
   ✅ PASS: Success rate acceptable

4️⃣  API Functionality Tests (REAL)
   Testing GET /users...
   ✅ GET endpoint working
   Testing POST /users...
   ✅ POST endpoint working
```

#### `scripts/promote-canary-to-primary`

Promociona el canary gradualmente de 5% → 100% tráfico.

**Etapas:**
1. 10% canary, 90% stable
2. 25% canary, 75% stable
3. 50% canary, 50% stable
4. 75% canary, 25% stable
5. 100% canary, 0% stable

Entre cada etapa:
- Espera 30 segundos
- Health check
- Si error rate > 5%, rollback automático

**Uso:**
```bash
./scripts/promote-canary-to-primary
```

#### `scripts/rollback-canary`

Revierte todo el tráfico a la versión estable.

**Acciones:**
- Shift 100% tráfico a v1
- Scale canary deployment a 0 replicas
- Logs para investigación

**Uso:**
```bash
./scripts/rollback-canary
```

### Workflow GitHub Actions

**Archivo:** `.github/workflows/canary.yml`

**Trigger:** Push a `main` branch

**Jobs:**
1. `build`: Build y push imagen Docker
2. `deploy-canary`: Deploy canary + traffic shift + analysis + promotion/rollback

**Modo Simulación:**
- No requiere cluster Kubernetes real
- Valida manifiestos
- Ejecuta scripts de análisis
- Muestra output detallado de cada paso

---

## 🔵🟢 Blue-Green Deployment

### Flujo de Trabajo

```
┌─────────────┐
│  Git Push   │
│   to main   │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│ 1. Build & Push Docker Image    │
│    ghcr.io/joseligos/devops/app │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ 2. Deploy to Green Environment  │
│    • 3 replicas in 'green' ns   │
│    • New image                  │
│    • Not receiving traffic yet  │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ 3. Run Smoke Tests on Green     │
│    ✓ Health endpoint            │
│    ✓ API functionality          │
│    ✓ Security headers           │
│    ✓ Performance                │
└──────────┬──────────────────────┘
           │
           ├─── ✅ Tests PASSED ──────────┐
           │                              │
           │                              ▼
           │               ┌────────────────────────────┐
           │               │ 4. Switch Traffic to Green │
           │               │    • Patch service selector│
           │               │    • version: blue → green │
           │               │    • Instant switch        │
           │               └────────────────────────────┘
           │
           └─── ❌ Tests FAILED ──────────┐
                                          │
                                          ▼
                           ┌────────────────────────────┐
                           │ Deployment Stops           │
                           │ • Green stays idle         │
                           │ • Blue continues serving   │
                           │ • Investigate failures     │
                           └────────────────────────────┘
```

### Manifiestos Kubernetes

**deployment-green.yaml** incluye:

1. **Green Deployment** (namespace: `green`):
   - 3 replicas
   - Label: `version=green`
   - Nueva imagen
   - Service: `my-app-green` (internal)

2. **Blue Deployment** (namespace: `blue`):
   - 3 replicas
   - Label: `version=blue`
   - Imagen estable
   - Service: `my-app-blue` (internal)

3. **Production Service** (namespace: `production`):
   - Selector configurable: `version: blue` o `version: green`
   - LoadBalancer tipo
   - Esto es lo que se cambia para el switch

### Scripts

#### `scripts/smoke-tests`

Suite completa de tests de humo con **VALIDACIÓN REAL** contra el backend en producción.

**Implementación Real:**
- ✅ 12 tests funcionales contra backend real
- ✅ Validación de endpoints `/healthz` y `/users`
- ✅ Medición real de latencia y performance
- ✅ Tests de concurrencia (10 requests simultáneos)
- ✅ Validación de seguridad (HTTPS, CORS)

**Tests incluidos (TODOS REALES):**

**Health & Availability (3 tests):**
- Health endpoint `/healthz` responde
- HTTP 200 status verificado
- Response time < 2 segundos

**API Functionality (5 tests):**
- GET `/users` accesible
- Retorna JSON válido
- Retorna array de usuarios
- POST `/users` crea recurso con datos reales
- POST retorna 200 o 201

**Security (2 tests):**
- HTTPS habilitado y funcionando
- CORS headers presentes

**Performance (2 tests):**
- Maneja 10 requests concurrentes sin fallos
- Average response time < 2s (medido en 5 requests reales)

**Uso:**
```bash
# Usa backend de producción por defecto
./scripts/smoke-tests

# O especifica un URL diferente
./scripts/smoke-tests https://green.example.com
```

**Exit codes:**
- `0`: Todos los 12 tests pasaron, green listo para producción
- `1`: Uno o más tests fallaron, NO hacer switch

**Ejemplo de Output Real:**
```
🧪 Running REAL Smoke Tests
   Target: https://devops-crud-app-backend.onrender.com

═══════════════════════════════════════════
🏥 Health & Availability Tests
═══════════════════════════════════════════

[1] Health endpoint responds... ✅ PASS
[2] Health returns 200 status... ✅ PASS
[3] Response time < 2s... ✅ PASS

═══════════════════════════════════════════
🔧 API Functionality Tests
═══════════════════════════════════════════

[4] GET /users endpoint accessible... ✅ PASS
[5] GET /users returns valid JSON... ✅ PASS
[6] GET /users returns array... ✅ PASS
[7] POST /users creates resource... ✅ PASS
[8] POST /users returns 200 or 201... ✅ PASS

═══════════════════════════════════════════
🔐 Security Tests
═══════════════════════════════════════════

[9] HTTPS enabled... ✅ PASS
[10] CORS headers present... ✅ PASS

═══════════════════════════════════════════
📊 Performance Tests
═══════════════════════════════════════════

[11] Can handle 10 concurrent requests... ✅ PASS
[12] Average response time... ✅ PASS (.358s avg)

═══════════════════════════════════════════
📈 Test Results Summary
═══════════════════════════════════════════

   Total Tests: 12
   Passed: 12
   Failed: 0

✅ ALL SMOKE TESTS PASSED

🟢 Green environment is healthy and ready for production traffic
```

### Workflow GitHub Actions

**Archivo:** `.github/workflows/bluegreen.yml`

**Trigger:** Push a `main` branch

**Jobs:**
1. `build`: Build y push imagen Docker
2. `deploy-green`: Deploy a green environment + smoke tests
3. `switch-traffic`: Switch production service a green

**Modo Simulación:**
- No requiere cluster Kubernetes real
- Valida manifiestos
- Ejecuta smoke tests contra backend real
- Muestra comandos que se ejecutarían

---

## 📁 Estructura de Archivos

```
DevOps/
├── .github/
│   └── workflows/
│       ├── canary.yml           # Canary deployment pipeline
│       └── bluegreen.yml        # Blue-Green deployment pipeline
├── k8s/
│   ├── deployment-canary.yaml   # Canary + Stable deployments
│   ├── deployment-green.yaml    # Blue + Green deployments
│   └── istio-virtualservice.yaml # Traffic splitting config
├── scripts/
│   ├── canary-analysis          # Automated canary metrics analysis
│   ├── promote-canary-to-primary # Gradual traffic promotion
│   ├── rollback-canary          # Emergency rollback
│   └── smoke-tests              # Pre-production validation tests
└── DEPLOYMENT_STRATEGIES.md     # Esta documentación
```

---

## 🚀 Cómo Usar

### Para Canary Deployment

1. **Hacer cambios en el código:**
   ```bash
   git add .
   git commit -m "feat: new feature"
   git push origin main
   ```

2. **GitHub Actions automáticamente:**
   - ✅ Build imagen Docker
   - ✅ Deploy canary (5% traffic)
   - ✅ Analiza métricas por 10 minutos
   - ✅ Promociona o rollback basado en análisis

3. **Monitorear en GitHub Actions:**
   - Ve a: https://github.com/Joseligos/devops/actions
   - Selecciona el workflow "CI-CD Canary"
   - Observa el progreso y logs

4. **Si algo sale mal:**
   - El rollback es automático
   - Revisa logs en Grafana
   - Investiga causa raíz

### Para Blue-Green Deployment

1. **Hacer cambios en el código:**
   ```bash
   git add .
   git commit -m "feat: major update"
   git push origin main
   ```

2. **GitHub Actions automáticamente:**
   - ✅ Build imagen Docker
   - ✅ Deploy a green environment
   - ✅ Run smoke tests
   - ✅ Switch traffic si tests pasan

3. **Monitorear en GitHub Actions:**
   - Ve a: https://github.com/Joseligos/devops/actions
   - Selecciona el workflow "CI-CD Blue-Green"
   - Revisa resultados de smoke tests

4. **Rollback manual si es necesario:**
   ```bash
   # Si detectas problemas después del switch
   kubectl -n production patch service my-app \
     -p '{"spec":{"selector":{"version":"blue"}}}'
   ```

---

## 🔧 Scripts Disponibles

### Canary Scripts

| Script | Descripción | Uso |
|--------|-------------|-----|
| `canary-analysis` | Analiza métricas canary vs baseline | `./scripts/canary-analysis --baseline v1 --canary v2 --duration 10m` |
| `promote-canary-to-primary` | Promoción gradual 10%→100% | `./scripts/promote-canary-to-primary` |
| `rollback-canary` | Rollback a versión estable | `./scripts/rollback-canary` |

### Blue-Green Scripts

| Script | Descripción | Uso |
|--------|-------------|-----|
| `smoke-tests` | Suite de tests pre-producción | `./scripts/smoke-tests --url https://green.example.com` |

### Ejecutar Scripts Manualmente

Todos los scripts están en `/scripts` y son ejecutables:

```bash
# Análisis manual de canary
cd /home/joseligo/DevOps
./scripts/canary-analysis --baseline v1 --canary v2 --duration 5m

# Smoke tests manuales
./scripts/smoke-tests --url https://devops-crud-app-backend.onrender.com

# Promoción manual
./scripts/promote-canary-to-primary

# Rollback manual
./scripts/rollback-canary
```

---

## ⚙️ Configuración

### Variables de Entorno

#### Para Canary

```yaml
# .github/workflows/canary.yml
env:
  ISTIO_NAMESPACE: production  # Namespace donde deployar
```

En scripts:
```bash
export PROMETHEUS_URL="http://localhost:9090"
export BACKEND_URL="https://devops-crud-app-backend.onrender.com"
```

#### Para Blue-Green

```yaml
# .github/workflows/bluegreen.yml
# No requiere variables adicionales en simulación
```

### GitHub Secrets (Para Deployment Real)

Si quieres deployar a un cluster real de Kubernetes:

1. Ve a: Settings → Secrets and variables → Actions
2. Agrega:
   - `KUBE_CONFIG`: Tu kubeconfig file (base64 encoded)

```bash
# Generar KUBE_CONFIG secret
cat ~/.kube/config | base64 -w 0
```

### Istio Configuration (Para Canary Real)

Si tienes Istio instalado:

```bash
# Aplicar manifiestos de Istio
kubectl apply -f k8s/istio-virtualservice.yaml -n production

# Verificar VirtualService
kubectl get virtualservice -n production

# Verificar DestinationRule
kubectl get destinationrule -n production
```

---

## 📊 Métricas y Monitoreo

### Prometheus Queries para Canary Analysis

```promql
# Error rate por versión
sum(rate(http_requests_total{status=~"5.*", version="v2"}[5m])) 
/ 
sum(rate(http_requests_total{version="v2"}[5m])) * 100

# P95 latency por versión
histogram_quantile(0.95, 
  rate(http_request_duration_seconds_bucket{version="v2"}[5m])
)

# Success rate por versión
sum(rate(http_requests_total{status=~"2..", version="v2"}[5m])) 
/ 
sum(rate(http_requests_total{version="v2"}[5m])) * 100

# Requests por segundo por versión
sum(rate(http_requests_total{version="v2"}[1m]))
```

### Grafana Dashboards

Crear panel para comparar v1 vs v2:

```
┌─────────────────────────────────────────┐
│  Error Rate: v1 vs v2                   │
│  ─────────────────────────                │
│  v1: 0.05%  ✅                          │
│  v2: 0.08%  ⚠️                          │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  P95 Latency: v1 vs v2                  │
│  ─────────────────────────                │
│  v1: 120ms  ✅                          │
│  v2: 150ms  ✅                          │
└─────────────────────────────────────────┘
```

---

## 🆘 Troubleshooting

### Canary Deployment Issues

**Problema:** Canary analysis siempre falla
```bash
# Verificar que Prometheus está scrapeando
curl http://localhost:9090/api/v1/targets

# Verificar que métricas existen
curl http://localhost:9090/api/v1/query?query=http_requests_total

# Run analysis con más detalle
./scripts/canary-analysis --baseline v1 --canary v2 --duration 2m
```

**Problema:** Traffic no se está dividiendo
```bash
# Verificar VirtualService
kubectl get virtualservice -n production my-app -o yaml

# Verificar que pods tienen labels correctos
kubectl get pods -n production --show-labels
```

### Blue-Green Deployment Issues

**Problema:** Smoke tests fallan
```bash
# Run tests con más detalle
./scripts/smoke-tests --url https://devops-crud-app-backend.onrender.com

# Verificar endpoint específico
curl -v https://devops-crud-app-backend.onrender.com/healthz
```

**Problema:** Traffic switch no funciona
```bash
# Verificar service selector actual
kubectl get svc -n production my-app -o yaml | grep selector

# Verificar que pods green tienen labels correctos
kubectl get pods -n green --show-labels
```

### GitHub Actions Issues

**Problema:** Workflow falla en build step
```bash
# Verificar permisos de packages
# Settings → Actions → General → Workflow permissions
# Debe estar en "Read and write permissions"
```

**Problema:** Scripts no son ejecutables
```bash
chmod +x scripts/*
git add scripts/
git commit -m "fix: make scripts executable"
git push origin main
```

---

## 📚 Referencias

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Istio Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/)
- [Canary Deployments](https://martinfowler.com/bliki/CanaryRelease.html)
- [Blue-Green Deployments](https://martinfowler.com/bliki/BlueGreenDeployment.html)
- [GitHub Actions](https://docs.github.com/en/actions)

---

## 🎯 Próximos Pasos

1. **Integrar con Cluster Real:**
   - Provisionar cluster K8s (EKS, GKE, AKS)
   - Instalar Istio
   - Configurar `KUBE_CONFIG` secret

2. **Mejorar Análisis Canary:**
   - Integrar queries reales a Prometheus
   - Agregar más métricas (latency percentiles, apdex score)
   - Alertas automáticas en Slack

3. **Automated Rollback:**
   - Detectar degradación automáticamente
   - Rollback sin intervención humana
   - Post-mortem automático

4. **Progressive Delivery:**
   - Feature flags
   - User-based routing
   - Geo-based routing

---

**¿Preguntas?** Abre un issue en GitHub o consulta los logs de los workflows.

**Autor:** Jose Ligos  
**Proyecto:** DevOps CRUD App  
**Última actualización:** 19 Nov 2025
