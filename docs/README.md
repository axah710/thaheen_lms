# Thaheen LMS Documentation

Welcome to the technical documentation for **Thaheen LMS**, an Arabic-first, 100% offline learning management system and video player built for health-sciences students using Flutter.

---

## Documentation Structure

```text
docs/
├── README.md                      # Master documentation index (this file)
├── project_notes/
│   ├── issues.md                  # Chronological work log and feature history
│   ├── key_facts.md               # Quick reference for keys, schemas, and commands
│   └── debt_notes.md              # Living summary of active technical debt
├── decisions/
│   ├── README.md                  # Index of Architecture Decision Records (ADRs)
│   ├── 001-hermetic-offline-asset-architecture.md
│   ├── 002-pure-dart-domain-layer-and-invariants.md
│   ├── 003-arabic-first-rtl-ergonomics-and-unmirrored-media-controls.md
│   ├── 004-durable-local-persistence-and-lifecycle-flushing.md
│   ├── 005-zero-red-screens-resilience-and-error-boundaries.md
│   └── 006-adaptive-flex-video-controls-layout.md
├── bugs/
│   ├── README.md                  # Bug index and post-mortem register
│   └── BUG-001-custom-video-controls-renderflex-overflow.md
├── conventions/
│   ├── CLEAN-ARCHITECTURE-CONVENTION.md
│   ├── ARABIC-RTL-CONVENTION.md
│   └── PERSISTENCE-LIFECYCLE-CONVENTION.md
├── general/
│   └── system-flows.md            # Mermaid diagrams for domain, state, and persistence
├── debt/
│   ├── 20260926000000-bundled-video-asset-size.md
│   └── 20260926000001-single-active-course-continue-watching.md
└── local_development/
    └── local-setup.md             # Developer environment setup & troubleshooting
```

---

## Quick Navigation

| Topic | Document | Purpose |
|---|---|---|
| **Architecture & Core Decisions** | [ADR Index](decisions/README.md) | Authoritative records of system design choices and trade-offs |
| **Work History & Log** | [Issues & Changelog](project_notes/issues.md) | Chronological tasks, deliverables, and validation logs |
| **Configurations & Constants** | [Key Facts](project_notes/key_facts.md) | Storage keys, thresholds, commands, and rules |
| **Bug Records & Post-Mortems** | [Bug Log](bugs/README.md) | Root cause analyses, fixes, and prevention notes |
| **Coding Patterns** | [Clean Architecture](conventions/CLEAN-ARCHITECTURE-CONVENTION.md) | Dependency rules, pure Dart domain, and Cubit guidelines |
| **Arabic & RTL Ergonomics** | [Arabic RTL Guide](conventions/ARABIC-RTL-CONVENTION.md) | Directionality, unmirrored media controls, Western Arabic digits |
| **Persistence Engine** | [Persistence & Lifecycle](conventions/PERSISTENCE-LIFECYCLE-CONVENTION.md) | 5s debounce, dirty buffers, and AppLifecycleListener flush |
| **Diagrams & Flows** | [System Flows](general/system-flows.md) | Mermaid sequence, state, and class diagrams |
| **Local Setup** | [Local Development](local_development/local-setup.md) | Emulator setup, device clearing, and troubleshooting |
| **Technical Debt** | [Debt Summary](project_notes/debt_notes.md) | Ledger of tracked compromises and payoff triggers |
