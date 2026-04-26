# BACKEND_SCHEMA.md — EANTrack (FINAL)

> Gerado a partir de dois dumps: dump 1 (routines + params sem ordinal) e dump 2 (params com ordinal_position).
> Dump 2 é parcial — cobre funções até `list_networks_for_management`.
> Funções marcadas com `*` têm parâmetros apenas do dump 1 (sem ordinal confirmado).
> Nenhum dado foi inventado.
> Convenção IN/OUT: parâmetros prefixados com `p_` são IN; sem prefixo em função que retorna `record` são OUT.

---

## TABELAS

| Tabela |
|--------|
| agencies |
| agency_categories |
| agency_members |
| agency_member_regions |
| agency_subcategories |
| agency_subscription |
| cities |
| email_codes |
| email_logs |
| email_outbox |
| industries |
| industry_products |
| leads |
| legal_documents |
| legal_representatives |
| networks |
| pdvs |
| region_cities |
| region_responsibles |
| regions |
| tab_cadastroauxiliar |
| tabapieaninterno |
| user_flow_state |
| user_identifiers |

---

## VIEWS

| View | Descrição |
|------|-----------|
| `user_profile_view` | Perfil consolidado do usuário |
| `v_regions_full` | Regiões com cidades e responsáveis |
| `v_user_agency_onboarding_context` | Contexto de onboarding da agência para o usuário autenticado — consumida por `AgencyStatusNotifier` |
| `v_user_agency_onboarding_representativelegal` | Dados do representante legal no contexto de onboarding |
| `v_user_agency_session_v1` | Sessão consolidada agência + usuário |
| `v_latest_legal_documents` | Última tentativa de documento por `(agency_id, document_type)` — ver [LEGAL_DOCUMENTS_VERSIONING.md](LEGAL_DOCUMENTS_VERSIONING.md) |
| `v_agency_latest_document_status` | Status consolidado de documentos por agência — **única fonte de status para o app** — ver [LEGAL_DOCUMENTS_VERSIONING.md](LEGAL_DOCUMENTS_VERSIONING.md) |

---

---

## Modelo de Documentos Legais Versionados

As tabelas `legal_representatives` e `legal_documents` formam o núcleo do fluxo de aprovação de agências. O modelo é **não-destrutivo**: cada envio cria novos registros, nenhum documento é apagado ou sobrescrito.

**Documentação completa:** [LEGAL_DOCUMENTS_VERSIONING.md](LEGAL_DOCUMENTS_VERSIONING.md)

### Resumo rápido

| Tabela | Papel |
|--------|-------|
| `legal_representatives` | Dados cadastrais do representante — novo registro por tentativa |
| `legal_documents` | Arquivos e status — insert-only, `attempt_number` incremental |

| View | Papel |
|------|-------|
| `v_latest_legal_documents` | Última tentativa por `(agency_id, document_type)` |
| `v_agency_latest_document_status` | Status consolidado por agência — única fonte para o app |

**Regra crítica:** o app Flutter lê status exclusivamente via `v_agency_latest_document_status`. Nunca via query direta em `legal_documents`.

---

## TRIGGERS

| Nome | Evento estimado |
|------|----------------|
| convert_to_integer | INSERT/UPDATE — converte campo para inteiro |
| enforce_region_cities_agency_match | INSERT/UPDATE em `region_cities` — garante cidade e região da mesma agência |
| normalize_network_name | INSERT/UPDATE em `networks` — normaliza nome |
| normalize_region_name | INSERT/UPDATE em `regions` — normaliza nome |
| prevent_city_in_multiple_regions_same_agency | INSERT/UPDATE em `region_cities` — impede cidade em múltiplas regiões |
| set_agency_owner_user_uuid | INSERT em `agencies` — define UUID do owner |
| set_legal_representative_id | INSERT/UPDATE — define ID do representante legal |
| set_updated_at | UPDATE — define `updated_at` |
| sync_network_logo_path | INSERT/UPDATE em `networks` — sincroniza caminho do logo |
| touch_updated_at | UPDATE — atualiza `updated_at` |
| trg_agencies_email_on_insert | INSERT em `agencies` — dispara envio de e-mail |
| trg_agencies_email_on_status_change | UPDATE de status em `agencies` — dispara envio de e-mail |
| trg_agency_on_approved_create_owner_member | UPDATE status → aprovado em `agencies` — cria membro owner |
| update_updated_at | UPDATE — atualiza `updated_at` |
| update_updated_at_column | UPDATE — atualiza coluna `updated_at` |
| validate_industry_product_consistency | INSERT/UPDATE em `industry_products` — valida consistência |
| validate_subcategory_agency | INSERT/UPDATE em `agency_subcategories` — valida vínculo com agência |

---

## FUNÇÕES (RPCs)

### Auth / Usuário

---

#### `get_user_onboarding_route`
- **Retorno:** `text` (nullable)
- **Parâmetros:** nenhum — opera sobre o `auth.uid()` da sessão atual
- **Valores possíveis de retorno:**

  | Valor | Destino no app |
  |-------|---------------|
  | `'hub'` | `AppRoutes.hub` |
  | `'onboarding/agency/status'` | `AppRoutes.onboardingAgencyStatus` |
  | `'onboarding/agency/representative'` | `AppRoutes.onboardingAgencyRepresentative` |
  | `'onboarding/agency/cnpj'` | `AppRoutes.onboardingAgencyCnpj` |
  | `'onboarding/individual/profile'` | `AppRoutes.onboardingIndividualProfile` |
  | `null` / outro | `AppRoutes.onboarding` (fallback) |

- **Consumido por:** `SplashNotifier._resolveRoute()` — ver DEC-021
- **Nota:** session null ou exception no cliente → redireciona para `/login` sem chamar a RPC

---

#### `email_code_exists`
- **Retorno:** `boolean`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_hash | text | IN |

---

#### `insert_email_code`
- **Retorno:** `void`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_hash | text | IN |
  | 2 | p_user_id | uuid | IN |

---

#### `is_email_confirmed_status`
- **Retorno:** `jsonb`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_email | text | IN |

---

#### `identifier_exists`
- **Retorno:** `boolean`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_identificador | text | IN |

---

#### `reservar_identificador_com_cadastro` *
- **Retorno:** `boolean`
- **Parâmetros:** não presentes nos dumps

---

#### `verificar_matricula_existe` *
- **Retorno:** `boolean`
- **Parâmetros:** não presentes nos dumps

---

#### `verificar_e_atualizar_matricula` *
- **Retorno:** `boolean`
- **Parâmetros:** não presentes nos dumps

---

#### `search_users_by_identifier` *
- **Retorno:** `record` (set)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | — | p_query | text | IN |
  | — | p_limit | integer | IN |
  | — | user_id | uuid | OUT |
  | — | identificador | text | OUT |
  | — | nome | text | OUT |
  | — | photourl | text | OUT |

---

#### `get_user_role_in_agency`
- **Retorno:** `USER-DEFINED` (enum de role)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |

---

#### `is_member_of_agency`
- **Retorno:** `boolean`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |

---

#### `can_manage_agency_members`
- **Retorno:** `boolean`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |

---

### Agência

---

#### `admin_review_legal_documents`
- **Retorno:** `void`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |
  | 2 | p_status | USER-DEFINED | IN |
  | 3 | p_rejection_reason | text | IN |

---

#### `cnpj_exists_agency`
- **Retorno:** `text`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_cnpj | text | IN |

---

#### `check_agency_pdvs_regions_exist`
- **Retorno:** `record`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |
  | 2 | has_networks | text | OUT |
  | 3 | has_regions | text | OUT |
  | 4 | has_pdvs | text | OUT |
  | 5 | pdvs_count | bigint | OUT |

---

#### `enqueue_agency_status_email`
- **Retorno:** `void`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |
  | 2 | p_new_status | text | IN |
  | 3 | p_to_email | text | IN |
  | 4 | p_user_name | text | IN |
  | 5 | p_agency_name | text | IN |

---

#### `notify_agency_status_change` *
- **Retorno:** `jsonb`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | — | p_agency_id | uuid | IN |
  | — | p_new_status | text | IN |
  | — | p_to_email | text | IN |
  | — | p_user_name | text | IN |
  | — | p_agency_name | text | IN |

---

#### `notify_agency_status_change_internal` *
- **Retorno:** `void`
- **Parâmetros:** não presentes nos dumps

---

---

### Regiões / Cidades

---

#### `can_access_region`
- **Retorno:** `boolean`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_region_id | uuid | IN |

---

#### `has_regions_for_current_user`
- **Retorno:** `json`
- **Parâmetros:** nenhum (confirmado no dump 2)

---

#### `is_region_name_available_for_current_user`
- **Retorno:** `json`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_name | text | IN |

---

#### `list_regions_for_dropdown` *
- **Retorno:** `record` (set)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | — | p_agency_id | uuid | IN |
  | — | id | uuid | OUT |
  | — | name | text | OUT |

---

#### `list_regions_for_filter_dropdown` *
- **Retorno:** `record` (set)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | — | p_agency_id | uuid | IN |
  | — | id | uuid | OUT |
  | — | name | text | OUT |

---

#### `list_regions_by_agency_exhibition` *
- **Retorno:** `record` (set)
- **Parâmetros:** não presentes nos dumps

---

#### `list_cities_for_filter_dropdown`
- **Retorno:** `record` (set)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |
  | 2 | p_region_id | uuid | IN |
  | 3 | id | uuid | OUT |
  | 4 | name | text | OUT |
  | 5 | uf | text | OUT |

---

#### `list_cities_for_region_dropdown`
- **Retorno:** `record` (set)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |
  | 2 | p_region_id | uuid | IN |
  | 3 | id | uuid | OUT |
  | 4 | name | text | OUT |
  | 5 | uf | text | OUT |

---

#### `get_conflicting_city_ids`
- **Retorno:** `uuid` (set)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |
  | 2 | p_city_ids | ARRAY | IN |
  | 3 | p_region_id | uuid | IN |
  | 4 | city_id | uuid | OUT |

---

#### `replace_region_cities` *
- **Retorno:** `text`
- **Parâmetros:** não presentes nos dumps

---

### Redes (Networks)

---

#### `list_networks_for_management`
- **Retorno:** `record` (set)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |
  | 2 | p_search | text | IN |
  | 3 | id | uuid | OUT |
  | 4 | name | text | OUT |
  | 5 | logo_url | text | OUT |
  | 6 | reference_code | text | OUT |
  | 7 | channel | text | OUT |
  | — | is_active | boolean | OUT |
  | — | created_at | timestamp with time zone | OUT |
  | — | updated_at | timestamp with time zone | OUT |

  > Ordinal 8–10 (`is_active`, `created_at`, `updated_at`) presentes apenas no dump 1.

---

#### `list_networks_for_dropdown`
- **Retorno:** `record` (set)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |
  | 2 | id | uuid | OUT |
  | 3 | name | text | OUT |
  | 4 | logo_url | text | OUT |
  | 5 | is_active | boolean | OUT |
  | 6 | channel | text | OUT |

---

#### `list_networks_for_filter_dropdown`
- **Retorno:** `record` (set)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |
  | 2 | id | uuid | OUT |
  | 3 | name | text | OUT |
  | 4 | logo_url | text | OUT |
  | 5 | channel | text | OUT |

---

#### `network_name_exists_in_agency` *
- **Retorno:** `text`
- **Parâmetros:** não presentes nos dumps

---

### PDVs

---

#### `get_pdv_for_edit`
- **Retorno:** `record`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_pdv_id | uuid | IN |
  | 2 | id | uuid | OUT |
  | 3 | agency_id | uuid | OUT |
  | 4 | network_id | uuid | OUT |
  | 5 | city_id | uuid | OUT |
  | 6 | region_id | uuid | OUT |
  | 7 | cnpj | text | OUT |
  | 8 | razao_social | text | OUT |
  | 9 | channel | text | OUT |
  | 10 | tipo_pdv | text | OUT |
  | 11 | porte_pdv | text | OUT |
  | 12 | checkout_count | integer | OUT |
  | 13 | codigo_interno | text | OUT |
  | 14 | cep | text | OUT |
  | 15 | logradouro | text | OUT |
  | 16 | numero | text | OUT |
  | 17 | bairro | text | OUT |
  | 18 | uf | text | OUT |
  | 19 | latitude | double precision | OUT |
  | 20 | longitude | double precision | OUT |
  | 21 | location_validated | boolean | OUT |
  | 22 | is_active | boolean | OUT |
  | 23 | created_at | timestamp with time zone | OUT |
  | 24 | updated_at | timestamp with time zone | OUT |
  | 25 | store_manager_name | text | OUT |
  | 26 | store_contact | text | OUT |

---

#### `list_pdvs_by_agency_exhibition` *
- **Retorno:** `record` (set)
- **Parâmetros:** não presentes nos dumps

---

#### `pdv_cnpj_exists_in_agency` *
- **Retorno:** `text`
- **Parâmetros:** não presentes nos dumps

---

#### `check_first_digit`
- **Retorno:** `record`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | user_id | uuid | — |
  | 2 | nome_first_digit | character | — |
  | 3 | sobrenome_first_digit | character | — |

  > Nenhum parâmetro tem prefixo `p_`. Direção IN/OUT não determinável sem `parameter_mode`.

---

### Categorias / Subcategorias

---

#### `list_categories_for_management`
- **Retorno:** `record` (set)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |
  | 2 | p_search | text | IN |
  | 3 | id | uuid | OUT |
  | 4 | name | text | OUT |
  | 5 | description | text | OUT |
  | 6 | subcategory_count | integer | OUT |
  | 7 | is_active | boolean | OUT |
  | 8 | created_at | timestamp with time zone | OUT |
  | 9 | updated_at | timestamp with time zone | OUT |

---

#### `list_subcategories_for_management` *
- **Retorno:** `record` (set)
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | — | p_agency_id | uuid | IN |
  | — | p_category_id | uuid | IN |
  | — | p_search | text | IN |
  | — | id | uuid | OUT |
  | — | name | text | OUT |
  | — | is_active | boolean | OUT |
  | — | created_at | timestamp with time zone | OUT |
  | — | updated_at | timestamp with time zone | OUT |

---

#### `category_name_exists`
- **Retorno:** `boolean`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | 1 | p_agency_id | uuid | IN |
  | 2 | p_name | text | IN |
  | 3 | p_id | text | IN |

---

#### `subcategory_name_exists` *
- **Retorno:** `text`
- **Parâmetros:**

  | # | Nome | Tipo | Direção |
  |---|------|------|---------|
  | — | p_agency_id | uuid | IN |
  | — | p_category_id | uuid | IN |
  | — | p_name | text | IN |
  | — | p_id | text | IN |

---

### Utilitários

---

#### `unaccent_immutable` *
- **Retorno:** `text`
- **Parâmetros:** não presentes nos dumps

---

## RESUMO

| Categoria | Quantidade |
|-----------|-----------|
| Tabelas | 24 |
| Views | 7 |
| Triggers | 17 |
| Funções (RPCs) | 42 |
| — com ordinal_position confirmado (dump 2) | 20 |
| — com params apenas do dump 1 | 13 |
| — sem params em nenhum dump | 8 |
| — adicionadas pós-dump (`get_user_onboarding_route`) | 1 |
