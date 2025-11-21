# 🚀 Estrategias de Deployment Modernas

## Presentación: Canary vs Blue-Green Deployment

---

## 📋 ¿Qué es un Deployment?

**Deployment** = Llevar tu aplicación nueva a producción (donde los usuarios la usan)

**El problema tradicional:**
```
Versión Vieja    →    Apagar Servidor    →    Subir Versión Nueva
   (v1.0)              (¡DOWNTIME! 😱)            (v2.0)
```

❌ Los usuarios se quedan sin servicio
❌ Si la nueva versión falla, todos sufren
❌ No hay forma de probar antes

**La solución moderna:** Deployments sin downtime y con validación automática

---

## 🎯 Nuestra Aplicación

**Backend Node.js en Render:**
- URL: `https://devops-crud-app-backend.onrender.com`
- Endpoints:
  - `/healthz` - Verifica que el servidor esté vivo
  - `/users` - API para gestionar usuarios (GET, POST, PUT, DELETE)

**¿Cómo desplegamos cambios sin que los usuarios lo noten?**

→ Usamos 2 estrategias: **Canary** y **Blue-Green**

---

## 🐤 Canary Deployment - "El Canario en la Mina"

### 🤔 ¿Qué es?

Imagina que tienes una mina de carbón y quieres saber si el aire es seguro. Los mineros llevaban un canario 🐤. Si el canario moría, ¡era momento de salir!

**En software es igual:**
- Envías la nueva versión solo a un **pequeño grupo de usuarios** (5%)
- Si funciona bien → aumentas gradualmente (10%, 25%, 50%, 100%)
- Si falla → solo afectaste al 5%, los demás siguen con la versión vieja

### 📊 ¿Cómo funciona en nuestra app?

```
ANTES del Deployment:
┌────────────────────────────┐
│  100% usuarios → v1.0      │  ← Todos usan la versión vieja
└────────────────────────────┘

DURANTE Canary:
┌────────────────────────────┐
│   95% usuarios → v1.0      │  ← La mayoría sigue en vieja
├────────────────────────────┤
│    5% usuarios → v2.0 🐤   │  ← Grupo pequeño prueba nueva
└────────────────────────────┘

Si todo va bien → Aumentamos gradualmente:
   10% → 25% → 50% → 75% → 100%

Si algo falla → Regresamos todo al 100% v1.0
```

### ⚙️ Implementación Real en GitHub Actions

**Cuando haces `git push`:**

1. **Build (2 min):**
   ```
   ✅ Construye imagen Docker con tu código nuevo
   ✅ La sube a GitHub Container Registry
   ```

2. **Deploy Canary (1 min):**
   ```
   ✅ Despliega la versión nueva (v2.0) en un servidor separado
   ✅ Configura que solo el 5% del tráfico vaya ahí
   ```

3. **Análisis REAL (30 segundos):**
   ```
   El script genera tráfico REAL contra ambas versiones:
   
   📊 Midiendo v1.0 (versión vieja):
      • 6 requests HTTP reales
      • Latencia promedio: 380ms
      • 100% exitosas
   
   📊 Midiendo v2.0 (canario):
      • 6 requests HTTP reales
      • Latencia promedio: 415ms
      • 100% exitosas
   
   ✅ Comparación:
      • Error rate: 0% (threshold: <5%) ✅
      • Latencia: 415ms (threshold: <1000ms) ✅
      • Funcionalidad: GET/POST /users funcionan ✅
   ```

4. **Decisión Automática:**
   ```
   SI todo está OK:
      → Promoción gradual 5% → 10% → 25% → 50% → 100%
   
   SI algo falla:
      → Rollback automático a v1.0
      → Solo el 5% de usuarios vio el problema
   ```

### 📈 Métricas Reales que Medimos

Nuestro script `canary-analysis` hace requests HTTP reales y mide:

```bash
🔍 Starting REAL Canary Analysis

📊 Analyzing Real Metrics...

1️⃣  Error Rate Analysis (REAL DATA)
   Total Requests: 6
   Successful: 6
   Failed: 0
   Error Rate: 0.00%
   ✅ PASS

2️⃣  Latency Analysis (REAL DATA)
   Average Latency: 415ms
   P95 Latency: 534ms    # 95% de requests son más rápidos que esto
   ✅ PASS

3️⃣  Request Success Rate (REAL DATA)
   Success Rate: 100.00%
   ✅ PASS

4️⃣  API Functionality Tests (REAL)
   Testing GET /users... ✅
   Testing POST /users... ✅
```

### ✅ Ventajas del Canary

- 🎯 **Bajo riesgo:** Solo el 5% inicial experimenta problemas
- 📊 **Datos reales:** Probamos con usuarios reales, no simulaciones
- ⚡ **Rollback rápido:** Si falla, solo afectaste al 5%
- 🤖 **Automático:** Todo el proceso es automático en GitHub Actions

### ⚠️ Desventajas

- 🏗️ **Complejo:** Necesitas infraestructura que pueda dividir tráfico
- 📈 **Requiere monitoreo:** Necesitas medir métricas en tiempo real
- ⏱️ **Más lento:** Toma más tiempo que desplegar todo de una vez

### 🎬 Cuándo usar Canary

✅ Cuando el cambio es riesgoso (cambios grandes en el código)
✅ Cuando tienes muchos usuarios (un 5% es suficiente para probar)
✅ Cuando puedes medir el impacto (tienes métricas configuradas)

---

## 🔵🟢 Blue-Green Deployment - "Dos Ambientes Idénticos"

### 🤔 ¿Qué es?

Imagina que tienes **dos casas idénticas**:
- 🔵 **Casa Azul:** Donde vives actualmente (producción actual)
- 🟢 **Casa Verde:** La nueva casa que estás preparando

Preparas todo en la casa verde, y cuando está lista, **simplemente cambias de casa**. Si algo sale mal, regresas a la azul.

### 📊 ¿Cómo funciona en nuestra app?

```
ANTES del Deployment:
┌─────────────────────────────┐
│  🔵 BLUE Environment        │
│  • Versión v1.0             │
│  • 100% del tráfico aquí    │ ← Todos los usuarios
└─────────────────────────────┘

┌─────────────────────────────┐
│  🟢 GREEN Environment       │
│  • Vacío o con v0.9         │
│  • 0% tráfico               │ ← Nadie usa esto
└─────────────────────────────┘

PREPARANDO el Deployment:
┌─────────────────────────────┐
│  🔵 BLUE Environment        │
│  • Versión v1.0             │
│  • 100% tráfico             │ ← Usuarios siguen aquí
└─────────────────────────────┘

┌─────────────────────────────┐
│  🟢 GREEN Environment       │
│  • Versión v2.0 ← Nueva!    │
│  • 0% tráfico (probando)    │ ← Corremos tests aquí
└─────────────────────────────┘

Tests pasan → SWITCH!
┌─────────────────────────────┐
│  🔵 BLUE Environment        │
│  • Versión v1.0             │
│  • 0% tráfico               │ ← Por si necesitamos volver
└─────────────────────────────┘

┌─────────────────────────────┐
│  🟢 GREEN Environment       │
│  • Versión v2.0             │
│  • 100% tráfico ✅          │ ← Todos aquí ahora
└─────────────────────────────┘
```

### ⚙️ Implementación Real en GitHub Actions

**Cuando haces `git push`:**

1. **Build (2 min):**
   ```
   ✅ Construye imagen Docker con tu código nuevo
   ✅ La sube a GitHub Container Registry
   ```

2. **Deploy to Green (1 min):**
   ```
   ✅ Despliega v2.0 en el ambiente verde
   ✅ Los usuarios siguen en azul (no notan nada)
   ```

3. **Smoke Tests REALES (30 segundos):**
   ```
   El script hace 12 tests funcionales contra el ambiente verde:
   
   🧪 Running REAL Smoke Tests
   
   🏥 Health & Availability Tests
   [1] Health endpoint responds... ✅ PASS
   [2] Health returns 200 status... ✅ PASS
   [3] Response time < 2s... ✅ PASS
   
   🔧 API Functionality Tests
   [4] GET /users accessible... ✅ PASS
   [5] GET /users returns JSON... ✅ PASS
   [6] GET /users returns array... ✅ PASS
   [7] POST /users creates user... ✅ PASS
   [8] POST /users returns 201... ✅ PASS
   
   🔐 Security Tests
   [9] HTTPS enabled... ✅ PASS
   [10] CORS headers present... ✅ PASS
   
   📊 Performance Tests
   [11] Handles 10 concurrent requests... ✅ PASS
   [12] Avg response < 2s... ✅ PASS (.358s avg)
   
   ═══════════════════════════════════════
   ✅ ALL 12 TESTS PASSED
   ```

4. **Traffic Switch (instantáneo):**
   ```
   SI los 12 tests pasan:
      → Cambiar 100% del tráfico de Blue → Green
      → Usuarios ahora usan v2.0
   
   SI algún test falla:
      → NO hacer el switch
      → Usuarios siguen en Blue (v1.0)
      → Investigar qué falló en Green
   ```

5. **Rollback si es necesario (instantáneo):**
   ```
   Si después del switch detectas problemas:
      → Simplemente cambiar tráfico Green → Blue
      → En 1 segundo, todos están en la versión vieja
   ```

### 📋 Los 12 Smoke Tests Explicados

**¿Por qué 12 tests?** Porque validamos TODO antes de mover usuarios:

```
🏥 SALUD (3 tests):
   ¿El servidor responde?
   ¿Devuelve HTTP 200?
   ¿Responde rápido (< 2s)?

🔧 FUNCIONALIDAD (5 tests):
   ¿GET /users funciona?
   ¿Devuelve JSON válido?
   ¿Devuelve un array de usuarios?
   ¿POST /users crea usuarios nuevos?
   ¿Devuelve código 200 o 201?

🔐 SEGURIDAD (2 tests):
   ¿HTTPS está activo?
   ¿Headers CORS están configurados?

📊 PERFORMANCE (2 tests):
   ¿Aguanta 10 requests simultáneos?
   ¿Latencia promedio < 2 segundos?
```

Si **UNO SOLO** falla → NO hacemos el switch

### ✅ Ventajas del Blue-Green

- ⚡ **Rollback instantáneo:** Un click y vuelves a la versión vieja
- 🧪 **Pruebas completas:** Pruebas el ambiente completo antes del switch
- 0️⃣ **Zero downtime:** Los usuarios nunca ven caídas
- 🎯 **Simple de entender:** O estás en azul o en verde, no hay grises

### ⚠️ Desventajas

- 💰 **Caro:** Necesitas el doble de recursos (dos ambientes completos)
- 🔄 **Todo o nada:** No puedes probar con 5%, es 100% de una vez
- 📊 **Base de datos:** Si cambias el schema de DB, es más complejo

### 🎬 Cuándo usar Blue-Green

✅ Cuando necesitas validación exhaustiva antes de producción
✅ Cuando el rollback debe ser instantáneo
✅ Cuando no tienes herramientas para dividir tráfico (no tienes service mesh)
✅ Cuando haces cambios en la base de datos

---

## 🆚 Canary vs Blue-Green - Comparación Directa

| Aspecto | 🐤 Canary | 🔵🟢 Blue-Green |
|---------|-----------|-----------------|
| **¿Cómo prueba?** | Con 5% de usuarios reales | Con 0 usuarios (ambiente aislado) |
| **Velocidad del rollout** | Gradual: 5% → 10% → 25% → 50% → 100% | Instantáneo: 0% → 100% |
| **Si algo falla** | Solo el 5% inicial se afecta | Los tests detectan antes de que usuarios lo vean |
| **Recursos necesarios** | 105% (100% + 5% canary) | 200% (100% blue + 100% green) |
| **Complejidad** | Alta (necesitas service mesh) | Media (solo necesitas dos ambientes) |
| **Rollback** | Rápido (regresas el tráfico) | Instantáneo (cambias el selector) |
| **Mejor para** | Cambios riesgosos con muchos usuarios | Cambios con breaking changes o schema |

---

## 🛠️ Nuestra Implementación Técnica

### Tecnologías Usadas

```
📦 Backend:
   • Node.js + Express
   • Desplegado en Render
   • URL: devops-crud-app-backend.onrender.com

🐳 Containers:
   • Docker para empaquetar la app
   • GitHub Container Registry (ghcr.io)

🤖 CI/CD:
   • GitHub Actions (automatización)
   • 2 workflows: canary.yml y bluegreen.yml

📊 Validación:
   • Scripts en Bash
   • Requests HTTP reales con curl
   • Medición de latencias y error rates

🎯 Endpoints de nuestra API:
   • GET  /healthz        → Verifica salud
   • GET  /users          → Lista usuarios
   • POST /users          → Crea usuario
   • PUT  /users/:id      → Actualiza usuario
   • DELETE /users/:id    → Elimina usuario
```

### Archivos Clave del Proyecto

```
DevOps/
├── .github/workflows/
│   ├── canary.yml          ← Workflow de Canary
│   └── bluegreen.yml       ← Workflow de Blue-Green
│
├── scripts/
│   ├── canary-analysis     ← Analiza métricas reales (latencia, errors)
│   ├── promote-canary-to-primary  ← Aumenta tráfico gradualmente
│   ├── rollback-canary     ← Revierte a versión vieja
│   └── smoke-tests         ← Los 12 tests de validación
│
├── k8s/
│   ├── deployment-canary.yaml    ← Manifiestos Kubernetes para Canary
│   ├── deployment-green.yaml     ← Manifiestos para Blue-Green
│   └── istio-virtualservice.yaml ← Configuración de tráfico
│
└── backend/
    ├── index.js            ← Código del servidor
    └── package.json        ← Dependencias
```

---

## 🎯 Flujo Completo: De Código a Producción

### Escenario: Añadimos una nueva feature

**1. Desarrollador escribe código:**
```bash
# Añades un nuevo endpoint: GET /users/stats
git add .
git commit -m "feat: add user statistics endpoint"
git push origin main
```

**2. GitHub Actions se activa automáticamente:**

```
🤖 Workflow Iniciado: Canary Deployment

⏱️  [00:00] Clonando repositorio...
⏱️  [00:30] Construyendo imagen Docker...
⏱️  [02:00] Subiendo a ghcr.io/joseligos/devops/app:abc123...
⏱️  [02:30] Desplegando canary (5% tráfico)...
⏱️  [03:00] Iniciando análisis de métricas...

📊 [03:00-03:30] Generando tráfico real:
    • Haciendo requests a v1.0 (versión vieja)
    • Haciendo requests a v2.0 (canary con nueva feature)
    • Midiendo latencias...
    • Contando errores...

✅ [03:30] Análisis completado:
    • Error rate: 0% (threshold: <5%) ✅
    • Latencia P95: 420ms (threshold: <1000ms) ✅
    • Success rate: 100% (threshold: >99%) ✅
    • GET /users/stats funcionando ✅

🚀 [03:30] Iniciando promoción gradual:
    • 10% tráfico a canary... ✅ (30s)
    • 25% tráfico a canary... ✅ (30s)
    • 50% tráfico a canary... ✅ (30s)
    • 75% tráfico a canary... ✅ (30s)
    • 100% tráfico a canary... ✅ (30s)

✅ [05:30] Deployment completado exitosamente!
    Todos los usuarios ahora tienen acceso a /users/stats
```

**3. Usuarios nunca notaron nada:**
- No hubo downtime
- El cambio fue gradual y validado
- Si hubiera fallado, solo el 5% inicial se afectaba

---

## 📊 Demo en Vivo

### Puedes probar los scripts tú mismo:

**1. Canary Analysis (genera tráfico real durante 30s):**
```bash
cd DevOps
./scripts/canary-analysis --baseline v1 --canary v2 --duration 30s
```

Verás algo como:
```
🔍 Starting REAL Canary Analysis
   Baseline: v1
   Canary: v2
   Duration: 30s

⏱️  Monitoring for 30 seconds...
📊 Running real traffic against backend...

🚀 Generating load (6 requests)...
[Haciendo requests reales a producción...]

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

✅ REAL CANARY ANALYSIS PASSED
```

**2. Smoke Tests (12 tests funcionales):**
```bash
cd DevOps
./scripts/smoke-tests
```

Verás:
```
🧪 Running REAL Smoke Tests
   Target: https://devops-crud-app-backend.onrender.com

[1] Health endpoint responds... ✅ PASS
[2] Health returns 200 status... ✅ PASS
[3] Response time < 2s... ✅ PASS
[4] GET /users endpoint accessible... ✅ PASS
...
[12] Average response time... ✅ PASS (.358s avg)

✅ ALL SMOKE TESTS PASSED
🟢 Green environment is healthy and ready for production traffic
```

---

## 🎓 Conclusiones

### ¿Qué aprendimos?

1. **Deployments modernos NO causan downtime**
   - Los usuarios nunca ven caídas del servicio

2. **Siempre validamos antes de mover todos los usuarios**
   - Canary: con el 5% de usuarios reales
   - Blue-Green: con 12 smoke tests automáticos

3. **Rollback es rápido y automático**
   - No esperamos a que todos se quejen
   - El sistema detecta problemas y revierte solo

4. **Todo es automatizado**
   - `git push` → tests → deploy → validación → promoción
   - Los humanos solo escribimos código

### ¿Cuál usar en tu proyecto?

**Usa Canary si:**
- ✅ Tienes muchos usuarios (>1000)
- ✅ El cambio es riesgoso pero quieres datos reales
- ✅ Puedes medir métricas en producción

**Usa Blue-Green si:**
- ✅ Necesitas validación completa antes del switch
- ✅ Rollback debe ser instantáneo
- ✅ Haces cambios en la base de datos
- ✅ No tienes service mesh configurado

### 🚀 Siguiente Nivel

**Actualmente usamos:**
- GitHub Actions (CI/CD gratuito)
- Render (hosting gratuito)
- Scripts Bash (simples y efectivos)

**Para escalar podrías agregar:**
- ☸️ Kubernetes (orquestación de containers)
- 🔀 Istio (service mesh para traffic splitting avanzado)
- 📊 Prometheus + Grafana (métricas y dashboards)
- 🔔 PagerDuty/Slack (alertas automáticas)

---

## 🙋 Preguntas Frecuentes

**Q: ¿Qué pasa si un deployment canary falla a las 3 AM?**
A: El script detecta el problema automáticamente y hace rollback. No necesitas estar despierto. Al día siguiente revisas los logs.

**Q: ¿Los usuarios notaron cuando hicimos el último deployment?**
A: No. El tráfico se cambió gradualmente y sin downtime. Es invisible para ellos.

**Q: ¿Cuánto cuesta implementar esto?**
A: En nuestro caso:
- GitHub Actions: Gratis (2000 minutos/mes)
- Render: Gratis (con limitaciones)
- **Total: $0/mes** (perfecto para aprender)

**Q: ¿Es difícil mantener?**
A: Una vez configurado, solo haces `git push`. El resto es automático. Mantenimiento = casi cero.

**Q: ¿Funciona con cualquier lenguaje?**
A: Sí. Usamos Node.js pero los conceptos aplican a Python, Java, Go, etc. Solo cambia el Dockerfile.

---

## 📚 Recursos Adicionales

**En este repositorio:**
- `DEPLOYMENT_STRATEGIES.md` - Documentación técnica completa
- `TESTING_GUIDE.md` - Guía de testing
- `RENDER_DEPLOYMENT_GUIDE.md` - Setup de Render

**Para aprender más:**
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Patterns](https://kubernetes.io/docs/concepts/)

---

## 🎬 Fin de la Presentación

**Puntos clave para recordar:**

1. 🐤 **Canary** = Prueba con 5% de usuarios reales, aumenta gradualmente
2. 🔵🟢 **Blue-Green** = Dos ambientes, pruebas completas, switch instantáneo
3. ✅ **Ambos** evitan downtime y tienen rollback automático
4. 🤖 **Todo automatizado** con GitHub Actions
5. 📊 **Validación real** con scripts que miden producción

**¿Preguntas?** 🙋

---

**Repositorio:** https://github.com/Joseligos/devops
**Contacto:** Tu email o información de contacto aquí
