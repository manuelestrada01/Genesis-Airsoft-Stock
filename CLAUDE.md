# Genesis Airsoft Stock — CLAUDE.md

## Proyecto
App de gestión de inventario y finanzas para tienda de airsoft. Flutter + Firebase.

## Ubicación
`C:\G` — path corto intencionalmente para evitar MAX_PATH en builds.

## Stack
- **Flutter** 3.29.2 / Dart 3.7.2
- **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`
- **State management**: Riverpod 2.x (`flutter_riverpod`)
- **Navegación**: `go_router` con `StatefulShellRoute` para bottom tabs
- **Formato**: `intl` locale `es_AR`, moneda `$`

## Arquitectura
```
lib/
  domain/         ← entidades + interfaces de repositorios (Dart puro)
  application/    ← use cases (lógica de negocio)
  infrastructure/ ← implementaciones Firebase
  presentation/   ← providers (Riverpod), screens, widgets, utils
  app/            ← router, theme
```

## Firebase
- **Proyecto**: `genesis-airsoft`
- **applicationId**: `com.genesisairsoftstock`
- **Auth**: email/password
- **Colecciones**: `products`, `sales`, `expenses`
- Filtrado de productos: **client-side** (evita índices compuestos)

## Reglas de negocio
- `LOW_STOCK_THRESHOLD = 5` (ver `product.dart`)
- Al crear venta con `saleType=product` → deducir stock automáticamente
- `saleType=free` → no afecta stock

## Screens
1. `LoginScreen` — auth con Firebase
2. `HomeScreen` — dashboard con stats y acciones rápidas
3. `BalanceScreen` — ingresos/egresos con filtro de período
4. `InventoryScreen` — catálogo con búsqueda, filtros, modal de stock
5. `DebtsScreen` — placeholder "Próximamente"

## Historial
- Proyecto migrado desde React Native 0.86 por problemas de MAX_PATH en Windows con ninja/CMake
- El proyecto RN original está en `C:\Users\jetsa\GenesisAirsoftStock` (no borrar hasta validar)
- google-services.json copiado del proyecto RN original

## Estado actual (COMPLETO)
- [x] Setup Flutter en C:\G
- [x] Dominio (entidades, repositorios abstractos)
- [x] Use cases
- [x] Infrastructure (Firebase repos + auth service)
- [x] Theme, utils (formatCurrency, formatDate)
- [x] Providers (auth, products, sales, expenses, balance, stats)
- [x] Router (go_router con auth gate)
- [x] main.dart
- [x] LoginScreen
- [x] HomeScreen
- [x] InventoryScreen
- [x] BalanceScreen
- [x] DebtsScreen (placeholder)
- [x] Todos los widgets (Header, QuickActionCard, StatCard, ProductCard, StockBadge, CategoryFilter, SearchBarWidget, TabSelector, TransactionItem, PeriodSelector, PeriodModal, BalanceCard, EmptyState, UpdateStockModal, RegisterExpenseModal)
- [x] RegisterSaleFlowPage (5 pasos: type → select → confirm → free → payment)
- flutter analyze: 0 errores
