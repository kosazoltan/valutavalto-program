---
title: 2026 AI Agent Memory Architecture — State of the Art
type: reference
created: 2026-05-02
sources: Zep arXiv 2501.13956, Letta docs.letta.com, Mem0 mem0.ai blog, Linkedin Cognitive Memory Agent (InfoQ 2026-04)
---

# 2026 AI ügynök memória architektúra — Állapotjelentés

> **Forrás user-direktíva (2026-05-02):** "2026-ban a memória már nem csak az előző üzenetek betöltését jelenti. Három fő irány van."

A jelen dokumentum a 3 fő irány **pontos kódrészleteit** és architektúrális mintáit foglalja össze, amelyek alapján a `D:\valutavalto-vault\` rendszer értékelhető és fejleszthető.

---

## 1. Gráf memória és időbeli érvelés (Zep / Graphiti)

### Lényeg
- A vektoros adatbázisok fölé épített **temporális tudásgráf**: csomópontok (entitások) + élek (kapcsolatok) + **bi-temporal tracking** (mikor volt igaz, mikor jegyezték be).
- A Zep / Graphiti **non-lossy** módon kezeli a változásokat: ha egy tény elavul, **invalidálja** (`invalid_at` set), nem törli — így visszamenőleg lekérdezhető, mi volt igaz egy adott időpontban.
- **LongMemEval benchmark**: +18.5% pontosság, -90% latencia a baseline-hoz képest komplex temporal kérdéseknél.

### Háromszintű subgráf
1. **Episode subgraph** — nyers ingestelt adat (chat üzenet, dokumentum, JSON event)
2. **Semantic entity subgraph** — extraktált entitások és relációk
3. **Community subgraph** — entitás-klaszterek (Leiden community detection)

### Pontos Python kód

```python
import asyncio
from datetime import datetime, timezone
from graphiti_core import Graphiti
from graphiti_core.nodes import EpisodeType

async def main():
    # Init: Neo4j-alapú temporális gráf
    graphiti = Graphiti(
        uri="bolt://localhost:7687",
        user="neo4j",
        password="password",
    )
    await graphiti.build_indices_and_constraints()

    # Episode hozzáadás bi-temporal markerrel
    await graphiti.add_episode(
        name="v2.5.2 release",
        episode_body="A v2.5.2 telepítő publikálva, az aktuális production verzió.",
        source=EpisodeType.text,
        source_description="release-jegyzet",
        reference_time=datetime(2026, 5, 1, 12, 0, tzinfo=timezone.utc),
        # valid_at = reference_time (mikor volt igaz a valós világban)
        # invalid_at = automatikusan beállítódik, ha új episode kontradiktál
    )

    # Lekérdezés időponti referenciával
    results = await graphiti.search(
        query="Aktuális production verzió",
        # reference_time: mikor érvényes válasz kell
        # az invalidált tények NEM jönnek vissza
    )
    for r in results:
        print(f"  {r.fact} (valid_at={r.valid_at}, invalid_at={r.invalid_at})")

asyncio.run(main())
```

### Kulcs koncepciók
- `valid_at` / `invalid_at` — bi-temporal mezők minden élen (relation)
- `reference_time` — query-time paraméter, mikorra vonatkozó truth-ot kérünk
- **Nem destruktív update**: új episode kontradiktálja a régit → új él létrejön + régi `invalid_at` set, eredeti tény lekérdezhető marad

---

## 2. Többszintű memória (Letta / MemGPT)

### Lényeg
A Letta (eredetileg MemGPT, 2024-ben átnevezve) **operációs rendszer**-szerű memóriát ad: az ügynök **maga menedzseli** a memóriát.

### Három tier
| Tier | Analógia | Jellemző | Méret |
|---|---|---|---|
| **Core memory** | RAM | Mindig a context window-ban (block-okban) | KB-os (tokens) |
| **Recall memory** | Disk cache | Történeti chat-ek, on-demand search | MB-os |
| **Archival memory** | Cold storage | Vector DB, explicit `archival_memory_search` tool call | GB-os |

### Pontos Python kód

```python
from letta_client import Letta

client = Letta(api_key="LETTA_API_KEY")

# 1. Agent létrehozás core memory blokkokkal
agent_state = client.agents.create(
    model="openai/gpt-4o-mini",
    embedding="openai/text-embedding-3-small",
    memory_blocks=[
        {
            "label": "human",
            "value": "Felhasználó: Kósa Zoltán. Magyarul beszél. Win11 + RTX 5090."
            # description auto-generated for "human" / "persona" labels
        },
        {
            "label": "persona",
            "value": "AI-fejlesztő ügynök vagyok a Valutaváltó ERP projekthez."
        },
        {
            # Custom label: kötelezően description kell
            "label": "project_state",
            "description": "Aktuális verzió, nyitott PR-ek, Hetzner state.",
            "value": "v2.5.3 mergelve, production HTTP 200, Hetzner deploy success."
        },
    ],
    tools=["archival_memory_insert", "archival_memory_search", "conversation_search"],
)

# 2. Az ügynök automatikusan használja a tool-okat:
# archival_memory_insert(content="...")           — long-term tárolás
# archival_memory_search(query="...")              — long-term keresés
# conversation_search(query="...")                 — recall memory keresés
# core_memory_replace(label="...", new_value="...") — RAM-blokk frissítés
```

### Kulcs koncepciók
- **Block-alapú core memory**: minden block-nak `label`, `description`, `value` mezője van. A description **kritikus** — az ügynök ezt használja, hogy eldöntse melyik blockba írjon.
- **Tool-mediated archival**: az archival nem auto-load, az ügynöknek explicit tool-call-t kell kezdeményeznie.
- **Self-managed**: az ügynök maga dönt, mit promote-ol Core-ba és mit demote-ol Archival-ba (pressure-based context window management).

---

## 3. Procedurális memória (Mem0 + ReasoningBank)

### Lényeg
A **tények** (semantic) és **élmények** (episodic) mellett az ügynökök 2026-ban már **folyamatokat** is tanulnak: hogyan kell egy adott teamnek PR-t nyitni, milyen sorrendben kell deploy-olni, mely Slack csatornában kell jóváhagyást kérni.

### Mi az, és mi NEM az?
- **Procedurális** = "hogyan csináljuk"
- **Episodic** = "ez történt akkor"
- **Semantic** = "ez igaz a világról"
- **Preference** = "a user dark-mode-ot szeret"

### Pontos Python kód (Mem0)

```python
from mem0 import Memory

m = Memory()

# Procedural memory hozzáadás — explicit memory_type
m.add(
    messages=[
        {"role": "user", "content": "Push-merge ciklus minden PR-re:"},
        {"role": "assistant", "content": (
            "1. CI-zöldnek kell lennie (lint+typecheck+test+build)"
            "2. Sourcery + Codex review lekérése (gh api pulls/N/reviews)"
            "3. Minden P0/P1/P2 finding javítása follow-up PR-ben"
            "4. gh pr merge N --squash --auto --delete-branch"
            "5. Lokális branch törlés"
            "6. Hetzner deploy verify (curl excvaluta.com/api/v1/auth/bootstrap-status)"
        )},
    ],
    agent_id="valuta-erp-agent",
    memory_type="procedural_memory",  # << ez a kulcs paraméter
)

# Lekérdezés — szemantikai keresés
results = m.search(
    query="Hogyan mergelek egy PR-t?",
    agent_id="valuta-erp-agent",
)
```

### ReasoningBank (Google Research, 2026)
- **Trial-and-error tanulás**: az ügynök **sikertelen** workflow-kat is elraktározza, hogy ne ismételje a hibát.
- Példa: "Ha V174 migrációt írok, ELLENŐRIZD az `@Table(name=...)` annotációt — mert 2026-05-01-én `branches` plural helyett `branch` singular volt, és outage lett."

### LinkedIn Cognitive Memory Agent (InfoQ 2026-04)
- **Memory consolidation**: a session után az ügynök saját maga distillálja a tanulságokat egy "lessons learned" file-ba, ami a következő sessionnél automatikusan core memory-ba kerül.

---

## 4. Hivatkozások

- [Zep arXiv paper (2501.13956)](https://arxiv.org/abs/2501.13956)
- [Graphiti GitHub (getzep/graphiti)](https://github.com/getzep/graphiti)
- [Letta docs — memory blocks](https://docs.letta.com/guides/agents/memory-blocks/)
- [Letta docs — memory management](https://docs.letta.com/advanced/memory-management/)
- [Mem0 — State of AI Agent Memory 2026](https://mem0.ai/blog/state-of-ai-agent-memory-2026)
- [Google Research — ReasoningBank](https://research.google/blog/reasoningbank-enabling-agents-to-learn-from-experience/)
- [InfoQ — LinkedIn Cognitive Memory Agent](https://www.infoq.com/news/2026/04/linkedin-cognitive-memory-agent/)
- [Atlan — Best AI Agent Memory Frameworks 2026](https://atlan.com/know/best-ai-agent-memory-frameworks-2026/)
